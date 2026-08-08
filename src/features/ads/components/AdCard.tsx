import { memo } from "react";
import { Link } from "react-router-dom";
import { Megaphone, Star, ShieldCheck, Tag } from "lucide-react";
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
  isPromoted?: boolean;
  isBoosted?: boolean;
  compositionID?: number;
  isFollowed?: boolean;
  favoritesCount?: number;
  city?: string;
  date?: string;
  searchTerm?: string;
}

const AdCard = ({
  id,
  title,
  price,
  originalPrice,
  discountPercentage,
  brand = "",
  isVerified = false,
  rating,
  reviewsCount,
  image,
  isTopSale = false,
  isPromoted = false,
  isBoosted = false,
  compositionID,
  isFollowed,
  favoritesCount,
  searchTerm,
}: AdCardProps) => {
  const numericId = typeof id === "string" ? parseInt(id, 10) : id;
  const productPath = searchTerm
    ? `/produit/${id}?fromSearch=true&searchTerm=${encodeURIComponent(searchTerm)}`
    : `/produit/${id}`;

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
          <Link to={productPath}>
            <img
              src={image}
              alt={title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              loading="lazy"
            />
          </Link>

          {/* Badges commerciaux uniquement lorsque l'API les justifie. */}
          {isTopSale && (
            <span className="absolute top-2.5 left-2.5 bg-black text-white text-[11px] font-extrabold tracking-wider px-2.5 py-1 rounded-md uppercase">
              TOP VENTE
            </span>
          )}

          {isBoosted && (
            <span className="absolute top-14 right-2.5 bg-amber-400 text-amber-950 text-[10px] font-extrabold px-2 py-1 rounded-md flex items-center gap-1 uppercase">
              <Megaphone className="h-3 w-3" /> Boosté
            </span>
          )}

          {isPromoted && !isBoosted && (
            <span className="absolute top-14 right-2.5 bg-emerald-600 text-white text-[10px] font-extrabold px-2 py-1 rounded-md flex items-center gap-1 uppercase">
              <Tag className="h-3 w-3" /> Promo
            </span>
          )}

          {discountPercentage && discountPercentage > 0 && (
            <span className="absolute bottom-2.5 left-2.5 bg-[#cb4024] text-white text-[12px] font-bold px-2.5 py-0.5 rounded-md">
              -{Math.round(discountPercentage)}%
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
          {(brand || isVerified) && (
            <div className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300 font-semibold text-xs tracking-wide uppercase">
              {brand && <span>{brand}</span>}
              {isVerified && <ShieldCheck className="w-4 h-4 text-slate-700 dark:text-slate-300" />}
            </div>
          )}

          {/* Titre Produit */}
          <Link to={productPath} className="block">
            <h3 className="text-[15px] font-semibold text-slate-800 dark:text-slate-100 line-clamp-2 leading-snug hover:text-primary transition-colors">
              {title}
            </h3>
          </Link>

          {/* Évaluation / Note */}
          {rating !== undefined && (
            <div className="flex items-center gap-1.5 pt-0.5 text-xs text-slate-500">
              <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
              <span className="font-bold text-slate-800 dark:text-slate-200">{rating}</span>
              {reviewsCount !== undefined && <span>({reviewsCount})</span>}
            </div>
          )}

          {/* Prix & Ancien Prix */}
          <div className="flex items-baseline gap-2 pt-1 pb-2">
            <span className="text-2xl font-black text-slate-900 dark:text-white">
              {price.toLocaleString("fr-FR")} MAD
            </span>
            {originalPrice !== undefined && originalPrice > price && (
              <span className="text-sm font-medium text-slate-400 line-through">
                {originalPrice.toLocaleString("fr-FR")} MAD
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
