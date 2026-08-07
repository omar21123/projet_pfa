import { MapPin, Clock, Store, CheckCircle2, ArrowRight, Megaphone, Tag } from "lucide-react";
import { Link, useSearchParams } from "react-router-dom";
import { useSearchProducts } from "@/components/search/useSearchProducts";
import { getMediaUrl } from "@/utils/mediaUtils";

interface FeaturedAd {
  id: string;
  title: string;
  price: number;
  oldPrice?: number;
  location: string;
  time: string;
  category: string;
  image: string;
  store: string;
  isSponsored: boolean;
  isVerified: boolean;
}

// 6 Annonces de test
const MOCK_ADS: FeaturedAd[] = [
  {
    id: "1",
    title: "iPhone 15 Pro 256Go — Titane Naturel",
    price: 9800,
    oldPrice: 11500,
    location: "Casablanca",
    time: "Il y a 2 h",
    category: "ÉLECTRONIQUE",
    image: "https://images.unsplash.com/photo-1696446701796-da61225697cc?q=80&w=500&auto=format&fit=crop",
    store: "Sonora Pro",
    isSponsored: true,
    isVerified: true
  },
  {
    id: "2",
    title: "Canapé d'angle en velours 4 places",
    price: 4500,
    location: "Rabat",
    time: "Il y a 5 h",
    category: "MAISON",
    image: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?q=80&w=500&auto=format&fit=crop",
    store: "Maison Terra",
    isSponsored: true,
    isVerified: true
  },
  {
    id: "3",
    title: "MacBook Air M2 8/512 Go",
    price: 11200,
    oldPrice: 12500,
    location: "Tanger",
    time: "Hier",
    category: "INFORMATIQUE",
    image: "https://images.unsplash.com/photo-1517336712461-d01f9424ad91?q=80&w=500&auto=format&fit=crop",
    store: "PixelHub",
    isSponsored: false,
    isVerified: true
  },
  {
    id: "4",
    title: "VTT Carbone 29 pouces Shimano",
    price: 7200,
    location: "Marrakech",
    time: "Il y a 1 j",
    category: "SPORT",
    image: "https://images.unsplash.com/photo-1576435728678-68d0fbf94e91?q=80&w=500&auto=format&fit=crop",
    store: "Velo Plus",
    isSponsored: true,
    isVerified: false
  },
  {
    id: "5",
    title: "Table à manger Chêne Massif",
    price: 3200,
    oldPrice: 3900,
    location: "Agadir",
    time: "Il y a 2 j",
    category: "MAISON",
    image: "https://images.unsplash.com/photo-1530018607912-eff2df114f11?q=80&w=500&auto=format&fit=crop",
    store: "Deco Nord",
    isSponsored: false,
    isVerified: true
  },
  {
    id: "6",
    title: "Sony A7 III + Objectif 28-70mm",
    price: 13900,
    location: "Fès",
    time: "Il y a 3 j",
    category: "PHOTO",
    image: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=500&auto=format&fit=crop",
    store: "Optique Pro",
    isSponsored: true,
    isVerified: true
  }
];

const FeaturedAdsGrid = () => {
  const [searchParams] = useSearchParams();
  const searchTerm = searchParams.get("q")?.trim() ?? "";
  const { data: searchResults, isLoading } = useSearchProducts(searchTerm);

  const ads: FeaturedAd[] = searchTerm
    ? (searchResults?.products ?? []).slice(0, 6).map((product) => ({
        id: String(product.ProductID),
        title: product.ProductName,
        price: product.Price,
        location: "Non renseignée",
        time: "Résultat de recherche",
        category: product.Brand?.name?.toUpperCase() ?? "PRODUIT",
        image: getMediaUrl(product.ProductImage),
        store: product.Brand?.name ?? "Vendeur",
        isSponsored: false,
        isVerified: false,
      }))
    : MOCK_ADS;

  return (
    <section className="py-12 px-4 bg-background">
      <div className="max-w-7xl mx-auto">
        
        {/* Header */}
        <div className="flex items-end justify-between mb-10">
          <div>
            <h2 className="text-3xl font-heading font-extrabold text-[var(--ink)] tracking-tight">
              Annonces à la une
            </h2>
            <div className="h-1 w-20 bg-[var(--teal)] mt-2 rounded-full" />
          </div>
          <Link to="/annonces" className="nav-link flex items-center gap-2 font-bold text-xs uppercase tracking-widest text-[var(--teal)]">
            Toutes les annonces <ArrowRight className="h-4 w-4" />
          </Link>
        </div>

        {/* Grille de 6 annonces (3 par ligne sur desktop) */}
        {searchTerm && isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, index) => (
              <div key={index} className="h-[210px] rounded-2xl bg-muted/50 animate-pulse" />
            ))}
          </div>
        ) : searchTerm && ads.length === 0 ? (
          <p className="py-10 text-center text-muted-foreground">
            Aucun produit trouvé pour « {searchTerm} ».
          </p>
        ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {ads.map((ad) => {
            const discount = ad.oldPrice ? Math.round(((ad.oldPrice - ad.price) / ad.oldPrice) * 100) : null;

            return (
              <Link 
                to={`/ad/${ad.id}`} 
                key={ad.id}
                className="lift group flex h-[210px] bg-[var(--surface)] border border-[var(--hairline)] rounded-2xl overflow-hidden"
              >
                {/* Image Section */}
                <div className="relative w-[40%] h-full overflow-hidden bg-muted">
                  <img 
                    src={ad.image} 
                    alt={ad.title}
                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                  />
                  
                  {/* Badge SPONSORISÉ (Annonce payante) */}
                  {ad.isSponsored && (
                    <div className="absolute top-2 right-2 bg-black/70 backdrop-blur-md text-white text-[8px] font-bold px-2 py-1 rounded-full flex items-center gap-1 border border-white/10">
                      <Megaphone className="h-2.5 w-2.5 text-yellow-400" /> Sponsorisé
                    </div>
                  )}

                  {/* Badge PROMO */}
                  {discount && (
                    <div className="absolute bottom-2 left-2 bg-emerald-600 text-white text-[10px] font-bold px-2 py-0.5 rounded shadow-lg flex items-center gap-1">
                      <Tag className="h-3 w-3" /> -{discount}%
                    </div>
                  )}
                </div>

                {/* Info Section */}
                <div className="w-[60%] p-4 flex flex-col justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-[var(--teal)] tracking-[0.15em] uppercase block mb-1">
                      {ad.category}
                    </span>
                    
                    <h3 className="text-[14px] font-bold text-[var(--ink)] line-clamp-2 leading-tight mb-2 group-hover:text-[var(--teal)] transition-colors">
                      {ad.title}
                    </h3>

                    <div className="flex flex-col">
                      <span className="text-lg font-black text-[var(--ink)]">
                        {ad.price.toLocaleString()} MAD
                      </span>
                      {ad.oldPrice && (
                        <span className="text-[11px] text-muted-foreground line-through">
                          {ad.oldPrice.toLocaleString()} MAD
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2 pt-3 border-t border-[var(--hairline)]">
                    <div className="flex items-center gap-3 text-[10px] text-muted-foreground">
                      <span className="flex items-center gap-1"><MapPin className="h-3 w-3" /> {ad.location}</span>
                      <span className="flex items-center gap-1"><Clock className="h-3 w-3" /> {ad.time}</span>
                    </div>
                    
                    <div className="flex items-center gap-1.5 text-[11px] font-bold text-[var(--ink)]">
                      <div className="w-5 h-5 rounded-full bg-[var(--cream)] flex items-center justify-center border border-[var(--hairline)] shadow-sm">
                         <Store className="h-3 w-3 text-[var(--teal)]" />
                      </div>
                      <span className="truncate max-w-[90px]">{ad.store}</span>
                      {ad.isVerified && <CheckCircle2 className="h-3 w-3 text-blue-500" />}
                    </div>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
        )}
      </div>
    </section>
  );
};

export default FeaturedAdsGrid;
