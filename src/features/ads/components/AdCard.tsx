import { MapPin, ShoppingCart } from "lucide-react";
import { memo, useCallback } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { useCart } from "@/hooks/useCart";
import { useNotification } from "@/features/notifications/hooks/useNotification";
import { useLanguage } from "@/contexts/LanguageContext";
import { FavoriteButton } from "@/features/favorites";

interface AdCardProps {
  id: string;
  title: string;
  price: number;
  city: string;
  image: string;
  date: string;
  seller?: string;
  ownerId?: number;
  favoritesCount?: number;
  isFollowed?: boolean;
}

const AdCard = ({
  id,
  title,
  price,
  city,
  image,
  date,
  seller = "Vendeur",
  ownerId,
  favoritesCount,
  isFollowed,
}: AdCardProps) => {
  const { t } = useLanguage();
  const { addToCart } = useCart();
  const { addNotification } = useNotification();

  const handleAddToCart = useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      addToCart(id, title, price, image, seller);
      addNotification(t("added_to_cart_title"), t("added_to_cart_msg"), "success");
    },
    [addNotification, addToCart, id, image, price, seller, title, t],
  );

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35 }}
      className="group"
    >
      <Link to={`/ad/${id}`} className="block">
        <div className="bg-card rounded-2xl overflow-hidden border border-border shadow-card hover:shadow-card-hover transition-shadow duration-300">
          <div className="relative aspect-[4/3] overflow-hidden bg-muted">
            <img
              src={image}
              alt={title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              loading="lazy"
            />
            <FavoriteButton
              annonceId={id}
              ownerId={ownerId}
              className="absolute top-3 right-3 h-9 w-9 bg-background/80 backdrop-blur-sm hover:bg-background"
              showCount
              initialIsFavorite={isFollowed}
              initialFavoritesCount={favoritesCount}
            />
          </div>
          <div className="p-4">
            <p className="text-lg font-heading font-bold text-primary">
              {price.toLocaleString()} DH
            </p>
            <h3 className="text-sm font-medium text-foreground mt-1 line-clamp-2 leading-snug">
              {title}
            </h3>
            <button
              onClick={handleAddToCart}
              className="w-full mt-3 bg-add-to-cart text-white font-medium py-2 px-3 rounded-lg flex items-center justify-center gap-2 transition-all duration-200 transform hover:scale-105"
            >
              <ShoppingCart className="w-4 h-4" />
              <span>{t("add_to_cart")}</span>
            </button>
            <div className="flex items-center gap-1 mt-3 text-xs text-muted-foreground">
              <MapPin className="h-3.5 w-3.5" />
              <span>{city}</span>
              <span className="mx-1">·</span>
              <span>{date}</span>
            </div>
          </div>
        </div>
      </Link>
    </motion.div>
  );
};

export default memo(AdCard);
