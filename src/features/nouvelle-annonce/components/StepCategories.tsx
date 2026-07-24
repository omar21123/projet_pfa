import { useState } from "react";
import { ChevronRight, ArrowLeft, Check, X } from "lucide-react";
import { useNavbarCategories } from "@/hooks/useCategories";
import type { FormState } from "@/types/types";
import { getCatId, getCatName } from "@/types/types";
import { CategoryChip, SectionTitle } from "./shared";

export function StepCategories({ form, setField }: { form: FormState; setField: any }) {
  const { data: categories = [], isLoading } = useNavbarCategories();

  // État pour la catégorie parent active/cliquée
  const [selectedParentId, setSelectedParentId] = useState<number | null>(null);

  const toggle = (id: number) => {
    const exists = form.categories.includes(id);
    setField("categories", exists ? form.categories.filter((c) => c !== id) : [...form.categories, id]);
  };

  if (isLoading) return <div className="p-4 animate-pulse bg-slate-100 rounded-xl h-24" />;

  // Recherche de la catégorie parent sélectionnée
  const activeParent = categories.find((cat) => getCatId(cat) === selectedParentId);

  return (
    <div className="space-y-6">
      <SectionTitle
        title="Catégories"
        subtitle="Cliquez sur une catégorie principale pour explorer et choisir ses sous-catégories."
      />

      {/* ============================================================ */}
      {/* VUE 1 : LISTE DES CATÉGORIES PRINCIPALES                      */}
      {/* ============================================================ */}
      {!selectedParentId ? (
        <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-3">
          {categories.map((cat) => {
            const catId = getCatId(cat);
            if (!catId) return null;

            const subCount = cat.children?.length ?? 0;
            const isSelected = form.categories.includes(catId);

            return (
              <button
                key={catId}
                type="button"
                onClick={() => setSelectedParentId(catId)}
                className="group flex items-center justify-between p-4 rounded-xl border border-slate-200 bg-white hover:border-[#375260] hover:shadow-sm transition-all text-left"
              >
                <div>
                  <h4 className="font-semibold text-slate-800 text-sm group-hover:text-[#375260] transition-colors">
                    {getCatName(cat)}
                  </h4>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {subCount > 0 ? `${subCount} sous-catégories` : "Aucune sous-catégorie"}
                  </p>
                </div>
                
                <div className="flex items-center gap-2">
                  {isSelected && (
                    <span className="p-1 bg-emerald-100 text-emerald-700 rounded-full">
                      <Check className="size-3.5" />
                    </span>
                  )}
                  <ChevronRight className="size-4 text-slate-400 group-hover:text-[#375260] group-hover:translate-x-0.5 transition-all" />
                </div>
              </button>
            );
          })}
        </div>
      ) : (
        /* ============================================================ */
        /* VUE 2 : SOUS-CATÉGORIES D'UNE CATÉGRIE SÉLECTIONNÉE           */
        /* ============================================================ */
        <div className="space-y-5 bg-slate-50/70 p-5 rounded-xl border border-slate-200">
          {/* En-tête avec bouton retour */}
          <div className="flex items-center justify-between border-b border-slate-200 pb-3">
            <button
              type="button"
              onClick={() => setSelectedParentId(null)}
              className="flex items-center gap-2 text-xs font-semibold text-[#375260] hover:underline"
            >
              <ArrowLeft className="size-4" />
              Retour aux catégories
            </button>
            
            <span className="text-sm font-bold text-slate-800">
              {activeParent ? getCatName(activeParent) : ""}
            </span>
          </div>

          {/* Option pour cocher la catégorie principale elle-même */}
          {activeParent && (
            <div>
              <label className="text-xs font-semibold text-slate-500 uppercase block mb-2">
                Catégorie principale
              </label>
              <CategoryChip
                label={getCatName(activeParent)}
                active={form.categories.includes(selectedParentId)}
                onClick={() => toggle(selectedParentId)}
              />
            </div>
          )}

          {/* Liste des sous-catégories */}
          <div>
            <label className="text-xs font-semibold text-slate-500 uppercase block mb-2">
              Sous-catégories disponibles
            </label>

            {activeParent?.children && activeParent.children.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {activeParent.children.map((sub) => {
                  const subId = getCatId(sub);
                  if (!subId) return null;
                  return (
                    <CategoryChip
                      key={subId}
                      label={getCatName(sub)}
                      active={form.categories.includes(subId)}
                      onClick={() => toggle(subId)}
                    />
                  );
                })}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucune sous-catégorie disponible.</p>
            )}
          </div>
        </div>
      )}

      {/* ============================================================ */}
      {/* RÉSUMÉ DES CATÉGORIES SÉLECTIONNÉES                          */}
      {/* ============================================================ */}
      {form.categories.length > 0 && (
        <div className="pt-4 border-t border-slate-100">
          <p className="text-xs font-semibold text-slate-500 mb-2">
            Catégories sélectionnées ({form.categories.length}) :
          </p>
          <div className="flex flex-wrap gap-1.5">
            {categories
              .flatMap((c) => [c, ...(c.children || [])])
              .map((item) => {
                const id = getCatId(item);
                if (!id || !form.categories.includes(id)) return null;

                return (
                  <span
                    key={id}
                    className="inline-flex items-center gap-1.5 px-3 py-1 bg-[#375260]/10 text-[#375260] text-xs font-medium rounded-lg"
                  >
                    {getCatName(item)}
                    <button
                      type="button"
                      onClick={() => toggle(id)}
                      className="hover:text-red-600 transition-colors"
                    >
                      <X className="size-3" />
                    </button>
                  </span>
                );
              })}
          </div>
        </div>
      )}
    </div>
  );
}