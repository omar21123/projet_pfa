import { useState } from "react";
import { FaFacebookF, FaLink, FaShareNodes, FaWhatsapp, FaEnvelope } from "react-icons/fa6";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { toast } from "@/components/ui/use-toast";
import { cn } from "@/lib/utils";

type ShareButtonsProps = {
  title: string;
  description?: string;
  url?: string;
  className?: string;
  triggerClassName?: string;
  menuAlign?: "start" | "center" | "end";
  showLabel?: boolean;
};

const getShareUrl = (url?: string) => {
  if (url) {
    return url;
  }

  if (typeof window !== "undefined") {
    return window.location.href;
  }

  return "";
};

const openInNewTab = (targetUrl: string) => {
  window.open(targetUrl, "_blank", "noopener,noreferrer");
};

const buildShareMessage = (title: string, shareUrl: string, description?: string) =>
  [title, description, shareUrl].filter(Boolean).join("\n\n");

const isAbortError = (error: unknown) => {
  return error instanceof DOMException && error.name === "AbortError";
};

export function ShareButtons({
  title,
  description,
  url,
  className,
  triggerClassName,
  menuAlign = "end",
  showLabel = false,
}: ShareButtonsProps) {
  const [isCopying, setIsCopying] = useState(false);

  const handleShare = async () => {
    const shareUrl = getShareUrl(url);

    if (!shareUrl) {
      toast({
        title: "Partage indisponible",
        description: "Impossible de récupérer l'URL de cette annonce.",
        variant: "destructive",
      });
      return;
    }

    const shareData = {
      title,
      text: description ? `${title}\n\n${description}` : title,
      url: shareUrl,
    };

    if (typeof navigator !== "undefined" && typeof navigator.share === "function") {
      try {
        await navigator.share(shareData);
        return;
      } catch (error) {
        if (isAbortError(error)) {
          return;
        }
      }
    }

    toast({
      title: "Partage non disponible",
      description: "La fonction de partage native n'est pas disponible sur cet appareil.",
    });
  };

  const handleWhatsAppShare = () => {
    const shareUrl = getShareUrl(url);

    if (!shareUrl) {
      toast({
        title: "Erreur de partage",
        description: "Impossible de générer le lien à partager.",
        variant: "destructive",
      });
      return;
    }

    const message = buildShareMessage(title, shareUrl, description);
    openInNewTab(`https://wa.me/?text=${encodeURIComponent(message)}`);
  };

  const handleFacebookShare = () => {
    const shareUrl = getShareUrl(url);

    if (!shareUrl) {
      toast({
        title: "Erreur de partage",
        description: "Impossible de générer le lien à partager.",
        variant: "destructive",
      });
      return;
    }

    openInNewTab(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(shareUrl)}`);
  };

  const handleEmailShare = () => {
    const shareUrl = getShareUrl(url);

    if (!shareUrl) {
      toast({
        title: "Erreur de partage",
        description: "Impossible de générer le lien à partager.",
        variant: "destructive",
      });
      return;
    }

    const subject = `Annonce à partager: ${title}`;
    const body = buildShareMessage(title, shareUrl, description);
    openInNewTab(`mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`);
  };

  const handleCopyLink = async () => {
    const shareUrl = getShareUrl(url);

    if (!shareUrl) {
      toast({
        title: "Erreur de copie",
        description: "Impossible de récupérer l'URL actuelle.",
        variant: "destructive",
      });
      return;
    }

    try {
      setIsCopying(true);
      await navigator.clipboard.writeText(shareUrl);
      toast({
        title: "Lien copié",
        description: "Le lien de l'annonce a été copié dans le presse-papiers.",
      });
    } catch {
      toast({
        title: "Copie impossible",
        description: "Votre navigateur a bloqué l'accès au presse-papiers.",
        variant: "destructive",
      });
    } finally {
      setIsCopying(false);
    }
  };

  const canUseNativeShare =
    typeof navigator !== "undefined" && typeof navigator.share === "function";

  return (
    <div className={cn("inline-flex", className)}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            type="button"
            variant="outline"
            size={showLabel ? "default" : "icon"}
            className={cn(
              "h-12 rounded-xl border-secondary/30 bg-background/90 shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:bg-secondary/10 hover:shadow-md focus-visible:ring-2 focus-visible:ring-primary/20",
              showLabel && "px-4",
              triggerClassName,
            )}
            aria-label="Ouvrir le menu de partage"
          >
            <FaShareNodes className="h-4 w-4" />
            {showLabel ? <span className="text-sm font-medium">Partager</span> : null}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent
          align={menuAlign}
          sideOffset={10}
          className="w-[calc(100vw-2rem)] max-w-sm rounded-2xl border border-border/70 bg-background/95 p-2 shadow-2xl backdrop-blur-md data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 sm:w-80"
        >
          <DropdownMenuLabel className="px-3 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
            Partager l'annonce
          </DropdownMenuLabel>
          <DropdownMenuSeparator />

          {canUseNativeShare ? (
            <DropdownMenuItem
              className="group flex cursor-pointer items-start gap-3 rounded-xl px-3 py-3 text-sm outline-none transition-colors focus:bg-primary/8 focus:text-foreground"
              onSelect={() => {
                void handleShare();
              }}
            >
              <span className="mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary transition-transform group-hover:scale-105">
                <FaShareNodes className="h-4 w-4" />
              </span>
              <span className="flex-1">
                <span className="block font-medium">Partager sur l'appareil</span>
                <span className="block text-xs text-muted-foreground">
                  Utilise le menu natif du téléphone
                </span>
              </span>
            </DropdownMenuItem>
          ) : null}

          <DropdownMenuItem
            className="group flex cursor-pointer items-start gap-3 rounded-xl px-3 py-3 text-sm outline-none transition-colors focus:bg-[#25D366]/10 focus:text-foreground"
            onSelect={() => {
              handleWhatsAppShare();
            }}
          >
            <span className="mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#25D366]/10 text-[#25D366] transition-transform group-hover:scale-105">
              <FaWhatsapp className="h-4 w-4" />
            </span>
            <span className="flex-1">
              <span className="block font-medium">WhatsApp</span>
              <span className="block text-xs text-muted-foreground">
                Partager le lien avec vos contacts
              </span>
            </span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className="group flex cursor-pointer items-start gap-3 rounded-xl px-3 py-3 text-sm outline-none transition-colors focus:bg-[#1877F2]/10 focus:text-foreground"
            onSelect={() => {
              handleFacebookShare();
            }}
          >
            <span className="mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#1877F2]/10 text-[#1877F2] transition-transform group-hover:scale-105">
              <FaFacebookF className="h-4 w-4" />
            </span>
            <span className="flex-1">
              <span className="block font-medium">Facebook</span>
              <span className="block text-xs text-muted-foreground">
                Ouvrir le partage Facebook
              </span>
            </span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className="group flex cursor-pointer items-start gap-3 rounded-xl px-3 py-3 text-sm outline-none transition-colors focus:bg-secondary/10 focus:text-foreground"
            onSelect={() => {
              handleEmailShare();
            }}
          >
            <span className="mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-secondary/10 text-secondary transition-transform group-hover:scale-105">
              <FaEnvelope className="h-4 w-4" />
            </span>
            <span className="flex-1">
              <span className="block font-medium">Email</span>
              <span className="block text-xs text-muted-foreground">
                Pré-remplir un nouveau message
              </span>
            </span>
          </DropdownMenuItem>

          <DropdownMenuItem
            className="group flex cursor-pointer items-start gap-3 rounded-xl px-3 py-3 text-sm outline-none transition-colors focus:bg-accent focus:text-foreground"
            onSelect={() => {
              void handleCopyLink();
            }}
            disabled={isCopying}
          >
            <span className="mt-0.5 inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-accent/80 text-foreground transition-transform group-hover:scale-105">
              <FaLink className="h-4 w-4" />
            </span>
            <span className="flex-1">
              <span className="block font-medium">Copier le lien</span>
              <span className="block text-xs text-muted-foreground">
                Copie automatiquement l'URL de l'annonce
              </span>
            </span>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}

export default ShareButtons;
