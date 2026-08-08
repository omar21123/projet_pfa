import React, { useCallback, useEffect, useState } from "react";
import axios from "axios";
import { wishlistApi } from "@/api/wishlist.api";
import { Bookmark, Loader2 } from "lucide-react";
import { useAuth } from "@/contexts";
import { useToast } from "@/hooks/use-toast";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import type { Wishlist, WishlistItem, WishlistItemCreated } from "@/types/wishlist";

interface WishlistButtonProps {
  productId: number | string;
  className?: string;
  ariaLabel?: string;
}

const WishlistButton = ({
  productId,
  className = "",
  ariaLabel = "Ajouter à la wishlist",
}: WishlistButtonProps) => {
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  const [isPending, setIsPending] = useState(false);
  const [isAdded, setIsAdded] = useState(false);
  const [wishListItemId, setWishListItemId] = useState<number | null>(null);

  // 1. Charger l'état (Est-ce que le produit est déjà dans une liste ?)
  const loadState = useCallback(async () => {
    if (!isAuthenticated) return;

    try {
      const resp = await wishlistApi.list();
      const lists: Wishlist[] = resp?.data ?? [];

      // On cherche si le produit existe dans l'une des listes de l'utilisateur
      for (const list of lists) {
        const foundItem = (list.items ?? []).find((it: WishlistItem) => {
          const currentId = it.productId ?? Number(it.productId);
          return Number(currentId) === Number(productId);
        });

        if (foundItem) {
          setIsAdded(true);
          setWishListItemId(foundItem.wishListItemId);
          return;
        }
      }

      setIsAdded(false);
      setWishListItemId(null);
    } catch (err) {
      console.error("Erreur wishlist loadState:", err);
    }
  }, [productId, isAuthenticated]);

  useEffect(() => {
    loadState();
  }, [loadState]);

  // 2. Action Toggle (Ajouter / Retirer)
  const handleClick = useCallback(
    async (event: React.MouseEvent<HTMLButtonElement>) => {
      event.preventDefault();
      event.stopPropagation();

      if (!isAuthenticated) {
        toast({
          title: "Connexion requise",
          description: "Veuillez vous connecter pour gérer votre wishlist.",
        });
        navigate("/login");
        return;
      }

      setIsPending(true);
      try {
        if (isAdded && wishListItemId) {
          // SUPPRESSION
          await wishlistApi.removeItem(Number(wishListItemId));
          setIsAdded(false);
          setWishListItemId(null);
          toast({ title: "Retiré", description: "Produit retiré de la wishlist." });
        } else {
          // AJOUT
          const listsResp = await wishlistApi.list();
          const lists = (listsResp?.data ?? []) as Wishlist[];
          let targetListId: number;

          if (lists.length > 0) {
            targetListId = lists[0].wishListId;
          } else {
            // Créer une liste par défaut si aucune n'existe
            const created = await wishlistApi.create({ name: "Mes favoris" });
            targetListId = created.data.wishListId;
          }

          const added = await wishlistApi.addItem(targetListId, { product_id: Number(productId) });
          const newId = (added?.data as WishlistItemCreated)?.wishListItemId ?? null;

          setIsAdded(true);
          setWishListItemId(newId);
          toast({ title: "Ajouté", description: "Produit ajouté à vos favoris." });
        }
      } catch (err: unknown) {
        const getAxiosMessage = (e: unknown): string | undefined => {
          if (!axios.isAxiosError(e)) return undefined;
          const data = e.response?.data;
          if (data && typeof data === "object" && "message" in data) {
            return String((data as Record<string, unknown>).message ?? undefined);
          }
          return undefined;
        };

        const errorMsg = getAxiosMessage(err) ?? "Une erreur est survenue";
        toast({ title: "Erreur", description: errorMsg, variant: "destructive" });
      } finally {
        setIsPending(false);
      }
    },
    [isAuthenticated, isAdded, productId, wishListItemId, toast, navigate],
  );

  return (
    <motion.button
      type="button"
      onClick={handleClick}
      disabled={isPending}
      aria-pressed={isAdded}
      aria-label={ariaLabel}
      className={cn(
        "relative inline-flex items-center justify-center rounded-full p-2 transition-all duration-200",
        isAdded ? "text-red-500" : "text-muted-foreground hover:text-primary",
        isPending && "opacity-70 cursor-not-allowed",
        className,
      )}
      whileTap={{ scale: 0.9 }}
      whileHover={{ scale: 1.1 }}
    >
      {isPending ? (
        <Loader2 className="h-5 w-5 animate-spin" />
      ) : (
        <Bookmark
          className={cn("h-5 w-5 transition-colors", isAdded ? "fill-current" : "fill-none")}
        />
      )}
    </motion.button>
  );
};

export default WishlistButton;
