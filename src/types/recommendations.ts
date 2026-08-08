export interface ProductBrand {
  name: string;
  logo: string | null;
}

export interface RecommendedProduct {
  ProductID: number;
  ProductName: string;
  ProductImage: string | null;
  Description: string | null;
  Price: number;
  Brand: ProductBrand | null;
  ModelName: string | null;
  TotalWishlist: number;
  TotalLikes: number;
  TotalOrders: number;
  IsLiked: boolean;
  IsWishedList: boolean;
}

export interface GetRecommendationsParams {
  limit?: number;
  category_id?: number;
}

export interface ProductRecommendationsData {
  MostSold: RecommendedProduct[];
  MostViewed: RecommendedProduct[];
  Promotions: RecommendedProduct[];
  Trending: RecommendedProduct[];
  FromYourLastActivity: RecommendedProduct[];
  PopularInYourRegion: RecommendedProduct[];
  NewestProducts: RecommendedProduct[];
}

export interface ProductRecommendationsResponse {
  success: boolean;
  data?: ProductRecommendationsData;
  message?: string;
}

export interface LoadMoreParams {
  page?: number;
  page_size?: number;
  category_id?: number;
}

export interface NewLoadMoreParams extends LoadMoreParams {
  days_back?: number;
}

export interface PaginatedLoadMoreResponse<T = RecommendedProduct> {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
}

export interface RecommendationErrorResponse {
  success: boolean;
  message: string;
}
