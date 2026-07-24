import { useAds } from "@/hooks";
import { AnnonceDto } from "@/types/ad.types";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

/**
 * Exemple de composant pour afficher les annonces
 *
 * Usage:
 * <DefaultAdsShowcase />
 */
export function DefaultAdsShowcase() {
  const { data: ads = [], isLoading } = useAds();

  if (isLoading) {
    return <div>Chargement des annonces...</div>;
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold mb-2">Nos Annonces</h1>
        <p className="text-muted-foreground">
          {ads.length} annonce{ads.length > 1 ? "s" : ""} disponible{ads.length > 1 ? "s" : ""}
        </p>
      </div>

      {/* Affichage des annonces */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {ads.map((ad) => (
          <AdCardExample key={ad.id} ad={ad} />
        ))}
      </div>
    </div>
  );
}

interface AdCardExampleProps {
  ad: AnnonceDto;
}

/**
 * Carte d'annonce simple
 */
function AdCardExample({ ad }: AdCardExampleProps) {
  return (
    <Card className="overflow-hidden hover:shadow-lg transition-shadow">
      {/* Images */}
      {ad.photosUrls.length > 0 && (
        <div className="relative w-full h-48 bg-muted overflow-hidden">
          <img
            src={ad.photosUrls[0]}
            alt={ad.titre}
            className="w-full h-full object-cover hover:scale-105 transition-transform"
          />
          {ad.photosUrls.length > 1 && (
            <div className="absolute top-2 right-2 bg-black/70 text-white px-2 py-1 rounded text-sm">
              +{ad.photosUrls.length - 1}
            </div>
          )}
        </div>
      )}

      {/* Contenu */}
      <CardHeader className="pb-3">
        <CardTitle className="line-clamp-2">{ad.titre}</CardTitle>
        <CardDescription className="line-clamp-2">{ad.description}</CardDescription>
      </CardHeader>

      <CardContent>
        <div className="flex justify-between items-center">
          <div className="text-2xl font-bold text-primary">{ad.prix} DH</div>
          <button className="px-3 py-1 bg-primary text-primary-foreground rounded hover:bg-primary/90 transition-colors">
            Voir
          </button>
        </div>
        <div className="mt-3 flex items-center justify-between text-sm text-muted-foreground">
          <span>
            {ad.numberoffavorites ?? 0} favori
            {ad.numberoffavorites && ad.numberoffavorites > 1 ? "s" : ""}
          </span>
          {ad.isFollowed && (
            <span className="rounded-full bg-primary/10 text-primary px-2 py-1">Suivi</span>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
