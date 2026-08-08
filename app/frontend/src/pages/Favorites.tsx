import { useMemo, useState, memo } from "react";
import {
  Heart,
  Clock,
  Search,
  Grid3X3,
  List,
  ChevronLeft,
  Sparkles,
  ArrowRight,
  ShoppingBag,
} from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import { useLanguage } from "@/contexts/LanguageContext";
import { useFavoriteAds } from "@/features/favorites/hooks/useFavoriteAds";
import { FavoriteButton } from "@/features/favorites";
import { getMediaUrl } from "@/utils/mediaUtils";

const Favorites = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [searchQuery, setSearchQuery] = useState("");
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");
  const [hiddenIds, setHiddenIds] = useState<Set<number>>(new Set());
  const { data: favoriteAds = [], isLoading } = useFavoriteAds();

  const handleOptimisticRemove = (productId: number) => {
    setHiddenIds((prev) => new Set(prev).add(productId));
  };

  const filtered = useMemo(() => {
    return favoriteAds
      .filter((fav) => !hiddenIds.has(fav.productId))
      .filter((product) => product.productName.toLowerCase().includes(searchQuery.toLowerCase()));
  }, [favoriteAds, hiddenIds, searchQuery]);

  return (
    <div className="min-h-screen bg-white dark:bg-slate-950 flex flex-col">
      <Navbar />

      <main className="flex-1 container py-6 max-w-6xl px-4">
        {/* Barre de Navigation Haute */}
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={() => navigate(-1)}
            className="group flex items-center gap-2 p-2 hover:bg-slate-100 dark:hover:bg-slate-900 rounded-full transition-all"
          >
            <ChevronLeft className="h-5 w-5 group-hover:-translate-x-1 transition-transform" />
            <span className="text-xs font-black uppercase tracking-widest px-2">Retour</span>
          </button>

          <div className="flex gap-1 bg-slate-100 dark:bg-slate-900 rounded-full p-1 border border-slate-200 dark:border-slate-800">
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "rounded-full h-8 w-8",
                viewMode === "grid" && "bg-white dark:bg-slate-800 shadow-sm",
              )}
              onClick={() => setViewMode("grid")}
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "rounded-full h-8 w-8",
                viewMode === "list" && "bg-white dark:bg-slate-800 shadow-sm",
              )}
              onClick={() => setViewMode("list")}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* Titre & Statstiques */}
        <div className="mb-10">
          <div className="flex items-baseline gap-3">
            <h1 className="text-5xl font-black tracking-tighter italic uppercase text-slate-900 dark:text-white">
              Mes Likes
            </h1>
            <span className="text-primary font-black text-xl">({filtered.length})</span>
          </div>
          <p className="text-slate-500 font-medium mt-2">
            Les articles que vous avez aimés et que vous surveillez.
          </p>
        </div>

        {/* Bannière PRO - Style "Membership Card" */}
        <motion.div
          whileHover={{ y: -5 }}
          className="relative overflow-hidden rounded-[2rem] bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white p-8 mb-12 shadow-2xl"
        >
          <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="flex items-center gap-6">
              <div className="h-16 w-16 rounded-2xl bg-primary/20 backdrop-blur-xl border border-primary/30 flex items-center justify-center rotate-3">
                <Sparkles className="h-8 w-8 text-primary" />
              </div>
              <div className="text-center lg:text-left">
                <h2 className="text-2xl font-black uppercase italic tracking-tight">
                  Passez au niveau supérieur
                </h2>
                <p className="text-slate-400 font-medium max-w-md">
                  Devenez vendeur professionnel pour débloquer des outils de vente avancés et
                  booster vos annonces.
                </p>
              </div>
            </div>
            <Button
              asChild
              className="rounded-full bg-primary hover:bg-primary/90 text-white font-black px-10 py-7 h-auto shadow-xl shadow-primary/20 group"
            >
              <Link to="/pro" className="flex items-center gap-3">
                DEVENIR PRO{" "}
                <ArrowRight className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </Link>
            </Button>
          </div>
          {/* Cercles de fond pour le style international */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/10 rounded-full blur-[80px] -mr-32 -mt-32" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-white/5 rounded-full blur-[80px] -ml-32 -mb-32" />
        </motion.div>

        {/* Filtre de recherche élégant */}
        <div className="relative mb-12">
          <Search className="absolute left-5 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <Input
            placeholder="Rechercher dans vos likes..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="h-16 pl-14 rounded-2xl bg-slate-50 dark:bg-slate-900 border-none shadow-inner text-lg placeholder:text-slate-400"
          />
        </div>

        {/* Grille de produits */}
        <AnimatePresence mode="popLayout">
          {isLoading ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="animate-pulse bg-slate-100 dark:bg-slate-800 rounded-[2rem] aspect-[3/4]"
                />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center py-32 bg-slate-50 dark:bg-slate-900/50 rounded-[3rem] border-2 border-dashed border-slate-200 dark:border-slate-800"
            >
              <Heart className="h-20 w-20 text-slate-200 dark:text-slate-800 mx-auto mb-6" />
              <h3 className="text-2xl font-bold text-slate-900 dark:text-white">
                Aucun coup de cœur ?
              </h3>
              <p className="text-slate-500 mb-8 mt-2">
                Parcourez les annonces et cliquez sur le cœur pour les retrouver ici.
              </p>
              <Button
                asChild
                className="rounded-full px-10 h-14 font-black uppercase tracking-widest"
              >
                <Link to="/explore">Explorer les produits</Link>
              </Button>
            </motion.div>
          ) : (
            <div
              className={cn(
                "gap-8",
                viewMode === "grid"
                  ? "grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
                  : "flex flex-col",
              )}
            >
              {filtered.map((product) => (
                <FavoriteCard
                  key={product.productId}
                  product={product}
                  viewMode={viewMode}
                  onOptimisticRemove={handleOptimisticRemove}
                />
              ))}
            </div>
          )}
        </AnimatePresence>
      </main>

      <Footer />
    </div>
  );
};

// --- Composant de Carte Optimisé ---
const FavoriteCard = memo(({ product, viewMode, onOptimisticRemove }: any) => {
  const imageUrl = getMediaUrl(product.productImage ?? "");

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.9 }}
      className="group"
    >
      <Link
        to={`/produit/${product.productId}`}
        className={cn(
          "relative flex transition-all",
          viewMode === "grid"
            ? "flex-col"
            : "flex-row items-center gap-6 p-4 bg-slate-50 dark:bg-slate-900 rounded-3xl",
        )}
      >
        <div
          className={cn(
            "relative overflow-hidden bg-slate-100 rounded-[2rem]",
            viewMode === "grid" ? "aspect-[3/4] w-full" : "h-24 w-24 shrink-0",
          )}
        >
          <img
            src={imageUrl}
            alt={product.productName}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

          {/* Bouton Like (Rouge quand actif) */}
          <div
            className="absolute top-4 right-4"
            onClick={(e) => {
              e.preventDefault();
              onOptimisticRemove(product.productId);
            }}
          >
            <FavoriteButton
              productId={product.productId}
              className="h-10 w-10 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md shadow-xl text-primary"
              initialIsFavorite={true}
            />
          </div>
        </div>

        <div className={viewMode === "grid" ? "mt-4 px-2" : "flex-1"}>
          <h3 className="font-black text-slate-900 dark:text-white uppercase italic tracking-tighter text-lg line-clamp-1 leading-none">
            {product.productName}
          </h3>
          <div className="flex justify-between items-center mt-2">
            <span className="text-primary font-black text-xl">
              {product.basePrice.toLocaleString()} DH
            </span>
            {viewMode === "grid" && (
              <div className="h-8 w-8 rounded-full border border-slate-200 flex items-center justify-center group-hover:bg-slate-900 group-hover:text-white transition-colors">
                <ShoppingBag className="h-4 w-4" />
              </div>
            )}
          </div>
        </div>
      </Link>
    </motion.div>
  );
});

export default Favorites;
