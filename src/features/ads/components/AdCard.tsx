import { memo } from "react";
import { Link } from "react-router-dom";
import { Star, ShieldCheck } from "lucide-react";
import { motion } from "framer-motion";
import { FavoriteButton } from "@/features/favorites";
import { WishlistButton } from "@/features/wishlist";
import { ShoppingCartButton } from "@/features/cart/ShoppingCartButton";

interface AdCardProps {
  id: number | string; // Gère les IDs numériques pour l'API
  title: string;
  price: number;
  originalPrice?: number;
  discountPercentage?: number;
  brand?: string;
  isVerified?: boolean;
  rating?: number;
  reviewsCount?: number;
  image: string;
  isTopSale?: boolean;
  compositionID?: number;
  isFollowed?: boolean;
  favoritesCount?: number;
}

const AdCard = ({
  id,
  title,
  price,
  originalPrice = 229,
  discountPercentage = -35,
  brand = "SONORA PRO",
  isVerified = true,
  rating = 4.7,
  reviewsCount = 328,
  image,
  isTopSale = true,
  compositionID,
  isFollowed,
  favoritesCount,
}: AdCardProps) => {
  const numericId = typeof id === "string" ? parseInt(id, 10) : id;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="group w-full max-w-[320px]"
    >
      <div className="bg-[#f8f8f8] dark:bg-card rounded-2xl p-3 border border-border/60 shadow-sm hover:shadow-md transition-all duration-300">
        {/* Zone Image */}
        <div className="relative aspect-square rounded-xl overflow-hidden bg-muted mb-3">
          <Link to={`/produit/${id}`}>
            <img
              src={image}
              alt={title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              loading="lazy"
            />
          </Link>

          {/* Badge TOP VENTE */}
          {isTopSale && (
            <span className="absolute top-2.5 left-2.5 bg-black text-white text-[11px] font-extrabold tracking-wider px-2.5 py-1 rounded-md uppercase">
              TOP VENTE
            </span>
          )}

          {/* Badge Réduction */}
          {discountPercentage && (
            <span className="absolute top-2.5 right-2.5 bg-[#cb4024] text-white text-[12px] font-bold px-2.5 py-0.5 rounded-md">
              {discountPercentage}%
            </span>
          )}

          {/* Boutons Favoris + Wishlist en haut à droite */}
          <div className="absolute top-2.5 right-2.5 flex items-center gap-2 z-10">
            <WishlistButton
              productId={numericId}
              className="h-9 w-9 rounded-full bg-white shadow-md hover:bg-slate-50 text-slate-700 transition-transform active:scale-95 flex items-center justify-center border-none"
            />
            <FavoriteButton
              productId={String(id)}
              className="h-9 w-9 rounded-full bg-white shadow-md hover:bg-slate-50 text-slate-700 transition-transform active:scale-95 flex items-center justify-center border-none"
              initialIsFavorite={isFollowed}
              initialFavoritesCount={favoritesCount}
            />
          </div>
        </div>

        {/* Informations Produit */}
        <div className="px-1 space-y-1.5">
          {/* Marque & Badge Vérifié */}
          <div className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300 font-semibold text-xs tracking-wide uppercase">
            <span>{brand}</span>
            {isVerified && <ShieldCheck className="w-4 h-4 text-slate-700 dark:text-slate-300" />}
          </div>

          {/* Titre Produit */}
          <Link to={`/produit/${id}`} className="block">
            <h3 className="text-[15px] font-semibold text-slate-800 dark:text-slate-100 line-clamp-2 leading-snug hover:text-primary transition-colors">
              {title}
            </h3>
          </Link>

          {/* Évaluation / Note */}
          <div className="flex items-center gap-1.5 pt-0.5 text-xs text-slate-500">
            <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
            <span className="font-bold text-slate-800 dark:text-slate-200">{rating}</span>
            <span>({reviewsCount})</span>
          </div>

          {/* Prix & Ancien Prix */}
          <div className="flex items-baseline gap-2 pt-1 pb-2">
            <span className="text-2xl font-black text-slate-900 dark:text-white">{price} €</span>
            {originalPrice && (
              <span className="text-sm font-medium text-slate-400 line-through">
                {originalPrice} €
              </span>
            )}
          </div>

          {/* Bouton Ajouter au Panier */}
          <ShoppingCartButton
            productID={numericId}
            unitPrice={price}
            compositionID={compositionID}
          />
        </div>
      </div>
    </motion.div>
  );
};

export default memo(AdCard);
