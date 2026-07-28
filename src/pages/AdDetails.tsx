import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, MapPin, Calendar, User, MessageCircle } from "lucide-react";
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
import { useAds } from "@/features/ads/hooks/useAds";
import { FavoriteButton } from "@/features/favorites";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { AnnonceDto } from "@/types";
import type { Ad as LocalAd } from "@/types/ad.types";

const CITIES = ["Casablanca", "Rabat", "Marrakech", "Fès", "Tanger", "Agadir"];
const SELLERS = [
  { name: "Ahmed M.", joined: "Membre depuis 2024", rating: 4.5, reviewCount: 23 },
  { name: "Fatima B.", joined: "Membre depuis 2023", rating: 4.8, reviewCount: 45 },
  { name: "Hassan R.", joined: "Membre depuis 2022", rating: 4.9, reviewCount: 67 },
  { name: "Mohammed K.", joined: "Membre depuis 2024", rating: 4.6, reviewCount: 12 },
  { name: "Sarah D.", joined: "Membre depuis 2023", rating: 4.7, reviewCount: 34 },
  { name: "Nadia L.", joined: "Membre depuis 2024", rating: 4.4, reviewCount: 18 },
];

const formatDate = (value?: string) => {
  if (!value) {
    return "Non renseignée";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "Non renseignée";
  }

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

const buildSeller = (profile: AnnonceDto["vendeur"], fallback: Seller) => {
  if (!profile) {
    return fallback;
  }

  const fullName = [profile.prenom, profile.nom].filter(Boolean).join(" ").trim();

  return {
    id: profile.id,
    name: fullName || fallback.name,
    joined: profile.dateInscription
      ? `Membre depuis ${new Date(profile.dateInscription).getFullYear()}`
      : fallback.joined,
    rating: fallback.rating,
    reviewCount: fallback.reviewCount,
    email: profile.email,
    telephone: profile.telephone ?? undefined,
    role: profile.role,
    isVerified: profile.isVerified,
    estActif: profile.estActif,
    dateInscription: profile.dateInscription ?? undefined,
    avatar: undefined,
  };
};

const normalizeApiAd = (ad: AnnonceDto, index: number): DetailAd => ({
  id: String(ad.id),
  title: ad.titre,
  description: ad.description,
  price: ad.prix,
  images: (ad.photosUrls.length > 0 ? ad.photosUrls : ["/placeholder-ad.png"]).map(getMediaUrl),
  city: ad.ville || CITIES[index % CITIES.length],
  date: formatDate(ad.datepublication),
  seller: buildSeller(ad.vendeur, SELLERS[index % SELLERS.length]),
});

const normalizeLocalAd = (ad: LocalAd, index: number): DetailAd => ({
  id: ad.id,
  title: ad.title,
  description: ad.description,
  price: ad.price,
  images: ad.images.length > 0 ? ad.images : ["/placeholder-ad.png"],
  city: CITIES[index % CITIES.length],
  date: formatDate(ad.createdAt),
  seller: SELLERS[index % SELLERS.length],
});

const AdDetails = () => {
  const { t } = useLanguage();
  const { id } = useParams();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const { toast } = useToast();
  const [currentImage, setCurrentImage] = useState(0);
  const [sellerDialogOpen, setSellerDialogOpen] = useState(false);
  const [isStartingConversation, setIsStartingConversation] = useState(false);
  const { data: ads = [], isLoading } = useAds();

  const selectedAd = useMemo<DetailAd | null>(() => {
    if (!id) {
      return null;
    }

    const apiIndex = ads.findIndex((ad) => String(ad.id) === id);
    if (apiIndex >= 0) {
      return normalizeApiAd(ads[apiIndex], apiIndex);
    }

    const localAds = getDefaultAds();
    const localIndex = localAds.findIndex((ad) => ad.id === id);
    if (localIndex >= 0) {
      return normalizeLocalAd(localAds[localIndex], localIndex);
    }

    return null;
  }, [ads, id]);

  useEffect(() => {
    setCurrentImage(0);
  }, [selectedAd?.id]);

  useEffect(() => {
    setSellerDialogOpen(false);
  }, [selectedAd?.seller.email, selectedAd?.seller.name]);

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
        description: "Nous n'avons pas pu créer ou récupérer cette conversation.",
        variant: "destructive",
      });
    } finally {
      setIsStartingConversation(false);
    }
  };

  if (isLoading && !selectedAd) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.3 }}
        className="min-h-screen bg-background flex flex-col"
      >
        <Navbar />
        <main className="flex-1 flex items-center justify-center text-sm text-muted-foreground">
          Chargement de l'annonce...
        </main>
        <Footer />
      </motion.div>
    );
  }

  if (!selectedAd) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.3 }}
        className="min-h-screen bg-background flex flex-col"
      >
        <Navbar />
        <main className="flex-1 flex items-center justify-center px-4">
          <div className="max-w-md w-full text-center bg-card border border-border rounded-2xl p-8 shadow-card">
            <h1 className="text-2xl font-heading font-bold mb-3">Annonce introuvable</h1>
            <p className="text-sm text-muted-foreground mb-6">
              L'annonce demandée n'existe pas ou n'est plus disponible.
            </p>
            <Button asChild className="rounded-xl">
              <Link to="/">Retour à l'accueil</Link>
            </Button>
          </div>
        </main>
        <Footer />
      </motion.div>
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

          <div className="grid md:grid-cols-[1fr_360px] gap-6">
            <div className="space-y-6">
              <div>
                <div className="aspect-[4/3] rounded-2xl overflow-hidden bg-muted border border-secondary/20">
                  <img
                    src={selectedAd.images[currentImage]}
                    alt={selectedAd.title}
                    loading="lazy"
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="flex gap-2 mt-3 flex-wrap">
                  {selectedAd.images.map((img, i) => (
                    <button
                      key={i}
                      onClick={() => setCurrentImage(i)}
                      className={`w-20 h-16 rounded-xl overflow-hidden border-2 transition-colors ${i === currentImage ? "border-primary" : "border-secondary/20"}`}
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
              </div>
              <AvisSection annonceId={Number(selectedAd.id)} />
            </div>

            <div className="space-y-4">
              <div className="bg-card rounded-2xl border border-border p-5 shadow-card">
                <p className="text-2xl font-heading font-bold text-primary">
                  {selectedAd.price.toLocaleString()} DH
                </p>
                <h1 className="text-lg font-semibold mt-2">{selectedAd.title}</h1>
                <div className="flex items-center gap-3 mt-3 text-sm text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <MapPin className="h-4 w-4 text-secondary" />
                    {selectedAd.city}
                  </span>
                  <span className="flex items-center gap-1">
                    <Calendar className="h-4 w-4 text-secondary" />
                    {selectedAd.date}
                  </span>
                </div>
                <div className="flex gap-2 mt-5">
                  <Button
                    className="flex-1 bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl font-semibold h-12 gap-2"
                    onClick={() => void handleContactSeller()}
                    disabled={isStartingConversation}
                  >
                    <MessageCircle className="h-5 w-5" /> {t("contact_seller")}
                  </Button>
                  <FavoriteButton
                    annonceId={selectedAd.id}
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

              <div className="bg-card rounded-2xl border border-border p-5 shadow-card">
                <h3 className="font-heading font-semibold mb-2">{t("description")}</h3>
                <div className="text-sm text-muted-foreground leading-relaxed whitespace-pre-line max-h-[60vh] overflow-auto pr-2 break-words">
                  {selectedAd.description}
                </div>
              </div>

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
                    <p className="font-semibold text-sm truncate">{selectedAd.seller.name}</p>
                    <StarRating
                      rating={selectedAd.seller.rating}
                      size="sm"
                      showCount
                      count={selectedAd.seller.reviewCount}
                    />
                    <p className="text-xs text-muted-foreground mt-0.5 truncate">
                      {selectedAd.seller.joined}
                    </p>
                    <p className="text-xs text-muted-foreground mt-1 truncate">
                      {selectedAd.seller.email || ""}
                    </p>
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
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
