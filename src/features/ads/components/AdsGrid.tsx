import { useState, useMemo, useCallback } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import AdCard from "./AdCard";
import FilterSidebar, { type Filters } from "@/components/search/FilterSidebar";
import { motion, AnimatePresence } from "framer-motion";
import { SlidersHorizontal, X, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useLanguage } from "@/contexts/LanguageContext";
import { useAds } from "@/features/ads/hooks/useAds";
import { getMediaUrl } from "@/utils/mediaUtils";

const formatDate = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "Non renseignée";
  }
  return date.toLocaleDateString("fr-FR", { day: "numeric", month: "short", year: "numeric" });
};

const defaultFilters: Filters = {
  priceRange: [0, 1000000],
  categories: [],
  cities: [],
  dateFrom: undefined,
  dateTo: undefined,
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08 } },
};
const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6 } },
};

const AdsGrid = () => {
  const { t } = useLanguage();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const categoryId = searchParams.get("category");
  const subCategoryId = searchParams.get("subCategory");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [filters, setFilters] = useState<Filters>(defaultFilters);

  const villeFromFilters = filters.cities && filters.cities.length > 0 ? filters.cities[0] : null;
  const villeFromParams = searchParams.get("ville");
  const villeToSend = villeFromFilters ?? (villeFromParams !== null ? villeFromParams : undefined);

  const {
    data: ads = [],
    isLoading,
    isError,
    error,
  } = useAds({
    categoryId: categoryId !== null ? Number(categoryId) : 0,
    subCategoryId: subCategoryId !== null ? Number(subCategoryId) : 0,
    ville: villeToSend ?? undefined,
  });

  const openSidebar = useCallback(() => setSidebarOpen(true), []);
  const closeSidebar = useCallback(() => setSidebarOpen(false), []);
  const clearAllFilters = useCallback(() => {
    setFilters(defaultFilters);
    const params = new URLSearchParams();
    params.set("category", "0");
    params.set("subCategory", "0");
    navigate(`/?${params.toString()}`);
  }, [navigate]);

  const activeFilterCount = useMemo(() => {
    let count = 0;
    if (filters.priceRange[0] > 0 || filters.priceRange[1] < 1000000) count++;
    count += filters.categories.length;
    count += filters.cities.length;
    if (filters.dateFrom) count++;
    if (filters.dateTo) count++;
    return count;
  }, [filters]);

  const filteredAds = useMemo(() => {
    return ads.filter((ad) => {
      if (ad.prix < filters.priceRange[0] || ad.prix > filters.priceRange[1]) return false;
      if (filters.categories.length > 0 && !filters.categories.includes(ad.categorie)) return false;
      if (filters.cities.length > 0 && !filters.cities.includes(ad.ville)) return false;
      return true;
    });
  }, [ads, filters]);

  const noResultsMessage = useMemo(() => {
    if (categoryId || subCategoryId || activeFilterCount > 0) {
      return "Aucune annonce ne correspond à ces critères.";
    }
    return t("no_ads_found");
  }, [categoryId, subCategoryId, activeFilterCount, t]);

  const cardAds = useMemo(
    () =>
      filteredAds.map((ad) => ({
        id: String(ad.id),
        title: ad.titre,
        price: ad.prix,
        city: ad.ville || "Non renseignée",
        image: getMediaUrl(ad.photosUrls[0]),
        date: formatDate(ad.datepublication),
        ownerId: ad.idutilisateur,
        favoritesCount: ad.numberoffavorites,
        isFollowed: ad.isFollowed,
      })),
    [filteredAds],
  );

  const activeChips = useMemo(() => {
    const chips: { label: string; onRemove: () => void }[] = [];
    if (filters.priceRange[0] > 0 || filters.priceRange[1] < 1000000) {
      chips.push({
        label: `${filters.priceRange[0].toLocaleString()} - ${filters.priceRange[1].toLocaleString()} DH`,
        onRemove: () => setFilters((f) => ({ ...f, priceRange: [0, 1000000] })),
      });
    }
    filters.categories.forEach((cat) =>
      chips.push({
        label: cat,
        onRemove: () =>
          setFilters((f) => ({ ...f, categories: f.categories.filter((c) => c !== cat) })),
      }),
    );
    filters.cities.forEach((city) =>
      chips.push({
        label: city,
        onRemove: () => setFilters((f) => ({ ...f, cities: f.cities.filter((c) => c !== city) })),
      }),
    );
    return chips;
  }, [filters]);

  return (
    <section className="py-8">
      <div className="container">
        <motion.div
          className="flex items-center justify-between mb-5"
          initial={{ opacity: 0, x: -20 }}
          whileInView={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5 }}
          viewport={{ once: true }}
        >
          <h2 className="text-xl font-heading font-bold">{t("recent_ads")}</h2>
          <div className="flex items-center gap-2">
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button variant="outline" size="sm" onClick={openSidebar} className="gap-2">
                <SlidersHorizontal className="h-4 w-4" />
                {t("filters")}
                {activeFilterCount > 0 && (
                  <Badge variant="default" className="text-xs px-1.5 py-0 ml-1">
                    {activeFilterCount}
                  </Badge>
                )}
              </Button>
            </motion.div>
            <motion.button
              className="text-sm font-semibold text-primary hover:text-primary-hover transition-colors"
              whileHover={{ x: 5 }}
            >
              {t("view_all")}
            </motion.button>
          </div>
        </motion.div>

        <AnimatePresence>
          {activeChips.length > 0 && (
            <motion.div
              className="flex flex-wrap gap-2 mb-4"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
            >
              {activeChips.map((chip) => (
                <motion.span
                  key={chip.label}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8 }}
                  className="inline-flex items-center gap-1 text-xs bg-accent text-accent-foreground px-3 py-1.5 rounded-full border border-border"
                >
                  {chip.label}
                  <button
                    onClick={chip.onRemove}
                    className="ml-1 hover:text-destructive transition-colors"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </motion.span>
              ))}
              <motion.button
                whileHover={{ scale: 1.05 }}
                onClick={clearAllFilters}
                className="text-xs text-muted-foreground hover:text-foreground transition-colors underline"
              >
                {t("clear_all")}
              </motion.button>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="flex gap-6">
          <FilterSidebar
            isOpen={sidebarOpen}
            onClose={closeSidebar}
            filters={filters}
            onFiltersChange={setFilters}
            onApply={() => {
              const params = new URLSearchParams();
              params.set("category", String(categoryId !== null ? Number(categoryId) : 0));
              params.set("subCategory", String(subCategoryId !== null ? Number(subCategoryId) : 0));
              if (filters.cities && filters.cities.length > 0) {
                params.set("ville", String(filters.cities[0]));
              }
              navigate(`/?${params.toString()}`);
            }}
            onReset={clearAllFilters}
            activeFilterCount={activeFilterCount}
          />
          <div className="flex-1">
            <AnimatePresence mode="wait">
              {isLoading ? (
                <motion.div
                  key="loading"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                >
                  {Array.from({ length: 8 }).map((_, index) => (
                    <div
                      key={index}
                      className="h-72 rounded-2xl border border-border bg-muted/40 animate-pulse"
                    />
                  ))}
                </motion.div>
              ) : isError ? (
                (() => {
                  const axiosErr = error as { response?: { status?: number } } | null;
                  if (axiosErr?.response?.status === 404) {
                    return (
                      <motion.div
                        key="not-found"
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-center py-16"
                      >
                        <div className="mx-auto mb-6 w-20 h-20 rounded-full bg-muted/40 flex items-center justify-center">
                          <Search className="h-8 w-8 text-muted-foreground" />
                        </div>
                        <h3 className="text-2xl font-semibold mb-2">Aucune annonce trouvée</h3>
                        <p className="text-sm text-muted-foreground mb-4">
                          Aucune annonce ne correspond à cette catégorie. Veuillez changer de
                          catégorie ou essayer d'autres produits.
                        </p>
                        <div className="flex items-center justify-center gap-3">
                          <Button variant="outline" onClick={clearAllFilters}>
                            Effacer les filtres
                          </Button>
                        </div>
                      </motion.div>
                    );
                  }

                  return (
                    <motion.div
                      key="error"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="text-center py-16"
                    >
                      <p className="text-muted-foreground text-lg mb-2">
                        Impossible de charger les annonces
                      </p>
                      <p className="text-sm text-muted-foreground mb-4">
                        Vérifie l’API `/api/Annonce/getall` et la configuration `VITE_API_URL`.
                      </p>
                    </motion.div>
                  );
                })()
              ) : cardAds.length > 0 ? (
                <motion.div
                  key="grid"
                  className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                  variants={containerVariants}
                  initial="hidden"
                  animate="visible"
                >
                  {cardAds.map((ad) => (
                    <motion.div key={ad.id} variants={itemVariants} layout>
                      <AdCard {...ad} />
                    </motion.div>
                  ))}
                </motion.div>
              ) : (
                <motion.div
                  key="empty"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  className="text-center py-16"
                >
                  <p className="text-muted-foreground text-lg mb-2">{noResultsMessage}</p>
                  <p className="text-sm text-muted-foreground mb-4">
                    {t("try_different_criteria")}
                  </p>
                  <Button variant="outline" onClick={clearAllFilters}>
                    {t("reset_filters")}
                  </Button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AdsGrid;
