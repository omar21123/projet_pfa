import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import {
  ArrowLeft,
  MapPin,
  Calendar,
  User,
  MessageCircle,
  CreditCard,
  CheckCircle2,
  Package,
  Tag,
  ShieldCheck,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { motion } from "framer-motion";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import StarRating from "@/components/StarRating";
import ShareButtons from "@/components/ShareButtons";
import { conversationApi } from "@/api";
import { useAuth } from "@/contexts";
import { useToast } from "@/hooks/use-toast";
import { useLanguage } from "@/contexts/LanguageContext";
import { getDefaultAds } from "@/data";
import { AvisSection } from "@/features/avis";
import { useProductInfo } from "@/features/ads/hooks/useProductInfo";
import { FavoriteButton } from "@/features/favorites";
import { ShoppingCartButton } from "@/features/cart/ShoppingCartButton";
import SimilarProductsSection from "@/features/ads/components/SimilarProductsSection";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { Ad as LocalAd } from "@/types/ad.types";
import type { ProductCombination, ProductInfoData } from "@/types/product-info";

const CITIES = ["Casablanca", "Rabat", "Marrakech", "Fès", "Tanger", "Agadir"];
const SELLERS = [
  { name: "Vendeur Officiel", joined: "Membre vérifié", rating: 4.8, reviewCount: 35 },
];

const formatDate = (value?: string) => {
  if (!value) return "Non renseignée";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Non renseignée";
  return date.toLocaleDateString("fr-FR", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
};

type Seller = {
  id?: number;
  name: string;
  joined: string;
  rating: number;
  reviewCount: number;
  email?: string;
  telephone?: string;
  role?: string;
  isVerified?: boolean;
  estActif?: boolean;
  dateInscription?: string;
  avatar?: string;
};

type DetailAd = {
  id: string;
  title: string;
  description: string;
  price: number;
  images: string[];
  city: string;
  date: string;
  seller: Seller;
};

const buildSeller = (profile: unknown, fallback: Seller): Seller => {
  if (!profile || typeof profile !== "object") return fallback;
  const p = profile as Record<string, unknown>;
  const fullName = [p["prenom"], p["nom"]].filter(Boolean).join(" ").trim();
  const profileId = p["id"] ?? p["VendorProfileID"];
  const profileDate = p["dateInscription"] ?? p["MemberSince"];
  const hasVerificationFields =
    "IdentityVerified" in p || "BusinessVerified" in p || "IsApproved" in p;
  const isVerified =
    typeof p["isVerified"] === "boolean"
      ? p["isVerified"]
      : hasVerificationFields
        ? Boolean(p["IdentityVerified"] || p["BusinessVerified"])
        : true;

  return {
    id:
      profileId !== undefined && Number.isFinite(Number(profileId)) ? Number(profileId) : undefined,
    name: fullName || (p["name"] as string) || (p["StoreName"] as string) || fallback.name,
    joined: profileDate
      ? `Membre depuis ${new Date(String(profileDate)).getFullYear()}`
      : fallback.joined,
    rating: (p["rating"] as number) ?? fallback.rating,
    reviewCount: (p["reviewCount"] as number) ?? fallback.reviewCount,
    email: (p["email"] as string) ?? undefined,
    telephone: (p["telephone"] as string) ?? undefined,
    role: (p["role"] as string) ?? undefined,
    isVerified,
    estActif: (p["estActif"] as boolean) ?? true,
    dateInscription: (profileDate as string) ?? undefined,
    avatar: (p["avatar"] as string) ?? (p["LogoURL"] as string) ?? undefined,
  };
};

const normalizeLocalAd = (ad: LocalAd, index: number): DetailAd => ({
  id: ad.id,
  title: ad.title,
  description: ad.description,
  price: ad.price,
  images: ad.images.length > 0 ? ad.images : ["/placeholder-ad.png"],
  city: CITIES[index % CITIES.length],
  date: formatDate(ad.createdAt),
  seller: SELLERS[0],
});

const normalizeToken = (value: string): string =>
  value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "")
    .trim();

const optionMatchesSku = (optionValue: string, sku: string): boolean => {
  const token = normalizeToken(optionValue);
  if (!token) return false;

  const skuTokens = sku
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);

  return skuTokens.some(
    (skuToken) => skuToken === token || (token.length >= 3 && skuToken === token.slice(0, 3)),
  );
};

const getProductImagePaths = (value: ProductInfoData["DefaultProductImage"]): string[] => {
  if (!value) return [];

  const values = Array.isArray(value) ? value : [value];
  return values.flatMap((item) => {
    if (typeof item === "string") return [item];
    const path = item.url || item.path;
    return path ? [path] : [];
  });
};

const AdDetails = () => {
  const { t } = useLanguage();
  const { id } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();

  const productIdNum = Number(id);
  const isValidId = !Number.isNaN(productIdNum) && productIdNum > 0;
  const searchTerm = searchParams.get("searchTerm")?.trim() ?? "";
  const fromSearch = searchParams.get("fromSearch") === "true" && searchTerm.length > 0;

  // Récupération via useProductInfo
  const {
    data: productInfoResponse,
    isLoading: isLoadingInfo,
    isError,
  } = useProductInfo(
    {
      ProductID: productIdNum,
      FromSearch: fromSearch,
      SearchTerm: fromSearch ? searchTerm : undefined,
    },
    { enabled: isValidId },
  );

  const [currentImage, setCurrentImage] = useState(0);
  const [sellerDialogOpen, setSellerDialogOpen] = useState(false);
  const [isStartingConversation, setIsStartingConversation] = useState(false);
  const [selectedOptions, setSelectedOptions] = useState<Record<number, number>>({});

  // Extraction sécurisée des données produit
  const pData = useMemo<ProductInfoData | undefined>(() => {
    if (!productInfoResponse) return undefined;
    if ("data" in productInfoResponse && productInfoResponse.data) {
      return productInfoResponse.data;
    }
    return productInfoResponse as unknown as ProductInfoData;
  }, [productInfoResponse]);

  // Initialisation des déclinaisons et choix par défaut
  useEffect(() => {
    if (!pData) return;

    const initialOpts: Record<number, number> = {};

    // 1. Chercher d'abord la combinaison avec IsDefault: true
    const defaultCombo = pData.ProductOptionsCombiniason?.find((c) => c.IsDefault);

    if (defaultCombo && defaultCombo.Configs) {
      const configsArr = Array.isArray(defaultCombo.Configs)
        ? defaultCombo.Configs
        : [defaultCombo.Configs];

      configsArr.forEach((cfg) => {
        initialOpts[cfg.ConfigID] = cfg.OptionID;
      });
    }

    // 2. Compléter les options manquantes via ProductDetails
    if (pData.ProductDetails) {
      pData.ProductDetails.forEach((cfg) => {
        if (!initialOpts[cfg.ConfigID] && cfg.Options && cfg.Options.length > 0) {
          const defaultOpt = cfg.Options.find((o) => o.isDefault) || cfg.Options[0];
          if (defaultOpt) {
            initialOpts[cfg.ConfigID] = defaultOpt.OptionID;
          }
        }
      });
    }

    setSelectedOptions(initialOpts);
  }, [pData]);

  // Détermination de la combinaison active
  const matchedCombination = useMemo<ProductCombination | null>(() => {
    if (!pData?.ProductOptionsCombiniason || Object.keys(selectedOptions).length === 0) {
      return null;
    }

    const details = pData.ProductDetails ?? [];
    const scoredCombinations = pData.ProductOptionsCombiniason.flatMap((combo) => {
      if (!combo.Configs) return [];

      const configsArray = Array.isArray(combo.Configs) ? combo.Configs : [combo.Configs];
      const explicitConfigIds = new Set(configsArray.map((config) => config.ConfigID));
      const explicitMatches = configsArray.every(
        (config) => selectedOptions[config.ConfigID] === config.OptionID,
      );

      if (!explicitMatches) return [];

      let score = configsArray.length * 100;
      details.forEach((detail) => {
        const selectedOptionId = selectedOptions[detail.ConfigID];
        if (selectedOptionId === undefined || explicitConfigIds.has(detail.ConfigID)) return;

        const selectedOption = detail.Options?.find(
          (option) => option.OptionID === selectedOptionId,
        );
        if (
          selectedOption &&
          (optionMatchesSku(selectedOption.OptionValue, combo.SKU) ||
            optionMatchesSku(selectedOption.OptionLabel, combo.SKU))
        ) {
          score += 10;
        }
      });

      return [
        { combo, score, isComplete: explicitConfigIds.size >= Object.keys(selectedOptions).length },
      ];
    });

    const completeMatches = scoredCombinations.filter((item) => item.isComplete);
    const candidates = completeMatches.length > 0 ? completeMatches : scoredCombinations;
    return (
      candidates.sort(
        (left, right) =>
          right.score - left.score || Number(right.combo.IsDefault) - Number(left.combo.IsDefault),
      )[0]?.combo ?? null
    );
  }, [pData?.ProductDetails, pData?.ProductOptionsCombiniason, selectedOptions]);

  // Valeurs dynamiques pour le prix et le stock
  const activePrice = matchedCombination
    ? matchedCombination.CombinationPrice
    : (pData?.BasePrice ?? 0);

  const comparePrice = matchedCombination?.CompareAtPrice ?? null;

  const activeStock = matchedCombination
    ? matchedCombination.CombinationStock
    : (pData?.Stock ?? 0);

  const activeCombinationImage = matchedCombination?.CombinationImage
    ? getMediaUrl(matchedCombination.CombinationImage)
    : null;

  // Normalisation des données pour l'affichage
  const selectedAd = useMemo<DetailAd | null>(() => {
    if (!id) return null;

    if (pData) {
      const images: string[] = [];

      images.push(...getProductImagePaths(pData.DefaultProductImage));

      if (pData.ProductOptionsCombiniason) {
        pData.ProductOptionsCombiniason.forEach((c) => {
          if (c.CombinationImage) images.push(c.CombinationImage);
        });
      }

      const media = images.length > 0 ? images.map(getMediaUrl) : ["/placeholder-ad.png"];

      return {
        id: String(id),
        title: pData.ProductName || "Produit",
        description: pData.ProductDescription || "Aucune description fournie.",
        price: activePrice,
        images: media,
        city: pData.ProductCity || CITIES[0],
        date: formatDate(pData.PublishedAt),
        seller: buildSeller(pData.ProductVendor ?? pData.VendorProfile, SELLERS[0]),
      };
    }

    // Données de secours locales si l'API ne renvoie rien
    const localAds = getDefaultAds();
    const localIndex = localAds.findIndex((ad) => ad.id === id);
    if (localIndex >= 0) return normalizeLocalAd(localAds[localIndex], localIndex);

    return null;
  }, [id, pData, activePrice]);

  useEffect(() => {
    if (!selectedAd) return;

    if (!activeCombinationImage) {
      setCurrentImage(0);
      return;
    }

    const imageIndex = selectedAd.images.findIndex((image) => image === activeCombinationImage);
    setCurrentImage(imageIndex >= 0 ? imageIndex : 0);
  }, [activeCombinationImage, selectedAd]);

  const handleOptionSelect = (configID: number, optionID: number) => {
    setSelectedOptions((prev) => ({
      ...prev,
      [configID]: optionID,
    }));
  };

  const handleContactSeller = async () => {
    const sellerId = selectedAd?.seller.id;

    if (!isAuthenticated) {
      navigate("/login");
      return;
    }

    if (!sellerId) {
      navigate("/messages");
      return;
    }

    try {
      setIsStartingConversation(true);
      const conversation = await conversationApi.createConversation(sellerId);
      navigate(`/messages?conversation=${conversation.idConversation}`);
    } catch {
      toast({
        title: "Impossible d'ouvrir la conversation",
        description: "Nous n'avons pas pu créer cette conversation.",
        variant: "destructive",
      });
    } finally {
      setIsStartingConversation(false);
    }
  };

  // 1. État de Chargement
  if (isLoadingInfo) {
    return (
      <div className="min-h-screen bg-background flex flex-col">
        <Navbar />
        <main className="flex-1 container py-6 max-w-5xl">
          <div className="animate-pulse space-y-6">
            <div className="h-6 w-24 bg-muted rounded mb-4" />
            <div className="grid md:grid-cols-[1fr_360px] gap-6">
              <div className="h-[420px] bg-muted rounded-2xl" />
              <div className="space-y-4">
                <div className="h-40 bg-muted rounded-2xl" />
                <div className="h-28 bg-muted rounded-2xl" />
              </div>
            </div>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  // 2. Produit introuvable
  if (!selectedAd || isError) {
    return (
      <div className="min-h-screen bg-background flex flex-col">
        <Navbar />
        <main className="flex-1 flex items-center justify-center px-4 py-12">
          <div className="max-w-md w-full text-center bg-card border border-border rounded-2xl p-8 shadow-card">
            <h1 className="text-2xl font-heading font-bold mb-3">Annonce introuvable</h1>
            <p className="text-sm text-muted-foreground mb-6">
              L'annonce demandée (ID: {id}) n'existe pas ou ne peut pas être chargée.
            </p>
            <Button asChild className="rounded-xl">
              <Link to="/">Retour à l'accueil</Link>
            </Button>
          </div>
        </main>
        <Footer />
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-background flex flex-col"
    >
      <Navbar />
      <main className="flex-1">
        <div className="container py-6 max-w-5xl">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-primary mb-4 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" /> {t("back")}
          </Link>

          <div className="grid md:grid-cols-[1fr_380px] gap-6">
            {/* Colonne Gauche : Galerie et Description */}
            <div className="space-y-6">
              <div>
                <div className="aspect-[4/3] rounded-2xl overflow-hidden bg-muted border border-secondary/20">
                  <img
                    src={selectedAd.images[currentImage] || "/placeholder-ad.png"}
                    alt={selectedAd.title}
                    loading="lazy"
                    className="w-full h-full object-cover"
                  />
                </div>
                {selectedAd.images.length > 1 && (
                  <div className="flex gap-2 mt-3 flex-wrap">
                    {selectedAd.images.map((img, i) => (
                      <button
                        key={i}
                        onClick={() => setCurrentImage(i)}
                        onMouseEnter={() => setCurrentImage(i)}
                        className={`w-20 h-16 rounded-xl overflow-hidden border-2 transition-transform hover:scale-105 ${
                          i === currentImage ? "border-primary" : "border-secondary/20"
                        }`}
                      >
                        <img
                          src={img}
                          alt={`${selectedAd.title} aperçu ${i + 1}`}
                          loading="lazy"
                          className="w-full h-full object-cover"
                        />
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <div className="bg-card rounded-2xl border border-border p-5 shadow-card">
                <h3 className="font-heading font-semibold mb-2">{t("description")}</h3>
                <div className="text-sm text-muted-foreground leading-relaxed whitespace-pre-line break-words">
                  {selectedAd.description}
                </div>
              </div>

              <AvisSection annonceId={Number(selectedAd.id)} />
            </div>

            {/* Colonne Droite : Prix, Options et Vendeur */}
            <div className="space-y-4">
              <div className="sticky top-24 space-y-4">
                <div className="bg-card rounded-2xl border border-border p-5 shadow-card space-y-4">
                  <div className="flex flex-wrap items-center gap-2">
                    {pData?.BrandName && (
                      <span className="inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-md bg-primary/10 text-primary">
                        <Tag className="w-3 h-3" /> {pData.BrandName}
                        {pData.ModelName ? ` - ${pData.ModelName}` : ""}
                      </span>
                    )}
                    {pData?.ProductCategories?.map((cat, idx) => (
                      <span
                        key={idx}
                        className="text-xs px-2.5 py-1 rounded-md bg-muted text-muted-foreground"
                      >
                        {cat.CategoryName}
                      </span>
                    ))}
                    {(pData?.HasPromotion || pData?.ProductPromotion) && (
                      <span className="inline-flex items-center gap-1 rounded-md bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                        <Tag className="h-3 w-3" /> Promotion active
                      </span>
                    )}
                  </div>

                  <div>
                    <h1 className="text-lg font-semibold">{selectedAd.title}</h1>
                    <div className="flex items-baseline gap-3 mt-2">
                      <span className="text-3xl font-heading font-bold text-primary">
                        {activePrice.toFixed(2)} DH
                      </span>
                      {comparePrice && comparePrice > activePrice && (
                        <span className="text-base line-through text-muted-foreground">
                          {comparePrice.toFixed(2)} DH
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-xs border-y border-border py-2.5 text-muted-foreground">
                    <span className="flex items-center gap-1.5 font-medium">
                      <Package className="w-4 h-4 text-primary" />
                      Stock:{" "}
                      {activeStock > 0 ? (
                        <span className="text-emerald-600 font-bold">
                          {activeStock} disponibles
                        </span>
                      ) : (
                        <span className="text-red-500 font-bold">Rupture de stock</span>
                      )}
                    </span>
                    {matchedCombination?.SKU && (
                      <span className="font-mono">SKU: {matchedCombination.SKU}</span>
                    )}
                  </div>

                  {/* Options & Déclinaisons */}
                  {pData?.ProductDetails && pData.ProductDetails.length > 0 && (
                    <div className="space-y-3 pt-1">
                      {pData.ProductDetails.map((cfg) => (
                        <div key={cfg.ConfigID} className="space-y-1.5">
                          <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                            {cfg.ConfigName}
                          </label>
                          <div className="flex flex-wrap gap-2">
                            {cfg.Options?.map((opt) => {
                              const isSelected = selectedOptions[cfg.ConfigID] === opt.OptionID;
                              return (
                                <button
                                  key={opt.OptionID}
                                  type="button"
                                  onClick={() => handleOptionSelect(cfg.ConfigID, opt.OptionID)}
                                  className={`px-3 py-1.5 text-xs font-medium rounded-lg border transition-all ${
                                    isSelected
                                      ? "border-primary bg-primary/10 text-primary font-bold shadow-sm"
                                      : "border-border bg-background hover:bg-muted text-foreground"
                                  }`}
                                >
                                  {opt.OptionLabel}
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="flex items-center gap-3 text-sm text-muted-foreground pt-1">
                    <span className="flex items-center gap-1">
                      <MapPin className="h-4 w-4 text-secondary" />
                      {selectedAd.city}
                    </span>
                    <span className="flex items-center gap-1">
                      <Calendar className="h-4 w-4 text-secondary" />
                      {selectedAd.date}
                    </span>
                  </div>

                  <div className="space-y-2 pt-2">
                    <ShoppingCartButton
                      productID={Number(selectedAd.id)}
                      unitPrice={activePrice}
                      compositionID={matchedCombination?.CombinationID}
                      className="w-full h-12 text-base shadow-md rounded-xl font-semibold"
                    />

                    <div className="flex gap-2">
                      <Button
                        className="flex-1 bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl font-semibold h-12 gap-2"
                        onClick={() => void handleContactSeller()}
                        disabled={isStartingConversation}
                      >
                        <MessageCircle className="h-5 w-5" /> {t("contact_seller")}
                      </Button>
                      <FavoriteButton
                        productId={selectedAd.id}
                        ownerId={selectedAd.seller.id}
                        className="h-12 w-12 rounded-xl border border-secondary/30 bg-background hover:bg-secondary/10"
                        showCount
                      />
                      <ShareButtons
                        title={selectedAd.title}
                        description={selectedAd.description}
                        className="shrink-0"
                        triggerClassName="h-12 w-12 border-secondary/30 hover:bg-secondary/10"
                      />
                    </div>
                  </div>
                </div>

                {/* Modes de paiement */}
                {pData?.ProductAllowedPayements && pData.ProductAllowedPayements.length > 0 && (
                  <div className="bg-card rounded-2xl border border-border p-5 shadow-card space-y-3">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                      <CreditCard className="w-4 h-4 text-primary" /> Modes de paiement acceptés
                    </h4>
                    <div className="grid grid-cols-2 gap-2">
                      {pData.ProductAllowedPayements.map((pm) => (
                        <div
                          key={pm.PaymentMethodID}
                          className="flex items-center gap-2 p-2 rounded-xl bg-muted/40 border border-border/50 text-xs font-medium"
                        >
                          <ShieldCheck className="w-4 h-4 text-emerald-500 shrink-0" />
                          <span className="truncate">{pm.PaymentMethodName}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Profil vendeur */}
                <div className="bg-card rounded-2xl border border-border p-5 shadow-card">
                  <h3 className="font-heading font-semibold mb-3">{t("seller")}</h3>
                  <button
                    type="button"
                    onClick={() => setSellerDialogOpen(true)}
                    className="w-full flex items-center gap-3 text-left rounded-xl transition-colors hover:bg-muted/40 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  >
                    <div className="w-11 h-11 rounded-full overflow-hidden bg-secondary/10 flex items-center justify-center shrink-0">
                      {selectedAd.seller.avatar ? (
                        <img
                          src={selectedAd.seller.avatar}
                          alt={selectedAd.seller.name}
                          className="w-11 h-11 object-cover rounded-full"
                        />
                      ) : (
                        <User className="h-5 w-5 text-secondary" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="font-semibold text-sm truncate flex items-center gap-1">
                        {selectedAd.seller.name}
                        {selectedAd.seller.isVerified && (
                          <CheckCircle2 className="w-3.5 h-3.5 text-primary" />
                        )}
                      </p>
                      <StarRating
                        rating={selectedAd.seller.rating}
                        size="sm"
                        showCount
                        count={selectedAd.seller.reviewCount}
                      />
                      <p className="text-xs text-muted-foreground mt-0.5 truncate">
                        {selectedAd.seller.joined}
                      </p>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <SimilarProductsSection productId={productIdNum} />
      </main>

      {/* Modal du Profil Vendeur */}
      <Dialog open={sellerDialogOpen} onOpenChange={setSellerDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Profil du vendeur</DialogTitle>
            <DialogDescription>Détails disponibles pour ce vendeur.</DialogDescription>
          </DialogHeader>

          <div className="space-y-4 pt-2">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-muted overflow-hidden flex items-center justify-center shrink-0">
                {selectedAd.seller.avatar ? (
                  <img
                    src={selectedAd.seller.avatar}
                    alt={selectedAd.seller.name}
                    className="w-12 h-12 object-cover rounded-full"
                  />
                ) : (
                  <User className="h-5 w-5 text-secondary" />
                )}
              </div>
              <div className="min-w-0">
                <p className="font-semibold truncate">{selectedAd.seller.name}</p>
                <p className="text-xs text-muted-foreground truncate">{selectedAd.seller.joined}</p>
              </div>
            </div>

            <div className="rounded-xl border border-border bg-muted/20 p-4 grid gap-2 text-sm">
              <div className="flex items-center justify-between gap-3">
                <span className="text-muted-foreground">Note</span>
                <StarRating
                  rating={selectedAd.seller.rating}
                  size="sm"
                  showCount
                  count={selectedAd.seller.reviewCount}
                />
              </div>
              {selectedAd.seller.email && (
                <div className="flex items-center justify-between gap-3">
                  <span className="text-muted-foreground">Email</span>
                  <span className="font-medium text-right break-all">
                    {selectedAd.seller.email}
                  </span>
                </div>
              )}
              {selectedAd.seller.telephone && (
                <div className="flex items-center justify-between gap-3">
                  <span className="text-muted-foreground">Téléphone</span>
                  <span className="font-medium text-right">{selectedAd.seller.telephone}</span>
                </div>
              )}
              {selectedAd.seller.role && (
                <div className="flex items-center justify-between gap-3">
                  <span className="text-muted-foreground">Rôle</span>
                  <span className="font-medium text-right">{selectedAd.seller.role}</span>
                </div>
              )}
              {selectedAd.seller.dateInscription && (
                <div className="flex items-center justify-between gap-3">
                  <span className="text-muted-foreground">Inscrit le</span>
                  <span className="font-medium text-right">
                    {formatDate(selectedAd.seller.dateInscription)}
                  </span>
                </div>
              )}
              <div className="flex items-center justify-between gap-3">
                <span className="text-muted-foreground">Statut</span>
                <span className="font-medium text-right">
                  {selectedAd.seller.isVerified ? "Vérifié" : "Non vérifié"}
                  {selectedAd.seller.estActif === false ? " · Inactif" : ""}
                </span>
              </div>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Footer />
    </motion.div>
  );
};

export default AdDetails;
