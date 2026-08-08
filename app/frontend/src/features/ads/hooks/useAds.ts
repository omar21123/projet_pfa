// src/features/ads/hooks/useAds.ts

export const useAds = (params?: any, options?: any) => {
  return {
    data: [
      {
        id: 1,
        titre: "Produit de démonstration 1",
        prix: 250,
        ville: "Casablanca",
        photosUrls: ["https://via.placeholder.com/300"],
        datepublication: "2026-01-15T10:00:00Z",
        idutilisateur: 1,
        numberoffavorites: 4,
        isFollowed: false,
        categorie: "Divers"
      },
      {
        id: 2,
        titre: "Produit de démonstration 2",
        prix: 1200,
        ville: "Rabat",
        photosUrls: ["https://via.placeholder.com/300"],
        datepublication: "2026-02-01T12:00:00Z",
        idutilisateur: 2,
        numberoffavorites: 10,
        isFollowed: true,
        categorie: "High-Tech"
      }
    ],
    isLoading: false,
    isError: false,
    error: null,
  };
};