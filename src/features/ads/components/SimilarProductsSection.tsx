import { useMemo } from "react";
import { useQueries } from "@tanstack/react-query";
import { Layers3, Sparkles, Tags } from "lucide-react";
import { fetchProductInfo } from "@/api/productInfoApi";
import { getMediaUrl } from "@/utils/mediaUtils";
import { useSimilarProducts } from "@/features/ads/hooks/useSimilarProducts";
import type { ProductInfoResponse } from "@/types/product-info";
import type { SimilarProduct } from "@/types/similar-products";
import AdCard from "./AdCard";

interface SimilarProductsSectionProps {
  productId: number;
}

const groups = [
  {
    key: "SimilarProducts" as const,
    title: "Produits similaires",
    description: "Des produits du même type",
    icon: Sparkles,
  },
  {
    key: "SimilarInBrandsOrModels" as const,
    title: "Même marque ou modèle",
    description: "Découvrez d’autres produits de cet univers",
    icon: Tags,
  },
  {
    key: "SimilarInCategories" as const,
    title: "Dans la même catégorie",
    description: "Les produits populaires dans cette catégorie",
    icon: Layers3,
  },
];

const uniqueProducts = (products: SimilarProduct[], displayedIds: Set<number>) => {
  const unique: SimilarProduct[] = [];

  products.forEach((product) => {
    if (product.ProductID === 0 || displayedIds.has(product.ProductID)) return;
    displayedIds.add(product.ProductID);
    unique.push(product);
  });

  return unique;
};

const getProductInfoImage = (response?: ProductInfoResponse): string | null => {
  const rawImages = response?.data?.DefaultProductImage;
  if (!rawImages) return null;

  const images = Array.isArray(rawImages) ? rawImages : [rawImages];
  for (const image of images) {
    if (typeof image === "string" && image.trim()) return image;
    if (typeof image === "object" && image !== null) {
      const path = image.url || image.path;
      if (path) return path;
    }
  }

  return null;
};

const SimilarProductsSection = ({ productId }: SimilarProductsSectionProps) => {
  const { data, isLoading } = useSimilarProducts(productId);

  const visibleGroups = useMemo(() => {
    if (!data?.success || !data.data) return [];

    const displayedIds = new Set<number>([productId]);
    return groups
      .map((group) => ({
        ...group,
        products: uniqueProducts(data.data[group.key] ?? [], displayedIds),
      }))
      .filter((group) => group.products.length > 0);
  }, [data, productId]);

  const similarProducts = useMemo(
    () => visibleGroups.flatMap((group) => group.products),
    [visibleGroups],
  );

  const productInfoQueries = useQueries({
    queries: similarProducts.map((product) => ({
      queryKey: ["similar-product-info", product.ProductID],
      queryFn: () => fetchProductInfo({ ProductID: product.ProductID, FromSearch: false }),
      enabled: !product.ProductImage,
      staleTime: 1000 * 60 * 10,
    })),
  });

  const imagesByProductId = useMemo(
    () =>
      new Map(
        similarProducts.map((product, index) => [
          product.ProductID,
          getProductInfoImage(productInfoQueries[index]?.data),
        ]),
      ),
    [productInfoQueries, similarProducts],
  );

  if (isLoading) {
    return (
      <section className="container max-w-5xl space-y-5 py-10">
        <div className="h-8 w-64 animate-pulse rounded bg-muted" />
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          {Array.from({ length: 4 }).map((_, index) => (
            <div key={index} className="h-72 animate-pulse rounded-2xl bg-muted/60" />
          ))}
        </div>
      </section>
    );
  }

  if (visibleGroups.length === 0) return null;

  return (
    <section className="border-t border-border bg-muted/20 px-4 py-10 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-5xl space-y-10">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-primary">
            Pour continuer votre découverte
          </p>
          <h2 className="mt-1 text-2xl font-heading font-extrabold tracking-tight sm:text-3xl">
            Vous pourriez aussi aimer
          </h2>
        </div>

        {visibleGroups.map((group) => {
          const Icon = group.icon;
          return (
            <div key={group.key} className="space-y-4">
              <div className="flex items-center gap-2">
                <Icon className="h-5 w-5 text-primary" />
                <div>
                  <h3 className="font-heading text-xl font-bold">{group.title}</h3>
                  <p className="text-sm text-muted-foreground">{group.description}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                {group.products.map((product) => (
                  <AdCard
                    key={`${group.key}-${product.ProductID}`}
                    id={product.ProductID}
                    title={product.ProductName}
                    price={product.BasePrice}
                    brand={product.BrandName ?? product.ModelName ?? undefined}
                    image={getMediaUrl(
                      product.ProductImage ?? imagesByProductId.get(product.ProductID),
                    )}
                  />
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
};

export default SimilarProductsSection;
