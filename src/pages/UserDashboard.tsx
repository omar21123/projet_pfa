import { useEffect, useMemo } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowUpRight,
  BadgeCheck,
  Heart,
  LayoutDashboard,
  Mail,
  Package,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  UserRound,
} from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import AdCard from "@/components/AdCard";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import { useLanguage } from "@/contexts/LanguageContext";
import { useUser } from "@/hooks/useUser";
import { useProfile } from "@/hooks/useProfile";
import { useFavoriteAds } from "@/features/ads/hooks/useFavoriteAds";
import { adsMeApi } from "@/api/ads_me_.api";
import { type AnnonceDto } from "@/types";
import { AdStatus } from "@/types/ad.types";
import { formatDate } from "@/utils/format";
import { env } from "@/config/env";

const resolveImageUrl = (path?: string) => {
  if (!path) return "/placeholder-ad.png";
  if (/^https?:\/\//i.test(path)) return path;
  return new URL(path, env.apiUrl).toString();
};

const DashboardSkeleton = () => (
  <div className="space-y-6">
    <Card className="overflow-hidden border-border/60 shadow-lg shadow-black/5">
      <CardHeader className="border-b border-border/60 bg-muted/30 pb-8">
        <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <Skeleton className="h-20 w-20 rounded-full" />
            <div className="space-y-3">
              <Skeleton className="h-8 w-56" />
              <Skeleton className="h-4 w-72" />
              <div className="flex gap-2">
                <Skeleton className="h-6 w-24 rounded-full" />
                <Skeleton className="h-6 w-24 rounded-full" />
              </div>
            </div>
          </div>
          <Skeleton className="h-11 w-44 rounded-xl" />
        </div>
      </CardHeader>
      <CardContent className="p-6 md:p-8">
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }).map((_, index) => (
            <Skeleton key={index} className="h-24 rounded-2xl" />
          ))}
        </div>
      </CardContent>
    </Card>

    <div className="grid gap-6 lg:grid-cols-2">
      <Skeleton className="h-[420px] rounded-3xl" />
      <Skeleton className="h-[420px] rounded-3xl" />
    </div>
  </div>
);

const DashboardEmptyState = ({
  title,
  description,
  actionHref,
  actionLabel,
  icon: Icon,
}: {
  title: string;
  description: string;
  actionHref: string;
  actionLabel: string;
  icon: typeof Package;
}) => (
  <div className="rounded-3xl border border-dashed border-border/70 bg-muted/20 p-8 text-center">
    <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-primary/10 text-primary">
      <Icon className="h-7 w-7" />
    </div>
    <h3 className="text-lg font-semibold">{title}</h3>
    <p className="mx-auto mt-2 max-w-md text-sm text-muted-foreground">{description}</p>
    <Button asChild className="mt-6 gap-2 rounded-xl">
      <Link to={actionHref}>
        {actionLabel}
        <ArrowUpRight className="h-4 w-4" />
      </Link>
    </Button>
  </div>
);

const UserDashboard = () => {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const { user } = useUser();
  const {
    data: profile,
    isLoading: isProfileLoading,
    error: profileError,
    refetch: refetchProfile,
  } = useProfile();
  const {
    data: favoriteAds = [],
    isLoading: isFavoritesLoading,
    error: favoritesError,
    refetch: refetchFavorites,
  } = useFavoriteAds();

  const myAdsQuery = useQuery<AnnonceDto[], Error>({
    queryKey: ["dashboard", "my-ads"],
    queryFn: () => adsMeApi.getMine(AdStatus.PUBLISHED),
    enabled: Boolean(user),
    staleTime: 1000 * 60 * 3,
    gcTime: 1000 * 60 * 10,
  });

  useEffect(() => {
    if (!user) {
      navigate("/login");
    }
  }, [navigate, user]);

  const memberSince = useMemo(() => {
    const dateSource = profile?.dateInscription;
    if (!dateSource) return new Date().getFullYear();
    const parsed = new Date(dateSource);
    return Number.isNaN(parsed.getTime()) ? new Date().getFullYear() : parsed.getFullYear();
  }, [profile?.dateInscription]);

  const stats = useMemo(
    () => [
      {
        label: t("my_ads"),
        value: myAdsQuery.data?.length ?? 0,
        icon: Package,
        description: "Annonces publiées et suivies",
        href: "/my-ads",
      },
      {
        label: t("favorites"),
        value: favoriteAds.length,
        icon: Heart,
        description: "Articles sauvegardés",
        href: "/favorites",
      },
      {
        label: "Profil",
        value: profile ? 100 : 0,
        icon: UserRound,
        description: "Données de compte disponibles",
        href: "/profile",
      },
      {
        label: "Réglages",
        value: profile?.estActif ? 1 : 0,
        icon: ShieldCheck,
        description: "Compte actif et connecté",
        href: "/settings",
      },
    ],
    [favoriteAds.length, myAdsQuery.data?.length, profile, t],
  );

  const recentAds = myAdsQuery.data?.slice(0, 3) ?? [];
  const recentFavorites = favoriteAds.slice(0, 4);
  const isLoading = isProfileLoading || myAdsQuery.isLoading || isFavoritesLoading;
  const hasError = profileError || favoritesError || myAdsQuery.error;

  if (isLoading) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="min-h-screen bg-background flex flex-col"
      >
        <Navbar />
        <main className="flex-1">
          <div className="container mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
            <DashboardSkeleton />
          </div>
        </main>
        <Footer />
      </motion.div>
    );
  }

  if (!user) {
    return null;
  }

  const userName = profile ? `${profile.prenom} ${profile.nom}`.trim() : user.name;
  const email = profile?.email ?? user.email;
  const initials = userName
    .split(" ")
    .filter(Boolean)
    .map((value) => value[0]?.toUpperCase())
    .join("")
    .slice(0, 2);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(15,23,42,0.06),_transparent_42%),linear-gradient(to_bottom,_rgba(248,250,252,1),_rgba(241,245,249,0.72))] flex flex-col"
    >
      <Navbar />
      <main className="flex-1">
        <div className="container mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8">
          <Card className="overflow-hidden border-border/60 bg-card/95 shadow-xl shadow-black/5 backdrop-blur">
            <CardHeader className="border-b border-border/60 bg-muted/30 pb-8">
              <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
                <div className="flex items-center gap-4">
                  <div className="flex h-20 w-20 items-center justify-center rounded-full border border-border bg-background shadow-sm">
                    <span className="text-lg font-semibold text-foreground">{initials || "U"}</span>
                  </div>
                  <div className="space-y-2">
                    <div className="flex flex-wrap items-center gap-3">
                      <CardTitle className="text-3xl font-semibold tracking-tight text-foreground">
                        {userName}
                      </CardTitle>
                      <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-200 bg-emerald-50 px-3 py-1 text-sm font-medium text-emerald-700">
                        <BadgeCheck className="h-3.5 w-3.5" />
                        {profile?.isVerified ? "Compte vérifié" : "Compte en attente"}
                      </span>
                    </div>
                    <CardDescription className="max-w-2xl text-base">
                      Un tableau de bord centralisé pour suivre votre profil, vos annonces et vos
                      favoris.
                    </CardDescription>
                    <div className="flex flex-wrap gap-2 text-sm text-muted-foreground">
                      <span className="inline-flex items-center gap-2 rounded-full bg-background px-3 py-1.5">
                        <Mail className="h-4 w-4" />
                        {email}
                      </span>
                      <span className="inline-flex items-center gap-2 rounded-full bg-background px-3 py-1.5">
                        <LayoutDashboard className="h-4 w-4" />
                        Membre depuis {memberSince}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="flex shrink-0 gap-3">
                  <Button asChild variant="outline" className="gap-2 rounded-xl">
                    <Link to="/profile">
                      Voir le profil
                      <ArrowUpRight className="h-4 w-4" />
                    </Link>
                  </Button>
                  <Button asChild className="gap-2 rounded-xl">
                    <Link to="/create">
                      Nouvelle annonce
                      <Sparkles className="h-4 w-4" />
                    </Link>
                  </Button>
                </div>
              </div>
            </CardHeader>

            <CardContent className="p-6 md:p-8 space-y-6">
              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                {stats.map((stat) => {
                  const Icon = stat.icon;
                  return (
                    <Link key={stat.label} to={stat.href} className="group">
                      <div className="rounded-2xl border border-border/60 bg-background/80 p-4 shadow-sm transition-transform group-hover:-translate-y-0.5 group-hover:shadow-md">
                        <div className="mb-3 flex items-center justify-between gap-3 text-sm text-muted-foreground">
                          <span className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
                            <Icon className="h-5 w-5" />
                          </span>
                          <ArrowUpRight className="h-4 w-4 opacity-0 transition-opacity group-hover:opacity-100" />
                        </div>
                        <p className="text-3xl font-semibold tracking-tight">{stat.value}</p>
                        <p className="mt-1 text-sm font-medium text-foreground">{stat.label}</p>
                        <p className="mt-1 text-xs text-muted-foreground">{stat.description}</p>
                      </div>
                    </Link>
                  );
                })}
              </div>

              <Separator />

              {hasError ? (
                <div className="rounded-3xl border border-destructive/20 bg-destructive/5 p-6">
                  <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                    <div>
                      <h3 className="text-lg font-semibold">
                        Certaines données n'ont pas pu être chargées
                      </h3>
                      <p className="mt-1 text-sm text-muted-foreground">
                        Le profil, les annonces ou les favoris sont temporairement indisponibles.
                      </p>
                    </div>
                    <div className="flex gap-3">
                      <Button
                        variant="outline"
                        onClick={() => void refetchProfile()}
                        className="gap-2"
                      >
                        <RefreshCw className="h-4 w-4" />
                        Profil
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => void refetchFavorites()}
                        className="gap-2"
                      >
                        <RefreshCw className="h-4 w-4" />
                        Favoris
                      </Button>
                      <Button onClick={() => void myAdsQuery.refetch()} className="gap-2">
                        <RefreshCw className="h-4 w-4" />
                        Annonces
                      </Button>
                    </div>
                  </div>
                </div>
              ) : null}

              <div className="grid gap-6 lg:grid-cols-2">
                <Card className="border-border/60 shadow-lg shadow-black/5">
                  <CardHeader className="border-b border-border/60 bg-muted/20">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <CardTitle className="flex items-center gap-2 text-xl">
                          <Package className="h-5 w-5 text-primary" />
                          Mes annonces récentes
                        </CardTitle>
                        <CardDescription>
                          Aperçu rapide des publications issues de la page MyAds.
                        </CardDescription>
                      </div>
                      <Button asChild variant="outline" className="rounded-xl">
                        <Link to="/my-ads">
                          Voir tout
                          <ArrowUpRight className="h-4 w-4" />
                        </Link>
                      </Button>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4 p-6">
                    {recentAds.length === 0 ? (
                      <DashboardEmptyState
                        title="Aucune annonce publiée"
                        description="Publiez votre première annonce pour la faire apparaître ici."
                        actionHref="/create"
                        actionLabel="Créer une annonce"
                        icon={Package}
                      />
                    ) : (
                      recentAds.map((ad) => (
                        <div
                          key={ad.id}
                          className="group flex items-center gap-4 rounded-2xl border border-border/60 bg-background/80 p-3 shadow-sm transition-shadow hover:shadow-md"
                        >
                          <img
                            src={resolveImageUrl(ad.photosUrls[0])}
                            alt={ad.titre}
                            loading="lazy"
                            className="h-20 w-24 rounded-xl object-cover"
                          />
                          <div className="min-w-0 flex-1">
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <h3 className="truncate font-semibold text-sm">{ad.titre}</h3>
                                <p className="mt-0.5 text-sm font-bold text-primary">
                                  {ad.prix.toLocaleString()} DH
                                </p>
                              </div>
                              <span className="rounded-full bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary">
                                {ad.statut}
                              </span>
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">
                              {ad.ville} • {formatDate(ad.datepublication)}
                            </p>
                          </div>
                        </div>
                      ))
                    )}
                  </CardContent>
                </Card>

                <Card className="border-border/60 shadow-lg shadow-black/5">
                  <CardHeader className="border-b border-border/60 bg-muted/20">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <CardTitle className="flex items-center gap-2 text-xl">
                          <Heart className="h-5 w-5 text-primary fill-primary" />
                          Mes favoris
                        </CardTitle>
                        <CardDescription>
                          Les annonces sauvegardées les plus récentes.
                        </CardDescription>
                      </div>
                      <Button asChild variant="outline" className="rounded-xl">
                        <Link to="/favorites">
                          Voir tout
                          <ArrowUpRight className="h-4 w-4" />
                        </Link>
                      </Button>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4 p-6">
                    {recentFavorites.length === 0 ? (
                      <DashboardEmptyState
                        title="Aucun favori pour le moment"
                        description="Ajoutez des annonces à vos favoris pour les retrouver ici plus vite."
                        actionHref="/favorites"
                        actionLabel="Parcourir les favoris"
                        icon={Heart}
                      />
                    ) : (
                      recentFavorites.map((ad) => (
                        <Link
                          key={ad.id}
                          to={`/ad/${ad.id}`}
                          className="group flex items-center gap-4 rounded-2xl border border-border/60 bg-background/80 p-3 shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md"
                        >
                          <img
                            src={resolveImageUrl(ad.photosUrls[0])}
                            alt={ad.titre}
                            loading="lazy"
                            className="h-20 w-24 rounded-xl object-cover"
                          />
                          <div className="min-w-0 flex-1">
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <h3 className="truncate font-semibold text-sm">{ad.titre}</h3>
                                <p className="mt-0.5 text-sm font-bold text-primary">
                                  {ad.prix.toLocaleString()} DH
                                </p>
                              </div>
                              <span className="rounded-full bg-secondary/10 px-2.5 py-1 text-xs font-medium text-secondary">
                                {ad.categorie}
                              </span>
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">
                              {ad.ville} • {formatDate(ad.datepublication)}
                            </p>
                          </div>
                        </Link>
                      ))
                    )}
                  </CardContent>
                </Card>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
      <Footer />
    </motion.div>
  );
};

export default UserDashboard;
