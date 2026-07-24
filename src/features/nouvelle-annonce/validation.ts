import type { FormState } from "@/types/types";

export function validateStep(step: number, form: FormState): string[] {
  const errs: string[] = [];

  if (step === 1) {
    if (!form.name.trim()) errs.push("Le nom du produit est obligatoire.");
    if (!form.barcode.trim()) errs.push("Le code-barres est obligatoire.");
    if (!form.basePrice || Number(form.basePrice) < 0) errs.push("Le prix doit être valide.");
    if (form.stock === "" || Number(form.stock) < 0) errs.push("Le stock initial est requis.");
    if (!form.brandId) errs.push("La sélection de la marque est requise.");
    if (!form.modelId) errs.push("La sélection du modèle est requise.");
  }

  if (step === 2) {
    // 🎯 Règle d'obligation : 1 image + 1 vidéo de validation
    const hasImage = form.resources.some((r) => r.kind === "image");
    const hasVideo = form.resources.some((r) => r.kind === "video");

    if (!hasImage) errs.push("Au moins une image du produit est obligatoire.");
    if (!hasVideo) errs.push("Une vidéo de validation du produit est obligatoire.");
  }

  if (step === 3 && form.categories.length === 0) {
    errs.push("Veuillez choisir au moins une catégorie.");
  }

  if (step === 5 && form.allowedPayment.length === 0) {
    errs.push("Sélectionnez au moins un moyen de paiement.");
  }

  return errs;
}