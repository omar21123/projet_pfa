import { Heart, Loader2 } from "lucide-react";
import { memo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { useAuth, useLanguage } from "@/contexts";
import { useFavorite } from "@/features/favorites/hooks/useFavorite";

interface FavoriteButtonProps {
  productId: string | number;
  ownerId?: number;
  className?: string;
  showCount?: boolean;
  ariaLabel?: string;
  initialIsFavorite?: boolean;
  initialFavoritesCount?: number;
}

const FavoriteButton = ({
  productId,
  ownerId,
  className,
  showCount = true,
  ariaLabel,
  initialIsFavorite,
  initialFavoritesCount,
}: FavoriteButtonProps) => {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const { isFavorite, favoritesCount, isPending, toggleFavorite } = useFavorite(
    productId,
    {
      isFavorite: initialIsFavorite,
      favoritesCount: initialFavoritesCount,
    },
    { ownerId },
  );

  const handleClick = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      event.preventDefault();
      event.stopPropagation();
      if (!isAuthenticated) {
        navigate("/login");
        return;
      }
      toggleFavorite();
    },
    [isAuthenticated, navigate, toggleFavorite],
  );

  return (
    <motion.button
      type="button"
      onClick={handleClick}
      disabled={isPending}
      aria-pressed={isFavorite}
      aria-label={ariaLabel ?? (isFavorite ? t("removed_from_favorites") : t("added_to_favorites"))}
      className={cn(
        "relative inline-flex items-center justify-center rounded-full transition-all duration-200",
        isFavorite ? "text-red-500" : "text-muted-foreground hover:text-primary",
        isPending && "opacity-80 cursor-not-allowed",
        className,
      )}
      whileTap={{ scale: isPending ? 1 : 0.94 }}
      whileHover={{ scale: isPending ? 1 : 1.04 }}
    >
      <motion.span
        initial={false}
        animate={isFavorite ? { scale: [1, 1.16, 1] } : { scale: 1 }}
        transition={{ duration: 0.24 }}
        className="relative flex items-center justify-center"
      >
        {isPending ? (
          <Loader2 className="h-4 w-4 animate-spin" />
        ) : (
          <Heart className={cn("h-5 w-5 transition-colors", isFavorite && "fill-current")} />
        )}
      </motion.span>

      {showCount && (
        <span className="absolute -bottom-2 -right-2 min-w-5 rounded-full border border-border bg-background px-1.5 py-0.5 text-[10px] font-semibold leading-none text-foreground shadow-sm">
          {favoritesCount}
        </span>
      )}
    </motion.button>
  );
};

export default memo(FavoriteButton);