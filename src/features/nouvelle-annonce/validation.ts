import type { FormState } from "@/features/nouvelle-annonce/types";

export function validateStep(step: number, form: FormState): string[] {
  const errors: string[] = [];

  // Étape 1 : Informations générales & Prix
  if (step === 1) {
    if (!form.name.trim()) errors.push("Le nom du produit est requis.");
    if (!form.barcode.trim()) errors.push("Le code-barres est requis.");
    if (!form.basePrice || Number(form.basePrice) <= 0) errors.push("Le prix de base doit être supérieur à 0.");
    if (!form.stock || Number(form.stock) < 0) errors.push("Le stock doit être supérieur ou égal à 0.");
    if (!form.brandId) errors.push("Veuillez sélectionner une marque.");
    if (!form.modelId) errors.push("Veuillez sélectionner un modèle.");

    if (form.promotionType && form.promotionType !== "none") {
      if (!form.promotionValue || Number(form.promotionValue) <= 0) {
        errors.push("Veuillez saisir une valeur de promotion valide.");
      }
      if (form.promotionType === "percentage" && Number(form.promotionValue) > 100) {
        errors.push("La réduction en pourcentage ne peut pas dépasser 100%.");
      }
      if (!form.promotionEndDate) {
        errors.push("La date limite de la promotion est requise.");
      }
    }
  }

  // Étape 2 : Médias (images + vidéo)
  if (step === 2) {
    const hasImage = form.resources.some((r) => r.kind === "image");
    if (!hasImage) errors.push("Ajoutez au moins une image du produit.");
    const hasVideo = form.resources.some((r) => r.kind === "video");
    if (!hasVideo) errors.push("Une vidéo de présentation/validation est requise.");
  }

  // Étape 3 : Catégories
  if (step === 3) {
    if (form.categories.length === 0) errors.push("Sélectionnez au moins une catégorie.");
  }

  // Étape 4 : Attributs & Options
  if (step === 4) {
    if (form.attributes.length > 0) {
      const hasEmptyGroup = form.attributes.some((g) => g.options.length === 0);
      if (hasEmptyGroup) {
        errors.push("Chaque attribut sélectionné doit avoir au moins une option cochée.");
      }
    }
  }

  // Étape 5 : Matrice des combinaisons
  if (step === 5) {
    if (form.attributes.length > 0) {
      if (form.combinations.length === 0) {
        errors.push("Veuillez générer au moins une combinaison pour vos attributs.");
      } else {
        const hasDefault = form.combinations.some((c) => c.isDefault);
        if (!hasDefault) errors.push("Veuillez définir au moins une variante par défaut.");
      }
    }
  }

  // Étape 6 : Règlement & Tags
  if (step === 6) {
    if (form.allowedPayment.length === 0) errors.push("Sélectionnez au moins un mode de paiement.");
  }

  return errors;
}