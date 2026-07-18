import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  ChevronRight,
  LayoutGrid,
  Shirt,
  Footprints,
  Watch,
  Grid3X3,
  Package,
  Sparkles,
  User,
  Users,
  Baby,
  Home,
  Smartphone,
  Activity,
  ShoppingBag,
  Glasses,
  Heart,
  Zap,
  Briefcase,
  Crown,
  Star,
  Gem,
} from "lucide-react";
import { useTranslation } from "react-i18next";
import { useNavbarCategories, type CategoryNode } from "@/hooks/useCategories";

interface CategoriesProps {
  onFilter: (filters: {
    categoryId?: number | null;
    subCategoryId?: number | null;
    label: string;
  }) => void;
}

// Extraction robuste : supporte PascalCase (.NET), snake_case (Laravel) et l'ancien mock (id/nom)
const getCatId = (cat: CategoryNode): number | undefined =>
  cat.CategoryID ?? cat.category_id ?? cat.id;

const getCatName = (cat: CategoryNode): string =>
  cat.Name ?? cat.name ?? cat.nom ?? "";

const getCategoryIcon = (name: string) => {
  const n = name.toLowerCase();
  if (n.includes("femme")) return User;
  if (n.includes("homme")) return Users;
  if (n.includes("enfant")) return Baby;
  if (n.includes("maison")) return Home;
  if (n.includes("électro") || n.includes("electro")) return Smartphone;
  if (n.includes("sport")) return Activity;
  if (n.includes("vêt") || n.includes("vet")) return Shirt;
  return LayoutGrid;
};

const getSubCategoryIcon = (name: string) => {
  const n = name.toLowerCase();

  // Vêtements
  if (n.includes("t-shirt") || n.includes("shirt") || n.includes("chemise")) return Shirt;
  if (n.includes("robe") || n.includes("jupe")) return Crown;
  if (n.includes("pantalon") || n.includes("jean")) return Briefcase;
  if (n.includes("veste") || n.includes("manteau") || n.includes("blouson")) return Package;
  if (n.includes("pull") || n.includes("sweat")) return Shirt;

  // Chaussures
  if (n.includes("chauss") || n.includes("basket") || n.includes("sneaker")) return Footprints;
  if (n.includes("botte") || n.includes("sandal")) return Footprints;

  // Accessoires
  if (n.includes("sac") || n.includes("bag")) return ShoppingBag;
  if (n.includes("bijou") || n.includes("collier") || n.includes("bague")) return Gem;
  if (n.includes("montre")) return Watch;
  if (n.includes("lunette")) return Glasses;
  if (n.includes("ceinture") || n.includes("écharpe") || n.includes("foulard")) return Star;

  // Beauté & Soins
  if (n.includes("soin") || n.includes("beauté") || n.includes("cosmé")) return Sparkles;
  if (n.includes("parfum")) return Heart;

  // Sport
  if (n.includes("sport") || n.includes("fitness")) return Activity;
  if (n.includes("running") || n.includes("training")) return Zap;

  return LayoutGrid;
};

const Categories = ({ onFilter }: CategoriesProps) => {
  const { t } = useTranslation();
  // Hook public (route /api/categories/navbar) : fonctionne pour un visiteur non connecté
  const { data: categories = [], isLoading } = useNavbarCategories();
  const [activeCategory, setActiveCategory] = useState<number | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Fermer au clic à l'extérieur
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setActiveCategory(null);
      }
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  const toggle = (id: number) => {
    setActiveCategory((cur) => (cur === id ? null : id));
  };

  const handleSelection = (catId: number | null, subId: number | null, label = "") => {
    onFilter({ categoryId: catId, subCategoryId: subId, label });
    setActiveCategory(null);
  };

  if (isLoading) {
    return (
      <div className="relative z-40 bg-background border-b border-border w-full">
        <div className="container relative">
          <div className="flex items-center gap-8 h-14 overflow-visible">
            <div className="text-muted-foreground text-sm animate-pulse">
              Chargement des catégories...
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative z-40 bg-background border-b border-border w-full">
      <div ref={containerRef} className="container relative">
        <div className="flex items-center gap-8 h-14 overflow-visible whitespace-nowrap">
          {categories.map((cat) => {
            const catId = getCatId(cat);
            const catName = getCatName(cat);
            if (!catId) return null;

            const isActive = activeCategory === catId;
            const CategoryIcon = getCategoryIcon(catName);

            return (
              <div key={catId} className="h-full flex items-center shrink-0">
                <button
                  type="button"
                  onClick={() => toggle(catId)}
                  className={`relative h-full px-1 text-base font-medium transition-colors flex items-center gap-2 ${
                    isActive
                      ? "text-foreground after:absolute after:left-0 after:right-0 after:bottom-0 after:h-0.5 after:bg-primary"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  <CategoryIcon className="h-5 w-5" />
                  <span>{t(catName)}</span>
                </button>

                <AnimatePresence>
                  {isActive && (
                    <motion.div
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 8 }}
                      transition={{ duration: 0.2, ease: "easeOut" }}
                      className="absolute left-0 right-0 top-full z-[999] bg-popover/95 backdrop-blur-lg text-popover-foreground border-t border-border shadow-xl"
                    >
                      <div className="container py-6">
                        <div className="w-full max-w-4xl mx-auto">
                          {/* Bouton "Voir tout" en vedette */}
                          <button
                            type="button"
                            onClick={() => handleSelection(catId, 0, catName)}
                            className="group flex items-center gap-3 px-4 py-3 mb-4 w-full rounded-lg bg-primary/10 hover:bg-primary/20 transition-all duration-200"
                          >
                            <div className="flex items-center justify-center w-10 h-10 rounded-full bg-primary/20">
                              <Grid3X3 className="h-5 w-5 text-primary" />
                            </div>
                            <span className="text-base font-semibold text-foreground">
                              {t("Voir tout")} {t(catName)}
                            </span>
                            <ChevronRight className="h-5 w-5 ml-auto text-primary group-hover:translate-x-1 transition-transform" />
                          </button>

                          {/* Grille des sous-catégories */}
                          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
                            {cat.children?.map((sub) => {
                              const subId = getCatId(sub);
                              const subName = getCatName(sub);
                              if (!subId) return null;

                              const SubIcon = getSubCategoryIcon(subName);
                              const hasChildren = Boolean(sub.children?.length);

                              return (
                                <button
                                  key={subId}
                                  type="button"
                                  onClick={() => handleSelection(catId, subId, subName)}
                                  className="group relative flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-all duration-200 hover:bg-accent hover:scale-[1.02]"
                                >
                                  <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-primary/10 group-hover:bg-primary/20 transition-colors">
                                    <SubIcon className="h-4.5 w-4.5 text-primary" />
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <span className="text-sm font-medium text-foreground group-hover:text-primary transition-colors line-clamp-2">
                                      {t(subName)}
                                    </span>
                                  </div>
                                  {hasChildren && (
                                    <ChevronRight className="h-4 w-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity absolute right-2 top-1/2 -translate-y-1/2" />
                                  )}
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default Categories;