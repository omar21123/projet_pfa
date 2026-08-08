import { useState } from "react";
import { ChevronRight, ArrowLeft, Check, X, RefreshCw } from "lucide-react";
import { useNavbarCategories } from "@/hooks/useCategories";
import type { FormState } from "@/features/nouvelle-annonce/types";
import { getCatId, getCatName } from "@/features/nouvelle-annonce/types";
import { CategoryChip, SectionTitle } from "./shared";

interface StepCategoriesProps {
  form: FormState;
  setField: <K extends keyof FormState>(field: K, value: FormState[K]) => void;
}

export function StepCategories({ form, setField }: StepCategoriesProps) {
  const { data: categories = [], isLoading, refetch, isRefetching } = useNavbarCategories();
  const [selectedParentId, setSelectedParentId] = useState<number | null>(null);

  const toggle = (id: number) => {
    const exists = form.categories.includes(id);
    setField("categories", exists ? form.categories.filter((c) => c !== id) : [...form.categories, id]);
  };

  const activeParent = categories.find((cat) => getCatId(cat) === selectedParentId);

  return (
    <div className="space-y-6">
      <SectionTitle
        title="Catégories"
        subtitle="Cliquez sur une catégorie principale pour explorer et choisir ses sous-catégories."
      />

      {isLoading ? (
        <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="p-4 rounded-xl border border-slate-200 bg-white animate-pulse">
              <div className="h-4 bg-slate-200 rounded w-3/4 mb-2" />
              <div className="h-3 bg-slate-100 rounded w-1/2" />
            </div>
          ))}
        </div>
      ) : categories.length === 0 ? (
        <div className="text-center py-10 space-y-4">
          <p className="text-sm text-slate-400 italic">
            Aucune catégorie disponible pour le moment.
          </p>
          <button
            type="button"
            onClick={() => refetch()}
            disabled={isRefetching}
            className="inline-flex items-center gap-2 h-9 px-4 rounded-lg bg-[#375260] text-white text-xs font-semibold hover:bg-[#2c424e] disabled:opacity-40 transition-colors"
          >
            <RefreshCw className={`size-3.5 ${isRefetching ? "animate-spin" : ""}`} />
            {isRefetching ? "Chargement..." : "Réessayer"}
          </button>
        </div>
      ) : !selectedParentId ? (
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
        <div className="space-y-5 bg-slate-50/70 p-5 rounded-xl border border-slate-200">
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