import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Home } from "lucide-react";
import type { ReactNode } from "react";

interface AuthStat {
  k: string;
  v: string;
}

interface AuthLayoutProps {
  /** Petit badge au-dessus du titre, ex: "Espace membre" */
  eyebrow: string;
  /** Titre principal du panneau gauche (peut contenir un <br /> + <span> coloré) */
  title: ReactNode;
  /** Texte descriptif sous le titre */
  description: string;
  /** Stats affichées en bas du panneau gauche (optionnel) */
  stats?: AuthStat[];
  /** Contenu de la colonne de droite (formulaire) */
  children: ReactNode;
}

/**
 * Layout partagé entre /login et /register.
 * Le panneau gauche (sombre) est paramétrable pour adapter le message
 * selon le contexte (connexion générique / inscription client / inscription fournisseur).
 */
const AuthLayout = ({ eyebrow, title, description, stats, children }: AuthLayoutProps) => {
  return (
    <div className="min-h-screen bg-[#f8f9fa] text-slate-900 grid lg:grid-cols-[1.1fr_1fr]">
      {/* Bouton Home fixe */}
      <div className="fixed top-6 left-6 z-50 lg:left-[calc(55%+24px)]">
        <Link to="/">
          <Button
            variant="ghost"
            className="gap-2 text-slate-500 hover:text-slate-900 hover:bg-slate-200/50 backdrop-blur-md transition-all rounded-full"
          >
            <Home size={16} />
            <span className="font-medium text-xs">← Retour à l'accueil</span>
          </Button>
        </Link>
      </div>

      {/* Panneau gauche immersif */}
      <aside className="relative hidden lg:flex flex-col justify-between p-12 bg-[#0d0f12] text-white overflow-hidden border-r border-white/5">
        {/* Glow ambre subtil */}
        <div
          aria-hidden
          className="absolute bottom-[-150px] left-[-50px] size-[600px] rounded-full blur-[140px] opacity-25"
          style={{
            background: "radial-gradient(circle at center, #d09a3f 0%, transparent 70%)",
          }}
        />
        {/* Grille fine */}
        <div
          aria-hidden
          className="absolute inset-0 opacity-[0.04]"
          style={{
            backgroundImage:
              "linear-gradient(to right, #ffffff 1px, transparent 1px), linear-gradient(to bottom, #ffffff 1px, transparent 1px)",
            backgroundSize: "44px 44px",
          }}
        />

        <div className="relative z-10">
          <Link to="/" className="text-2xl font-black tracking-wider text-white">
            MARCHÉ
          </Link>
        </div>

        <div className="relative z-10 max-w-lg my-auto">
          <span className="inline-flex items-center gap-2 rounded-full bg-white/5 border border-white/10 px-3.5 py-1 text-[11px] font-medium tracking-wider text-white/70 uppercase">
            <span className="size-1.5 rounded-full bg-[#d09a3f]" />
            {eyebrow}
          </span>
          <h1 className="mt-6 font-extrabold leading-[1.15] text-[46px] xl:text-[54px] tracking-tight">
            {title}
          </h1>
          <p className="mt-5 text-slate-400 text-sm leading-relaxed max-w-md">{description}</p>
        </div>

        {stats && stats.length > 0 && (
          <div className="relative z-10 grid grid-cols-3 gap-4 max-w-xl">
            {stats.map((s) => (
              <div
                key={s.v}
                className="rounded-xl bg-white/[0.02] border border-white/5 p-4 backdrop-blur-sm transition-all duration-300 hover:bg-white/[0.07] hover:border-white/15 hover:shadow-[0_8px_32px_rgba(0,0,0,0.3)]"
              >
                <div className="text-xl font-black text-[#d09a3f] tracking-tight">{s.k}</div>
                <div className="mt-1 text-[10px] uppercase font-bold tracking-widest text-slate-500">
                  {s.v}
                </div>
              </div>
            ))}
          </div>
        )}
      </aside>

      {/* Panneau droit (formulaire) */}
      <main className="flex flex-col bg-[#fdfdfd]">
        <header className="lg:hidden bg-[#0d0f12] p-4 flex items-center justify-between">
          <Link to="/" className="text-xl font-black tracking-wider text-white">
            MARCHÉ
          </Link>
        </header>

        <div className="flex-1 flex items-center justify-center px-6 sm:px-12 py-16">
          <div className="w-full max-w-[420px]">{children}</div>
        </div>
      </main>
    </div>
  );
};

export default AuthLayout;