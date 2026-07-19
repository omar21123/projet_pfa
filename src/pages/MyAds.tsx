import { useState, useEffect, useRef, useCallback } from "react";
import { adsMeApi } from "@/api/ads_me_.api";
import { env } from "@/config/env";
import type { AnnonceDto } from "@/types";
import { AdStatus } from "@/types/ad.types";
import AdCard from "@/components/AdCard";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import LoadingSkeleton from "@/components/LoadingSkeleton";
import { Button } from "@/components/ui/button";
import { PlusCircle, PackageOpen, AlertCircle, LayoutGrid } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion"; // Pour des transitions fluides
import { Link } from "react-router-dom";
import { useLanguage } from "@/contexts/LanguageContext";

const ALL_TAB = AdStatus.tous;

const resolveImageUrl = (path?: string) => {
  if (!path) return "/placeholder-ad.png"; // Image par défaut
  if (/^https?:\/\//i.test(path)) return path;
  const baseUrl = env.apiUrl || "https://localhost:7111";
  return new URL(path, baseUrl).toString();
};

const MyAds = () => {
  const { t } = useLanguage();
  const [ads, setAds] = useState<AnnonceDto[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<string>(ALL_TAB);
  const abortRef = useRef<AbortController | null>(null);

  const fetchAds = useCallback(async (status?: AdStatus) => {
    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setIsLoading(true);
    setError(null);

    try {
      const userAds = await adsMeApi.getMine(status, controller.signal);
      setAds(userAds);
    } catch (err: unknown) {
      if (err instanceof Error && (err.name === "CanceledError" || err.name === "AbortError"))
        return;
      setError("Une erreur est survenue lors du chargement de vos annonces.");
      console.error(err);
    } finally {
      if (!controller.signal.aborted) {
        setIsLoading(false);
      }
    }
  }, []);

  useEffect(() => {
    fetchAds(AdStatus.tous);
    return () => abortRef.current?.abort();
  }, [fetchAds]);

  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    fetchAds(tab === ALL_TAB ? undefined : (tab as AdStatus));
  };

  return (
    <div className="min-h-screen bg-slate-50/50 dark:bg-slate-950/50">
      <div className="container mx-auto px-4 py-10 max-w-7xl">
        {/* --- HEADER SECTION --- */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
          <div>
            <h1 className="text-4xl font-extrabold tracking-tight lg:text-5xl mb-2">
              Mes annonces
            </h1>
            <p className="text-muted-foreground text-lg">
              Gérez, modifiez et suivez la performance de vos publications.
            </p>
          </div>
          <motion.div whileHover={{ scale: 1.05 }} transition={{ duration: 0.2 }}>
            <Link to="/create">
              <Button className="bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl gap-2 font-semibold">
                <span className="hidden sm:inline">{t("publish")}</span>
              </Button>
            </Link>
          </motion.div>
        </div>

        {/* --- TABS SECTION --- */}
        <Tabs value={activeTab} onValueChange={handleTabChange} className="space-y-8">
          <div className="sticky top-0 z-10 bg-background/80 backdrop-blur-md pb-4 pt-2 -mx-4 px-4 overflow-x-auto no-scrollbar">
            <TabsList className="h-12 p-1 bg-muted/50 inline-flex min-w-full md:min-w-max border">
              <TabsTrigger value={ALL_TAB} className="px-6">
                Toutes
              </TabsTrigger>
              <TabsTrigger value={AdStatus.PUBLISHED}>Publiées</TabsTrigger>
              <TabsTrigger value={AdStatus.PENDING_VALIDATION}>En attente</TabsTrigger>
              <TabsTrigger value={AdStatus.DRAFT}>Brouillons</TabsTrigger>
              <TabsTrigger value={AdStatus.SOLD}>Vendues</TabsTrigger>
              <TabsTrigger value={AdStatus.ARCHIVED}>Archivées</TabsTrigger>
            </TabsList>
          </div>

          <TabsContent value={activeTab} className="mt-0 focus-visible:outline-none">
            {isLoading ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                <LoadingSkeleton count={8} />
              </div>
            ) : error ? (
              <div className="flex flex-col items-center justify-center py-20 text-center border-2 border-dashed rounded-2xl bg-white">
                <AlertCircle className="w-12 h-12 text-destructive mb-4" />
                <h3 className="text-xl font-semibold">{error}</h3>
                <Button
                  variant="outline"
                  className="mt-4"
                  onClick={() => fetchAds(activeTab as AdStatus)}
                >
                  Réessayer
                </Button>
              </div>
            ) : ads.length === 0 ? (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed rounded-3xl bg-white dark:bg-slate-900 shadow-sm"
              >
                <div className="bg-primary/10 p-4 rounded-full mb-4">
                  <PackageOpen className="w-10 h-10 text-primary" />
                </div>
                <h3 className="text-xl font-bold">Aucune annonce trouvée</h3>
                <p className="text-muted-foreground max-w-xs mx-auto mt-2">
                  {activeTab !== ALL_TAB
                    ? `Vous n'avez pas encore d'annonces avec le statut "${activeTab}".`
                    : "Vous n'avez pas encore publié d'annonces sur AdsMe."}
                </p>
              </motion.div>
            ) : (
              <motion.div
                layout
                className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
              >
                <AnimatePresence mode="popLayout">
                  {ads.map((ad) => (
                    <motion.div
                      key={ad.id}
                      layout
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                      transition={{ duration: 0.2 }}
                    >
                      <AdCard
                        id={ad.id.toString()}
                        title={ad.titre}
                        price={ad.prix}
                        city={ad.ville}
                        image={resolveImageUrl(ad.photosUrls[0])}
                        date={new Date(ad.datepublication).toLocaleDateString("fr-FR", {
                          day: "numeric",
                          month: "short",
                        })}
                        favoritesCount={ad.numberoffavorites}
                        isFollowed={ad.isFollowed}
                        // Note: Tu pourrais ajouter une prop "status" à AdCard pour afficher un badge
                      />
                    </motion.div>
                  ))}
                </AnimatePresence>
              </motion.div>
            )}
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default MyAds;
