import { useEffect, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import {
  ArrowRight,
  Flame,
  Gift,
  History,
  MapPin,
  Package,
  ShoppingBag,
  Sparkles,
  TrendingUp,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { useSearchParams } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { getMediaUrl } from "@/utils/mediaUtils";
import { productRecommendationsApi } from "@/api/productRecommendationsApi";
import { useProductRecommendations } from "@/hooks/useProductRecommendations";
import type {
  LoadMoreParams,
  PaginatedLoadMoreResponse,
  RecommendedProduct,
} from "@/types/recommendations";
import AdCard from "./AdCard";
import { getRecommendationCommercialInfo } from "./recommendationProduct";

type RecommendationKey =
  | "MostSold"
  | "MostViewed"
  | "Promotions"
  | "Trending"
  | "FromYourLastActivity"
  | "PopularInYourRegion"
  | "NewestProducts";

const RECOMMENDATION_PAGE_SIZE = 5;

interface RecommendationSectionDefinition {
  key: RecommendationKey;
  title: string;
  description: string;
  icon: LucideIcon;
  loadMore: (params: LoadMoreParams) => Promise<PaginatedLoadMoreResponse>;
}

const sections: RecommendationSectionDefinition[] = [
  {
    key: "MostSold",
    title: "Les plus vendus",
    description: "Les produits qui partent le plus vite",
    icon: ShoppingBag,
    loadMore: productRecommendationsApi.getMostSoldLoadMore,
  },
  {
    key: "MostViewed",
    title: "Les plus consultés",
    description: "Ce que la communauté regarde en ce moment",
    icon: Flame,
    loadMore: productRecommendationsApi.getMostViewedLoadMore,
  },
  {
    key: "Promotions",
    title: "Promotions du moment",
    description: "Les offres à ne pas manquer",
    icon: Gift,
    loadMore: productRecommendationsApi.getMostPromotedLoadMore,
  },
  {
    key: "Trending",
    title: "Tendances",
    description: "Les produits qui montent",
    icon: TrendingUp,
    loadMore: productRecommendationsApi.getTrendingLoadMore,
  },
  {
    key: "FromYourLastActivity",
    title: "Selon votre activité",
    description: "Une sélection basée sur vos dernières visites",
    icon: History,
    loadMore: productRecommendationsApi.getLastActivityLoadMore,
  },
  {
    key: "PopularInYourRegion",
    title: "Populaires près de chez vous",
    description: "Les produits appréciés dans votre région",
    icon: MapPin,
    loadMore: productRecommendationsApi.getPopularInRegionLoadMore,
  },
  {
    key: "NewestProducts",
    title: "Nouveautés",
    description: "Les derniers produits publiés",
    icon: Sparkles,
    loadMore: productRecommendationsApi.getNewLoadMore,
  },
];

interface RecommendationRowProps {
  definition: RecommendationSectionDefinition;
  initialItems: RecommendedProduct[];
  categoryId?: number;
}

const getRecommendationErrorMessage = (error: unknown): string => {
  if (error && typeof error === "object") {
    const responseData = (error as { response?: { data?: { message?: unknown } } }).response?.data;
    if (typeof responseData?.message === "string") return responseData.message;
  }

  if (error instanceof Error && error.message) return error.message;
  return "Le service de recommandations est temporairement indisponible.";
};

function RecommendationRow({ definition, initialItems, categoryId }: RecommendationRowProps) {
  const [items, setItems] = useState(initialItems);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState<number | null>(null);
  const loadMore = useMutation({
    mutationFn: () =>
      definition.loadMore({
        page: page + 1,
        page_size: RECOMMENDATION_PAGE_SIZE,
        category_id: categoryId,
      }),
    onSuccess: (response) => {
      setItems((current) => {
        const existingIds = new Set(current.map((item) => item.ProductID));
        return [...current, ...response.items.filter((item) => !existingIds.has(item.ProductID))];
      });
      setPage(response.page);
      setTotal(response.total);
    },
  });

  useEffect(() => {
    setItems(initialItems);
    setPage(1);
    setTotal(null);
  }, [initialItems]);

  const Icon = definition.icon;
  const canLoadMore = total === null || items.length < total;

  return (
    <section className="space-y-5">
      <div className="flex items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 text-primary">
            <Icon className="h-5 w-5" />
            <span className="text-xs font-bold uppercase tracking-[0.18em]">Sélection AdsMe</span>
          </div>
          <h2 className="mt-1 text-2xl font-heading font-extrabold tracking-tight text-foreground sm:text-3xl">
            {definition.title}
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">{definition.description}</p>
        </div>
        <ArrowRight className="hidden h-5 w-5 text-muted-foreground sm:block" />
      </div>

      <div className="grid auto-cols-[minmax(220px,260px)] grid-flow-col gap-4 overflow-x-auto pb-3 snap-x snap-mandatory">
        {items.map((product) => {
          const commercial = getRecommendationCommercialInfo(product, definition.key);
          return (
            <div key={`${definition.key}-${product.ProductID}`} className="snap-start">
              <AdCard
                id={product.ProductID}
                title={product.ProductName}
                price={product.Price}
                originalPrice={commercial.originalPrice}
                discountPercentage={commercial.discountPercentage}
                brand={product.Brand?.name ?? product.ModelName ?? undefined}
                image={getMediaUrl(product.ProductImage)}
                isTopSale={commercial.isTopSale}
                isPromoted={commercial.hasPromotion}
                isBoosted={commercial.isBoosted}
                isFollowed={product.IsLiked}
                favoritesCount={product.TotalLikes}
              />
            </div>
          );
        })}
      </div>

      {canLoadMore && (
        <div className="flex justify-center">
          <div className="text-center">
            <Button
              variant="outline"
              onClick={() => loadMore.mutate()}
              disabled={loadMore.isPending}
              className="gap-2"
            >
              {loadMore.isPending ? "Chargement..." : "Voir plus"}
              <Package className="h-4 w-4" />
            </Button>
            {loadMore.isError && (
              <p className="mt-2 text-xs text-destructive">
                {getRecommendationErrorMessage(loadMore.error)}
              </p>
            )}
          </div>
        </div>
      )}
    </section>
  );
}

const ProductRecommendations = () => {
  const [searchParams] = useSearchParams();
  const rawCategoryId = searchParams.get("category_id") ?? searchParams.get("category");
  const parsedCategoryId = rawCategoryId ? Number(rawCategoryId) : NaN;
  const categoryId =
    Number.isFinite(parsedCategoryId) && parsedCategoryId > 0 ? parsedCategoryId : undefined;
  const { data, isLoading, isError, error } = useProductRecommendations({
    limit: RECOMMENDATION_PAGE_SIZE,
    category_id: categoryId,
  });

  if (isLoading) {
    return (
      <div className="space-y-10 px-4 py-12">
        {Array.from({ length: 3 }).map((_, index) => (
          <div key={index} className="space-y-5">
            <div className="h-8 w-56 animate-pulse rounded bg-muted" />
            <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
              {Array.from({ length: 4 }).map((__, cardIndex) => (
                <div key={cardIndex} className="h-72 animate-pulse rounded-2xl bg-muted/60" />
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (isError || (data && !data.success)) {
    return (
      <section className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-destructive/20 bg-destructive/5 p-5 text-sm">
          <h2 className="font-semibold text-destructive">Recommandations indisponibles</h2>
          <p className="mt-1 text-muted-foreground">
            {data?.message ?? getRecommendationErrorMessage(error)}
          </p>
        </div>
      </section>
    );
  }

  if (!data?.success || !data.data) return null;

  const availableSections = sections.filter((section) => data.data?.[section.key]?.length);
  if (availableSections.length === 0) return null;

  return (
    <div className="space-y-14 bg-background px-4 py-12 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-7xl space-y-14">
        {availableSections.map((section) => (
          <RecommendationRow
            key={section.key}
            definition={section}
            initialItems={data.data[section.key]}
            categoryId={categoryId}
          />
        ))}
      </div>
    </div>
  );
};

export default ProductRecommendations;
