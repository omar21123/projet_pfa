// src/api/ads.api.ts
import { apiClient } from "./client"; // Ton client Axios configuré

// 1. Définition des fonctions d'API existantes ou mockées
const baseApi = {
  /**
   * Récupère la liste des villes pour la recherche (Mock)
   */
  getVilles: async (categoryId = 0, subCategoryId = 0) => {
    return [
      { id: "1", name: "Paris (75)" },
      { id: "2", name: "Lyon (69)" },
      { id: "3", name: "Marseille (13)" },
      { id: "4", name: "Bordeaux (33)" },
      { id: "5", name: "Lille (59)" }
    ];
  },

  // Tu pourras rajouter tes vraies fonctions ici au fur et à mesure :
  /*
  getLatestAds: async () => {
    const response = await apiClient.get('/api/ads/latest');
    return response.data;
  }
  */
};

// 2. 🛡️ PROXY ANTI-CRASH : Intercepte les appels aux fonctions effacées ou non encore créées
export const adsApi: any = new Proxy(baseApi, {
  get: (target: any, prop: string) => {
    // Si la fonction demandée existe dans baseApi, on l'utilise
    if (prop in target) {
      return target[prop];
    }

    // Si la fonction n'existe pas, on simule un retour propre pour éviter l'écran blanc
    console.warn(
      `[adsApi Warning] La méthode "${prop}" a été appelée par un composant mais n'est pas encore implémentée. Retour d'un tableau vide pour éviter un écran blanc.`
    );
    
    return async () => {
      // Renvoie un tableau vide par défaut pour satisfaire les boucles (.map) des composants
      return [];
    };
  }
});

export default adsApi;