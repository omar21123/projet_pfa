import { useMemo, useState, memo } from "react";
import { 
  Heart, 
  Clock, 
  Search, 
  Grid3X3, 
  List, 
  ChevronLeft, 
  Sparkles, 
  ArrowRight 
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

// --- Composant de Carte (Grid/List) ---
const FavoriteCard = memo(function FavoriteCard({
  product,
  viewMode,
  onOptimisticRemove,
}: {
  product: FavoriteProduct;
  viewMode: "grid" | "list";
  onOptimisticRemove: (productId: number) => void;
}) {
  const imageUrl = getMediaUrl(product.productImage ?? "");
  const handleRemoveCapture = (e: React.MouseEvent) => {
    e.preventDefault(); // Évite la navigation du Link
    onOptimisticRemove(product.productId);
  };

  if (viewMode === "grid") {
    return (
      <motion.div
        layout
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
      >
        <Link 
          to={`/produit/${product.productId}`} 
          className="group block bg-white dark:bg-slate-950 rounded-2xl border border-slate-100 dark:border-slate-800 overflow-hidden hover:shadow-xl transition-all duration-300"
        >
          <div className="relative aspect-square overflow-hidden bg-slate-100">
            <img src={imageUrl} alt={product.productName} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" />
            <div className="absolute top-2 right-2" onClick={handleRemoveCapture}>
              <FavoriteButton
                productId={product.productId}
                className="h-8 w-8 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md shadow-sm"
                initialIsFavorite={true}
              />
            </div>
          </div>
          <div className="p-4">
            <h3 className="font-bold text-sm text-slate-900 dark:text-white line-clamp-1 italic uppercase tracking-tighter">
              {product.productName}
            </h3>
            <div className="flex justify-between items-end mt-2">
              <span className="text-primary font-black text-lg">{product.basePrice.toLocaleString()} DH</span>
              <span className="text-[10px] text-slate-400 flex items-center gap-1 font-bold">
                <Clock className="h-3 w-3" /> {formatDate(product.likedAt)}
              </span>
            </div>
          </div>
        </Link>
      </motion.div>
    );
  }

  return (
    <motion.div layout>
      <Link to={`/produit/${product.productId}`} className="flex items-center gap-4 p-3 bg-white dark:bg-slate-900 rounded-2xl border border-slate-100 dark:border-slate-800 hover:shadow-md transition-all">
        <img src={imageUrl} alt={product.productName} className="w-20 h-20 rounded-xl object-cover shrink-0" />
        <div className="flex-1 min-w-0">
          <h3 className="font-bold text-sm truncate uppercase tracking-tighter">{product.productName}</h3>
          <p className="text-primary font-black">{product.basePrice.toLocaleString()} DH</p>
        </div>
        <div onClick={handleRemoveCapture}>
          <FavoriteButton productId={product.productId} className="h-10 w-10 rounded-full bg-slate-50 dark:bg-slate-800" initialIsFavorite={true} />
        </div>
      </Link>
    </motion.div>
  );
});

// --- Page Principale ---
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
      .filter((product) => 
        product.productName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (product.brandName ?? "").toLowerCase().includes(searchQuery.toLowerCase())
      );
  }, [favoriteAds, hiddenIds, searchQuery]);

  return (
    <div className="min-h-screen bg-white dark:bg-slate-950 flex flex-col">
      <Navbar />

      <main className="flex-1 container py-8 max-w-5xl">
        {/* Barre de retour et Titre */}
        <div className="flex flex-col gap-6 mb-8">
          <button 
            onClick={() => navigate(-1)} 
            className="flex items-center gap-2 text-slate-500 hover:text-primary transition-colors w-fit group"
          >
            <ChevronLeft className="h-5 w-5 transition-transform group-hover:-translate-x-1" />
            <span className="text-sm font-bold uppercase tracking-widest">Retour</span>
          </button>

          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-black tracking-tighter flex items-center gap-3 italic uppercase">
                <Heart className="h-8 w-8 text-primary fill-primary" />
                {t("my_favorites")}
              </h1>
              <p className="text-sm text-slate-500 font-medium">
                {filtered.length} {t("saved_ads")} enregistrées
              </p>
            </div>
            <div className="flex gap-1 bg-slate-100 dark:bg-slate-900 rounded-full p-1 border">
              <Button
                variant="ghost" size="icon"
                className={cn("rounded-full h-8 w-8", viewMode === "grid" && "bg-white dark:bg-slate-800 shadow-sm")}
                onClick={() => setViewMode("grid")}
              >
                <Grid3X3 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost" size="icon"
                className={cn("rounded-full h-8 w-8", viewMode === "list" && "bg-white dark:bg-slate-800 shadow-sm")}
                onClick={() => setViewMode("list")}
              >
                <List className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>

        {/* Bannière CTA PRO */}
        <motion.div 
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="relative overflow-hidden rounded-3xl bg-slate-900 text-white p-6 mb-8 shadow-2xl shadow-slate-200 dark:shadow-none"
        >
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-4 text-center md:text-left">
              <div className="h-12 w-12 rounded-2xl bg-primary flex items-center justify-center rotate-12 shadow-lg shadow-primary/20">
                <Sparkles className="h-6 w-6 text-white" />
              </div>
              <div>
                <h2 className="text-xl font-black tracking-tight uppercase italic">Boostez votre visibilité</h2>
                <p className="text-slate-400 text-sm font-medium">Vendez plus vite en passant au statut Professionnel.</p>
              </div>
            </div>
            <Button 
              asChild
              className="rounded-full bg-white text-slate-900 hover:bg-slate-100 font-black px-6 py-6 h-auto transition-transform hover:scale-105 active:scale-95"
            >
              <Link to="/pro" className="flex items-center gap-2">
                DEVENIR PRO <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
          </div>
          {/* Décoration abstraite en fond */}
          <div className="absolute top-0 right-0 -translate-y-1/2 translate-x-1/2 w-64 h-64 bg-primary/20 rounded-full blur-3xl" />
        </motion.div>

        {/* Filtre de recherche */}
        <div className="relative mb-8">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Rechercher dans vos favoris..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="h-14 pl-12 rounded-2xl bg-white dark:bg-slate-900 border-slate-200 shadow-sm focus:ring-primary focus:border-primary transition-all text-base"
          />
        </div>

        {/* Liste des produits */}
        <AnimatePresence mode="popLayout">
          {isLoading ? (
            <div className={cn("gap-6", viewMode === "grid" ? "grid sm:grid-cols-2 lg:grid-cols-3" : "space-y-4")}>
              {[1, 2, 3].map((i) => (
                <div key={i} className="animate-pulse bg-slate-100 dark:bg-slate-900 rounded-3xl h-64" />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-center py-20 border-2 border-dashed border-slate-100 rounded-3xl">
              <Heart className="h-16 w-16 text-slate-200 mx-auto mb-4" />
              <p className="text-slate-400 font-medium">Aucun favori trouvé.</p>
            </motion.div>
          ) : (
            <div className={cn("gap-6", viewMode === "grid" ? "grid sm:grid-cols-2 lg:grid-cols-3" : "flex flex-col")}>
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

export default Favorites;

// Helper function
const formatDate = (value: string) => {
  const date = new Date(value);
  return isNaN(date.getTime()) ? "Récemment" : date.toLocaleDateString("fr-FR", { day: "numeric", month: "short" });
};

interface FavoriteProduct {
  productId: number;
  productName: string;
  productImage: string | null;
  basePrice: number;
  brandName: string | null;
  likedAt: string;
}