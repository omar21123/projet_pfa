export interface AddCartItemRequest {
  productID: number;
  FromSearch?: boolean;
  SearchTerm?: string;
  CompositionID?: number;
  UnitPrice?: number;
}

export interface RemoveCartItemRequest {
  productID: number;
  CompositionID?: number;
}

export interface CartMutationResponse {
  success: boolean;
  message: string;
}

export interface CartItemRaw {
  ProductID?: number;
  productId?: number;
  id?: number;
  CompositionID?: number;
  CompositionId?: number;
  CombinationID?: number;
  CombinationId?: number;
  combinationId?: number;
  compositionId?: number;
  ProductName?: string;
  productName?: string;
  title?: string;
  UnitPrice?: number;
  unitPrice?: number;
  price?: number;
  ImagePath?: string;
  imagePath?: string;
  image?: string;
  BrandName?: string;
  brandName?: string;
  seller?: string;
  Quantity?: number;
  quantity?: number;
}

export interface CartResponse {
  success: boolean;
  data: CartItemRaw[];
}
