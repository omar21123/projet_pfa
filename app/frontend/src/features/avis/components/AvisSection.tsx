import { useState } from "react";
import { Link } from "react-router-dom";
import { Send, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import StarRating from "@/components/StarRating";
import { useAuth } from "@/contexts";
import { useAvis } from "@/features/avis/hooks/useAvis";

const formatDate = (value?: string) => {
  if (!value) {
    return "";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "";
  }

  return date.toLocaleDateString("fr-FR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};

type AvisSectionProps = {
  annonceId: number;
};

const AvisSection = ({ annonceId }: AvisSectionProps) => {
  const { avis, loading, error, submitAvis, isSubmitting } = useAvis(annonceId);
  const { isAuthenticated } = useAuth();
  const [note, setNote] = useState(0);
  const [commentaire, setCommentaire] = useState("");
  const [selectedAvis, setSelectedAvis] = useState<(typeof avis)[number] | null>(null);

  const handleSubmit = async () => {
    if (note === 0 || !commentaire.trim()) {
      return;
    }

    await submitAvis({ note, commentaire: commentaire.trim() });
    setNote(0);
    setCommentaire("");
  };

  return (
    <div className="bg-card rounded-2xl border border-border p-6 shadow-card space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h3 className="font-heading font-semibold text-lg">Avis ({avis.length})</h3>
        <span className="text-xs text-muted-foreground">Partagez votre expérience</span>
      </div>

      {loading && <p className="text-sm text-muted-foreground">Chargement des avis...</p>}

      {!loading && error && (
        <p className="text-sm text-destructive">Impossible de charger les avis pour le moment.</p>
      )}

      <div className="space-y-4">
        {avis.length === 0 && !loading && !error && (
          <p className="text-sm text-muted-foreground">Aucun avis pour cette annonce.</p>
        )}

        {avis.map((avisItem) => {
          const profile = avisItem.utilisateur;
          const authorName =
            [profile?.prenom, profile?.nom].filter(Boolean).join(" ").trim() ||
            avisItem.nomUtilisateur?.trim() ||
            "Utilisateur";
          const authorInitial = authorName.charAt(0).toUpperCase() || "?";
          const message = avisItem.commentaire ?? avisItem.cmt ?? "";

          return (
            <div
              key={avisItem.id}
              className="border-b border-border/70 pb-4 last:border-b-0 last:pb-0"
            >
              <div className="flex justify-between items-start gap-3 mb-2">
                <div className="flex items-center gap-2 min-w-0">
                  <button
                    type="button"
                    onClick={() => setSelectedAvis(avisItem)}
                    className="w-8 h-8 rounded-full bg-muted flex items-center justify-center font-bold text-sm shrink-0 transition-transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-primary/30"
                    aria-label={`Voir le profil de ${authorName}`}
                  >
                    {authorInitial}
                  </button>
                  <div className="min-w-0">
                    <span className="font-semibold text-sm block truncate">{authorName}</span>
                    {avisItem.dateCreation && (
                      <span className="text-xs text-muted-foreground">
                        {formatDate(avisItem.dateCreation)}
                      </span>
                    )}
                  </div>
                </div>
                <StarRating rating={avisItem.note} size="sm" />
              </div>
              <p className="text-sm text-foreground/90 whitespace-pre-line">{message}</p>
            </div>
          );
        })}
      </div>

      {isAuthenticated ? (
        <div className="space-y-3 pt-2 border-t border-border/70">
          <div className="flex items-center gap-2">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                onClick={() => setNote(star)}
                className="transition-transform hover:scale-110"
                aria-label={`Noter ${star} étoile${star > 1 ? "s" : ""}`}
              >
                <Star
                  size={20}
                  className={
                    star <= note ? "text-amber-400 fill-amber-400" : "text-muted-foreground/40"
                  }
                />
              </button>
            ))}
          </div>

          <div className="flex gap-2">
            <input
              value={commentaire}
              onChange={(e) => setCommentaire(e.target.value)}
              placeholder="Laisser un avis..."
              className="flex-1 h-11 px-4 rounded-xl bg-muted/30 border border-border outline-none text-sm focus:border-primary"
            />
            <Button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting || note === 0 || !commentaire.trim()}
              className="h-11 w-11 rounded-xl"
            >
              <Send size={16} />
            </Button>
          </div>
        </div>
      ) : (
        <div className="pt-2 border-t border-border/70 text-sm text-muted-foreground">
          <Link to="/login" className="text-primary hover:underline">
            Connectez-vous
          </Link>{" "}
          pour laisser un avis.
        </div>
      )}

      <Dialog open={Boolean(selectedAvis)} onOpenChange={(open) => !open && setSelectedAvis(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Profil de l'utilisateur</DialogTitle>
            <DialogDescription>Détails disponibles pour cet avis.</DialogDescription>
          </DialogHeader>

          {selectedAvis &&
            (() => {
              const selectedAuthorName =
                [selectedAvis.utilisateur?.prenom, selectedAvis.utilisateur?.nom]
                  .filter(Boolean)
                  .join(" ")
                  .trim() ||
                selectedAvis.nomUtilisateur ||
                "Utilisateur";

              return (
                <div className="space-y-4 pt-2">
                  {selectedAvis.utilisateur && (
                    <div className="rounded-xl border border-border bg-muted/20 p-4 grid gap-2 text-sm">
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-muted-foreground">Nom complet</span>
                        <span className="font-semibold text-right">
                          {[selectedAvis.utilisateur.prenom, selectedAvis.utilisateur.nom]
                            .filter(Boolean)
                            .join(" ") ||
                            selectedAvis.nomUtilisateur ||
                            "Utilisateur"}
                        </span>
                      </div>
                      {selectedAvis.utilisateur.email && (
                        <div className="flex items-center justify-between gap-3">
                          <span className="text-muted-foreground">Email</span>
                          <span className="font-medium text-right break-all">
                            {selectedAvis.utilisateur.email}
                          </span>
                        </div>
                      )}
                      {selectedAvis.utilisateur.telephone && (
                        <div className="flex items-center justify-between gap-3">
                          <span className="text-muted-foreground">Téléphone</span>
                          <span className="font-medium text-right">
                            {selectedAvis.utilisateur.telephone}
                          </span>
                        </div>
                      )}
                      {selectedAvis.utilisateur.role && (
                        <div className="flex items-center justify-between gap-3">
                          <span className="text-muted-foreground">Rôle</span>
                          <span className="font-medium text-right">
                            {selectedAvis.utilisateur.role}
                          </span>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center font-bold text-base shrink-0">
                      {(
                        selectedAvis.utilisateur?.prenom?.trim()?.charAt(0) ||
                        selectedAvis.nomUtilisateur?.trim()?.charAt(0) ||
                        "?"
                      ).toUpperCase()}
                    </div>
                    <div className="min-w-0">
                      <p className="font-semibold truncate">{selectedAuthorName}</p>
                      <p className="text-xs text-muted-foreground">
                        Avis publié
                        {selectedAvis.dateCreation
                          ? ` le ${formatDate(selectedAvis.dateCreation)}`
                          : ""}
                      </p>
                    </div>
                  </div>

                  <div className="rounded-xl border border-border bg-muted/20 p-4 space-y-3">
                    <div className="flex items-center justify-between gap-3">
                      <span className="text-sm text-muted-foreground">Note donnée</span>
                      <StarRating rating={selectedAvis.note} size="sm" showCount />
                    </div>
                    <div>
                      <span className="text-sm text-muted-foreground block mb-1">Commentaire</span>
                      <p className="text-sm leading-relaxed whitespace-pre-line">
                        {selectedAvis.commentaire ?? selectedAvis.cmt ?? "Aucun commentaire."}
                      </p>
                    </div>
                  </div>

                  <p className="text-xs text-muted-foreground">
                    Les avis exposent uniquement les données disponibles côté API.
                  </p>
                </div>
              );
            })()}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AvisSection;
