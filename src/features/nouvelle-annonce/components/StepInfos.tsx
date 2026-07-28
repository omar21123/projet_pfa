import { useQuery } from "@tanstack/react-query";
import axiosInstance from "@/api/axiosInstances";
import type { FormState } from "@/features/nouvelle-annonce/types";
import { Field, SectionTitle, inputCls } from "./shared";

export function StepInfos({ form, setField }: { form: FormState; setField: any }) {
  const { data: brandsRes } = useQuery({
    queryKey: ["brands-list"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/brands");
      return res.data;
    },
  });

  const { data: modelsRes } = useQuery({
    queryKey: ["models-list"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/models");
      return res.data;
    },
  });

  const extractArray = (res: any) => {
    if (!res) return [];
    if (Array.isArray(res)) return res;
    if (Array.isArray(res.data)) return res.data;
    if (res.data && Array.isArray(res.data.data)) return res.data.data;
    return [];
  };

  const brands = extractArray(brandsRes);
  const models = extractArray(modelsRes);

  const getSafeValue = (val: any) => {
    if (val === null || val === undefined || Number.isNaN(val)) return "";
    return val;
  };

  const selectedBrand = brands.find((b: any) => {
    const bId = b.id ?? b.BrandID ?? b.brand_id;
    return Number(bId) === Number(form.brandId);
  });

  const filteredModels = models.filter((m: any) => {
    if (!form.brandId) return false;
    const directBrandId = m.brand_id ?? m.BrandID ?? m.brandId ?? m.brand?.id;
    if (directBrandId !== undefined && directBrandId !== null) {
      return Number(directBrandId) === Number(form.brandId);
    }
    if (!selectedBrand) return false;
    const brandName = selectedBrand.Name ?? selectedBrand.name ?? "";
    const modelBrandName = m.BrandName ?? m.brandName ?? "";
    return modelBrandName.trim().toLowerCase() === brandName.trim().toLowerCase();
  });

  return (
    <div className="space-y-6">
      <SectionTitle
        title="Informations générales"
        subtitle="Nom, identifiants, marque, prix et stock de base."
      />

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
            placeholder="Ex: 8806090123456"
            className={inputCls}
          />
        </Field>

        <Field label="Marque *">
          <select
            value={getSafeValue(form.brandId)}
            onChange={(e) => {
              const val = e.target.value ? Number(e.target.value) : null;
              setField("brandId", val);
              setField("modelId", null);
            }}
            className={inputCls}
          >
            <option value="">— Sélectionner une marque —</option>
            {brands.map((b: any) => {
              const bId = b.id ?? b.BrandID ?? b.brand_id;
              const bName = b.Name ?? b.name ?? "Sans nom";
              return (
                <option key={bId} value={bId}>
                  {bName}
                </option>
              );
            })}
          </select>
        </Field>

        <Field label="Modèle *">
          <select
            value={getSafeValue(form.modelId)}
            onChange={(e) => {
              const val = e.target.value ? Number(e.target.value) : null;
              setField("modelId", val);
            }}
            disabled={!form.brandId || filteredModels.length === 0}
            className={inputCls}
          >
            <option value="">
              {!form.brandId
                ? "— Sélectionnez d'abord une marque —"
                : filteredModels.length === 0
                  ? "Aucun modèle pour cette marque"
                  : "— Sélectionner un modèle —"}
            </option>
            {filteredModels.map((m: any) => {
              const mId = m.id ?? m.ModelID ?? m.modelId;
              const mName = m.Name ?? m.name ?? "Sans nom";
              return (
                <option key={mId} value={mId}>
                  {mName}
                </option>
              );
            })}
          </select>
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

        <Field label="Stock initial *">
          <input
            type="number"
            value={form.stock}
            onChange={(e) => setField("stock", e.target.value)}
            placeholder="0"
            className={inputCls}
          />
        </Field>
      </div>

      <Field label="Description du produit">
        <textarea
          rows={3}
          value={form.description}
          onChange={(e) => setField("description", e.target.value)}
          placeholder="Rédigez une description claire..."
          className={`${inputCls} h-auto py-2.5`}
        />
      </Field>
    </div>
  );
}