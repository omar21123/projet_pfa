import type { FormState } from "@/features/nouvelle-annonce/types";
import { SectionTitle } from "./shared";

export function StepRecap({ form }: { form: FormState }) {
  const imageCount = form.resources.filter((r) => r.kind === "image").length;
  const videoCount = form.resources.filter((r) => r.kind === "video").length;

  return (
    <div className="space-y-4">
      <SectionTitle title="Validation finale" subtitle="Vérifiez les informations avant soumission." />
      
      <div className="border rounded-xl p-5 space-y-3 bg-slate-50 text-sm text-slate-700">
        <div><strong>Désignation :</strong> {form.name || "—"}</div>
        <div><strong>Code-barres :</strong> {form.barcode || "—"}</div>
        <div><strong>Prix de base :</strong> {form.basePrice ? `${form.basePrice} DH` : "—"}</div>
        
        {form.promotionType !== "none" && (
          <div className="text-emerald-700 font-semibold">
            <strong>Promotion :</strong> {form.promotionValue}{" "}
            {form.promotionType === "percentage" ? "%" : "DH"} jusqu'au {form.promotionEndDate}
          </div>
        )}

        <div><strong>Médias :</strong> {imageCount} image(s), {videoCount} vidéo(s)</div>
        <div><strong>Nombre de variantes générées :</strong> {form.combinations.length} variante(s)</div>
        <div><strong>Tags associés ({form.tags.length}) :</strong> {form.tags.join(", ") || "Aucun"}</div>
      </div>
    </div>
  );
}