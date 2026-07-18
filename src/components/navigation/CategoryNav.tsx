import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ChevronDown, Loader } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useNavbarCategories } from "@/hooks/useCategories"; // Remplacement par le nouveau hook[cite: 3]

interface CategoryNavBarProps {
  onFilter: (filters: { categoryId?: number; subCategoryId?: number; label: string }) => void;
}

const CategoryNav = ({ onFilter }: CategoryNavBarProps) => {
  const { t } = useTranslation();
  
  // Utilisation du hook dédié pour l'API navbar[cite: 3]
  const { data: categories = [], isLoading } = useNavbarCategories();
  const [activeCategory, setActiveCategory] = useState<number | null>(null);

  // Fermer le menu après une sélection
  const handleSelection = (catId?: number, subId?: number, label: string = "") => {
    onFilter({ categoryId: catId, subCategoryId: subId, label });
    setActiveCategory(null);
  };

  if (isLoading)
    return (
      <div className="h-10 flex items-center px-4">
        <Loader className="animate-spin h-4 w-4" />
      </div>
    );

  return (
    <nav className="relative flex items-center border-b border-gray-200 bg-white px-6 h-12 gap-8 z-50">
      {categories.map((cat) => {
        // Extraction robuste pour supporter la BDD (majuscules) et l'ancien code[cite: 3]
        const catId = cat.CategoryID ?? cat.id;
        const catName = cat.Name ?? cat.name ?? cat.nom ?? "";

        if (!catId) return null;

        return (
          <div
            key={catId}
            className="relative h-full flex items-center"
            onMouseEnter={() => setActiveCategory(catId)}
            onMouseLeave={() => setActiveCategory(null)}
          >
            {/* Libellé Catégorie Parente */}
            <button
              className={`flex items-center gap-1 text-sm font-medium transition-colors hover:text-teal-600 ${
                activeCategory === catId ? "text-teal-600" : "text-gray-600"
              }`}
            >
              {t(catName)}
              <ChevronDown
                size={14}
                className={`transition-transform ${activeCategory === catId ? "rotate-180" : ""}`}
              />
            </button>

            {/* Menu Déroulant (Dropdown) */}
            <AnimatePresence>
              {activeCategory === catId && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 10 }}
                  className="absolute top-full left-0 w-64 bg-white border border-gray-100 shadow-2xl rounded-b-xl p-2 mt-0"
                >
                  {/* OPTION : VOIR TOUT (Filtre par Parent ID) */}
                  <button
                    onClick={() => handleSelection(catId, undefined, catName)}
                    className="w-full text-left px-4 py-3 text-sm font-bold text-teal-600 hover:bg-teal-50 rounded-lg border-b border-gray-50 mb-1"
                  >
                    {t("Voir tout")} {t(catName)}
                  </button>

                  {/* LISTE DES SOUS-CATEGORIES */}
                  <div className="flex flex-col max-h-96 overflow-y-auto">
                    {cat.children?.map((sub) => {
                      const subId = sub.CategoryID ?? sub.id;
                      const subName = sub.Name ?? sub.name ?? sub.nom ?? "";

                      if (!subId) return null;

                      return (
                        <button
                          key={subId}
                          onClick={() => handleSelection(undefined, subId, subName)}
                          className="w-full text-left px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 hover:text-black rounded-md transition-all"
                        >
                          {t(subName)}
                        </button>
                      );
                    })}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        );
      })}
    </nav>
  );
};

export default CategoryNav;