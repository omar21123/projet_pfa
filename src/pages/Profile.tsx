import { useEffect } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft,
  BadgeCheck,
  CalendarClock,
  CheckCircle2,
  Mail,
  Phone,
  RefreshCw,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import { toast } from "@/components/ui/sonner";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import { useProfile } from "@/hooks/useProfile";
import { formatDate } from "@/utils/format";

const Profile = () => {
  const { data: profile, isLoading, error, refetch } = useProfile();

  useEffect(() => {
    if (error) {
      toast.error(error);
    }
  }, [error]);

  const initials = profile
    ? [profile.prenom, profile.nom]
        .filter(Boolean)
        .map((value) => value[0]?.toUpperCase())
        .join("")
    : "U";

  if (isLoading) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.25 }}
        className="min-h-screen bg-background"
      >
        <div className="container mx-auto max-w-5xl px-4 py-8 sm:px-6 lg:px-8">
          <div className="mb-8 flex items-center gap-3">
            <Skeleton className="h-5 w-5 rounded-full" />
            <Skeleton className="h-4 w-32" />
          </div>

          <Card className="overflow-hidden border-border/60 shadow-lg shadow-black/5">
            <CardHeader className="space-y-4 border-b border-border/60 bg-muted/30">
              <div className="flex items-center gap-4">
                <Skeleton className="h-20 w-20 rounded-full" />
                <div className="flex-1 space-y-3">
                  <Skeleton className="h-8 w-60" />
                  <Skeleton className="h-4 w-72" />
                  <div className="flex gap-2">
                    <Skeleton className="h-6 w-24 rounded-full" />
                    <Skeleton className="h-6 w-24 rounded-full" />
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent className="grid gap-4 p-6 sm:grid-cols-2">
              {Array.from({ length: 6 }).map((_, index) => (
                <div key={index} className="rounded-2xl border border-border/60 bg-muted/30 p-4">
                  <Skeleton className="mb-3 h-4 w-24" />
                  <Skeleton className="h-5 w-full" />
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </motion.div>
    );
  }

  if (error && !profile) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.25 }}
        className="min-h-screen bg-background"
      >
        <div className="container mx-auto max-w-3xl px-4 py-8 sm:px-6 lg:px-8">
          <Link
            to="/"
            className="mb-8 inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80"
          >
            <ArrowLeft className="h-4 w-4" />
            Retour à l'accueil
          </Link>

          <Card className="border-destructive/20 shadow-lg shadow-black/5">
            <CardHeader>
              <CardTitle className="text-2xl">Profil indisponible</CardTitle>
              <CardDescription>{error}</CardDescription>
            </CardHeader>
            <CardContent className="flex gap-3">
              <Button onClick={() => void refetch()} className="gap-2">
                <RefreshCw className="h-4 w-4" />
                Réessayer
              </Button>
              <Button asChild variant="outline">
                <Link to="/settings">Aller aux paramètres</Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </motion.div>
    );
  }

  if (!profile) {
    return null;
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.25 }}
      className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(15,23,42,0.06),_transparent_42%),linear-gradient(to_bottom,_rgba(248,250,252,1),_rgba(241,245,249,0.72))]"
    >
      <div className="container mx-auto max-w-5xl px-4 py-8 sm:px-6 lg:px-8">
        <Link
          to="/"
          className="mb-8 inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80"
        >
          <ArrowLeft className="h-4 w-4" />
          Retour à l'accueil
        </Link>

        <Card className="overflow-hidden border-border/60 bg-card/95 shadow-xl shadow-black/5 backdrop-blur">
          <CardHeader className="border-b border-border/60 bg-muted/30 pb-8">
            <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
              <div className="flex items-center gap-4">
                <Avatar className="h-20 w-20 border border-border bg-background shadow-sm">
                  <AvatarFallback className="text-lg font-semibold">{initials}</AvatarFallback>
                </Avatar>
                <div className="space-y-2">
                  <div className="flex flex-wrap items-center gap-3">
                    <CardTitle className="text-3xl font-semibold tracking-tight text-foreground">
                      {profile.prenom} {profile.nom}
                    </CardTitle>
                    <Badge
                      variant="secondary"
                      className="gap-1.5 border-emerald-200 bg-emerald-50 text-emerald-700"
                    >
                      <ShieldCheck className="h-3.5 w-3.5" />
                      Rôle #{profile.role}
                    </Badge>
                  </div>
                  <CardDescription className="max-w-2xl text-base">
                    Gérez vos informations de compte et consultez l’état de votre profil
                    utilisateur.
                  </CardDescription>
                  <div className="flex flex-wrap gap-2">
                    <Badge
                      variant={profile.estActif ? "default" : "destructive"}
                      className={
                        profile.estActif
                          ? "gap-1.5 bg-emerald-600 text-white hover:bg-emerald-600/90"
                          : "gap-1.5"
                      }
                    >
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      {profile.estActif ? "Compte actif" : "Compte inactif"}
                    </Badge>
                    <Badge
                      variant={profile.isVerified ? "default" : "outline"}
                      className={
                        profile.isVerified
                          ? "gap-1.5 bg-sky-600 text-white hover:bg-sky-600/90"
                          : "gap-1.5 border-dashed"
                      }
                    >
                      <BadgeCheck className="h-3.5 w-3.5" />
                      {profile.isVerified ? "Email vérifié" : "Email non vérifié"}
                    </Badge>
                  </div>
                </div>
              </div>

              <Button asChild variant="outline" className="shrink-0 gap-2">
                <Link to="/settings">
                  <UserRound className="h-4 w-4" />
                  Modifier le profil
                </Link>
              </Button>
            </div>
          </CardHeader>

          <CardContent className="space-y-6 p-6 md:p-8">
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              <StatItem icon={Mail} label="Adresse email" value={profile.email} />
              <StatItem icon={Phone} label="Téléphone" value={profile.telephone} />
              <StatItem
                icon={CalendarClock}
                label="Inscription"
                value={formatDate(profile.dateInscription)}
              />
              <StatItem
                icon={ShieldCheck}
                label="Dernière connexion"
                value={profile.derniereConnexion ? formatDate(profile.derniereConnexion) : "Jamais"}
              />
            </div>

            <Separator />

            <div className="grid gap-4 md:grid-cols-2">
              <DetailCard label="Identifiant" value={String(profile.id)} />
              <DetailCard label="Prénom" value={profile.prenom} />
              <DetailCard label="Nom" value={profile.nom} />
              <DetailCard label="Rôle" value={`Role #${profile.role}`} />
            </div>
          </CardContent>
        </Card>
      </div>
    </motion.div>
  );
};

interface StatItemProps {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string;
}

const StatItem = ({ icon: Icon, label, value }: StatItemProps) => (
  <div className="rounded-2xl border border-border/60 bg-background/80 p-4 shadow-sm">
    <div className="mb-3 flex items-center gap-2 text-sm text-muted-foreground">
      <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary">
        <Icon className="h-4 w-4" />
      </span>
      {label}
    </div>
    <p className="break-words text-sm font-medium leading-6 text-foreground">{value}</p>
  </div>
);

interface DetailCardProps {
  label: string;
  value: string;
}

const DetailCard = ({ label, value }: DetailCardProps) => (
  <div className="rounded-2xl border border-border/60 bg-muted/20 p-4">
    <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{label}</p>
    <p className="mt-2 break-words text-sm font-medium text-foreground">{value}</p>
  </div>
);

export default Profile;
