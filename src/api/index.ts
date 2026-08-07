// APIs Principales
export { apiClient } from "@/api/client";
export { authApi } from "@/api/auth.api";
export { usersApi } from "@/api/users.api";

// APIs Annonces & Produits
//export { adsApi } from "@/api/ads.api"; //  Décommenté (si le fichier existe)
export { annonceApi, buildAnnonceFormData } from "@/api/annonce.api";
export { fetchProductInfo, productInfoApi } from "@/api/productInfoApi";

// APIs Interactions (Messages & Favoris & Panier)
export { conversationApi } from "@/api/conversation.api";
export { messageApi } from "@/api/message.api";
export {
  addFavorite,
  favoritesApi,
  getFavorites,
  removeFavorite,
} from "@/features/favorites/api/favorites.api";
export {
  addWishlistItem,
  createWishlist,
  deleteWishlist,
  getWishlists,
  removeWishlistItem,
  wishlistApi,
} from "@/api/wishlist.api";
export {
  addCartItem,
  cartApi,
  getCart,
  removeCartItem,
} from "@/features/cart/cart.api";