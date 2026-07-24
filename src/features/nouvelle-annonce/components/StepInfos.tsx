// src/features/nouvelle-annonce/components/StepInfos.tsx
import { useQuery } from "@tanstack/react-query";
import axiosInstance from "@/api/axiosInstances";
import type { FormState } from "@/types/types";
import { Field, SectionTitle, inputCls } from "./shared";

export function StepInfos({ form, setField }: { form: FormState; setField: any }) {
  // 1. Récupération des marques
  const { data: brandsRes } = useQuery({
    queryKey: ["brands-list"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/brands");
      return res.data;
    },
  });

  // 2. Récupération des modèles
  const { data: modelsRes } = useQuery({
    queryKey: ["models-list"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/models");
      return res.data;
    },
  });

  // Extrait le tableau de données peu importe le format Laravel (Direct, .data ou .data.data)
  const extractArray = (res: any) => {
    if (!res) return [];
    if (Array.isArray(res)) return res;
    if (Array.isArray(res.data)) return res.data;
    if (res.data && Array.isArray(res.data.data)) return res.data.data; // Cas API paginée
    return [];
  };

  const brands = extractArray(brandsRes);
  const models = extractArray(modelsRes);

  // Empêche le bug du NaN dans React
  const getSafeValue = (val: any) => {
    if (val === null || val === undefined || isNaN(val)) return "";
    return val;
  };

  // Récupère la marque actuellement sélectionnée (objet complet)
  const selectedBrand = brands.find((b: any) => {
    const bId = b.id ?? b.BrandID ?? b.brand_id;
    return Number(bId) === Number(form.brandId);
  });

  // Cherche l'ID de marque sur un modèle, quelle que soit la forme renvoyée par l'API
  const findModelBrandId = (m: any): number | null => {
    const direct =
      m.brand_id ??
      m.BrandID ??
      m.brandId ??
      m.brand?.id ??
      m.brand?.BrandID ??
      m.brand?.brand_id;
    if (direct !== undefined && direct !== null) return Number(direct);
    return null;
  };

  // 🎯 FILTRAGE : essaie d'abord par ID (si le backend le renvoie un jour),
  // sinon retombe sur un matching par nom de marque (BrandName), insensible à la casse/espaces
  const filteredModels = models.filter((m: any) => {
    if (!form.brandId) return false;

    const mBrandId = findModelBrandId(m);
    if (mBrandId !== null) {
      return mBrandId === Number(form.brandId);
    }

    // Fallback par nom (cas actuel de l'API : le modèle n'a que "BrandName")
    if (!selectedBrand) return false;
    const brandName = selectedBrand.Name ?? selectedBrand.name ?? selectedBrand.nom ?? "";
    const modelBrandName = m.BrandName ?? m.brandName ?? m.brand_name ?? "";
    return modelBrandName.trim().toLowerCase() === brandName.trim().toLowerCase();
  });

  return (
    <div className="space-y-6">
      <SectionTitle title="Informations générales" subtitle="Nom, code-barres, description et prix de base." />

      <div className="grid gap-5 md:grid-cols-2">
        <Field label="Nom du produit *">
          <input
            type="text"
            value={form.name}
            onChange={(e) => setField("name", e.target.value)}
            placeholder="Nom du produit"
            className={inputCls}
          />
        </Field>

        <Field label="Code-barres *">
          <input
            type="text"
            value={form.barcode}
            onChange={(e) => setField("barcode", e.target.value)}
            placeholder="Code-barres"
            className={inputCls}
          />
        </Field>

        <Field label="Prix de base (DH) *">
          <input
            type="number"
            step="0.01"
            value={form.basePrice}
            onChange={(e) => setField("basePrice", e.target.value)}
            placeholder="0.00"
            className={inputCls}
          />
        </Field>

        <Field label="Stock *">
          <input
            type="number"
            value={form.stock}
            onChange={(e) => setField("stock", e.target.value)}
            placeholder="0"
            className={inputCls}
          />
        </Field>

        {/* --- LE SÉLECTEUR DE MARQUE --- */}
        <Field label="Marque *">
          <select
            value={getSafeValue(form.brandId)}
            onChange={(e) => {
              const val = e.target.value ? Number(e.target.value) : null;
              setField("brandId", val && !isNaN(val) ? val : null);
              setField("modelId", null); // Reset le modèle choisi automatiquement
            }}
            className={inputCls}
          >
            <option value="">— Sélectionner une marque ({brands.length} disponibles) —</option>
            {brands.map((b: any) => {
              const bId = b.id ?? b.BrandID ?? b.brand_id;
              const bName = b.Name ?? b.name ?? b.nom ?? "Sans nom";
              return (
                <option key={bId} value={bId}>
                  {bName}
                </option>
              );
            })}
          </select>
        </Field>

        {/* --- LE SÉLECTEUR DE MODÈLE --- */}
        <Field label="Modèle *">
          <select
            value={getSafeValue(form.modelId)}
            onChange={(e) => {
              const val = e.target.value ? Number(e.target.value) : null;
              setField("modelId", val && !isNaN(val) ? val : null);
            }}
            disabled={!form.brandId || filteredModels.length === 0}
            className={inputCls}
          >
            <option value="">
              {!form.brandId
                ? "— Sélectionnez d'abord une marque —"
                : filteredModels.length === 0
                ? `Aucun modèle trouvé pour cette marque (Total global en base: ${models.length})`
                : `— Sélectionner un modèle (${filteredModels.length} trouvés) —`}
            </option>
            {filteredModels.map((m: any) => {
              const mId = m.id ?? m.ModelID ?? m.product_model_id ?? m.modelId;
              const mName = m.Name ?? m.name ?? m.nom ?? "Sans nom";
              return (
                <option key={mId} value={mId}>
                  {mName}
                </option>
              );
            })}
          </select>
        </Field>
      </div>

      <Field label="Description">
        <textarea
          rows={4}
          value={form.description}
          onChange={(e) => setField("description", e.target.value)}
          placeholder="Description détaillée..."
          className={`${inputCls} h-auto py-2`}
        />
      </Field>
    </div>
  );
}
