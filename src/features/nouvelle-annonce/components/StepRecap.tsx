// src/features/nouvelle-annonce/components/StepRecap.tsx
import type { FormState } from "@/types/types";
import { SectionTitle } from "./shared";

export function StepRecap({ form }: { form: FormState }) {
  const imageCount = form.resources.filter((r) => r.kind === "image").length;
  const videoCount = form.resources.filter((r) => r.kind === "video").length;

  return (
    <div className="space-y-4">
      <SectionTitle title="Validation finale" subtitle="Vérifiez vos données avant de soumettre l'article." />
      <div className="border rounded-xl p-4 space-y-2 bg-slate-50 text-sm text-gray-700">
        <div><strong>Désignation :</strong> {form.name || "—"}</div>
        <div><strong>Code-barres :</strong> {form.barcode || "—"}</div>
        <div><strong>Prix de vente :</strong> {form.basePrice ? `${form.basePrice} DH` : "—"}</div>
        <div><strong>Médias :</strong> {imageCount} image(s), {videoCount} vidéo(s)</div>
        <div><strong>Options à créer :</strong> {form.attributes.length} configuration(s)</div>
        <div><strong>Tags associés ({form.tags.length}) :</strong> {form.tags.join(", ") || "Aucun"}</div>
      </div>
    </div>
  );
}
