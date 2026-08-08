export interface WishlistItem {
  wishListItemId: number;
  wishListId: number;
  productId: number;
  productName: string;
  productImage: string | null;
  basePrice: number;
  brandName: string | null;
  createdAt: string;
}

export interface Wishlist {
  wishListId: number;
  name: string;
  isDefault: boolean;
  createdAt: string;
  itemCount: number;
  items?: WishlistItem[];
}

export interface CreateWishlistRequest {
  name?: string;
}

export interface AddWishlistItemRequest {
  product_id: number;
}

export interface WishlistItemCreated {
  wishListItemId: number;
}

export interface ApiSuccess<T> {
  success: boolean;
  message?: string;
  data: T;
}

export interface ApiMessageResult {
  success: boolean;
  message?: string;
}
