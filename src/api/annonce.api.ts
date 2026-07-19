import { apiClient } from "@/api/client";

export interface AnnonceAttributeInput {
  idAttribut: number;
  valeur: string;
}

export interface CreateAnnonceRequest {
  titre: string;
  description: string;
  prix: number;
  idCategorie: number;
  idSousCategorie: number;
  localisationVille?: string;
  etat: string;
  statut: "draft" | "published";
  Images: File[]; // Doit absolument être un tableau de fichiers natifs
  Attributs: AnnonceAttributeInput[];
  slug?: string;
}

export interface CreateAnnonceResponse {
  id?: number | string;
  [key: string]: unknown;
}

export const buildAnnonceFormData = (payload: CreateAnnonceRequest) => {
  const formData = new FormData();

  // 1. Textes et Nombres (avec sécurité pour le Prix)
  formData.append("Titre", payload.titre || "");
  formData.append("Description", payload.description || "");
  formData.append("Prix", String(payload.prix).replace(",", "."));
  formData.append("IdCategorie", String(payload.idCategorie));
  formData.append("IdSousCategorie", String(payload.idSousCategorie));
  formData.append("LocalisationVille", payload.localisationVille ? payload.localisationVille : "");
  formData.append("Etat", payload.etat ? payload.etat.toLowerCase() : "");
  formData.append("Statut", payload.statut ? payload.statut.toLowerCase() : "draft");

  // 2. Sécurisation et ajout des Attributs
  if (payload.Attributs && Array.isArray(payload.Attributs)) {
    payload.Attributs.forEach((attr, index) => {
      formData.append(`Attributs[${index}].IdAttribut`, String(attr.idAttribut));
      formData.append(`Attributs[${index}].Valeur`, attr.valeur);
    });
  }

  // 3. Sécurisation et ajout des Images
  if (payload.Images && Array.isArray(payload.Images)) {
    payload.Images.forEach((image) => {
      // "Images" correspond exactement au nom de la propriété List<IFormFile> Images dans ton DTO C#
      formData.append("Images", image);
    });
  }

  // 🔍 Debug console pour vérifier avant l'envoi
  console.log("=== FormData Debug ===");
  for (const [key, value] of formData.entries()) {
    console.log(`${key}:`, value);
  }

  return formData;
};

export const annonceApi = {
  create: async (payload: CreateAnnonceRequest): Promise<CreateAnnonceResponse> => {
    const formData = buildAnnonceFormData(payload);

    // Appel Axios avec le header explicite pour éviter l'erreur 415
    const { data } = await apiClient.post<CreateAnnonceResponse>("api/Annonce", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });

    return data;
  },
};
