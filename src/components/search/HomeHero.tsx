// Home marketing hero without search concerns.
import React from "react";
import {
  ArrowRight,
  Zap,
  Store,
  Truck,
  ShieldCheck,
  BadgeCheck,
  RotateCcw,
} from "lucide-react";
import { useNavigate } from "react-router-dom";

const HomeHero: React.FC = () => {
  const navigate = useNavigate();

  return (
    <section className="py-8 px-4 max-w-7xl mx-auto">
      {/* 1. Grille principale */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* CARTE PRINCIPALE */}
        <div className="lg:col-span-2 relative rounded-3xl overflow-hidden bg-white dark:bg-slate-900 min-h-[420px] md:min-h-[480px] flex flex-col justify-between p-8 md:p-12 shadow-sm border border-slate-200 dark:border-slate-800/50 transition-colors duration-300">
          <div className="absolute inset-0 z-0">
            <img src="/home.jpg" alt="Background" className="w-full h-full object-cover" />
            <div className="absolute inset-0 bg-slate-400/20 dark:bg-slate-900/40" />
          </div>

          <div className="relative z-10 flex flex-col gap-2 max-w-xl">
            <span className="text-xs font-bold uppercase tracking-widest text-slate-700 dark:text-slate-300 bg-white/70 dark:bg-slate-900/60 px-3 py-1 rounded-full w-fit backdrop-blur-sm border border-slate-200/50 dark:border-slate-700/50">
              Nouvelle Saison
            </span>
            <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight text-slate-900 dark:text-white leading-tight mt-2 drop-shadow-sm">
              Milliers de produits, un seul marché.
            </h1>
            <p className="text-sm md:text-base text-slate-800 dark:text-slate-200 mt-2 leading-relaxed font-medium">
              Découvrez les sélections de nos vendeurs certifiés — livraison rapide, paiement
              sécurisé, retours faciles.
            </p>

          </div>

          {/* Action Buttons */}
          <div className="relative z-10 flex flex-wrap gap-4 mt-8">
            <button
              type="button"
              onClick={() => navigate("/search")}
              className="btn bg-slate-900 text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
            >
              Explorer le catalogue <ArrowRight className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => navigate("/vendors")}
              className="btn border border-slate-300 text-slate-900 bg-white/50 backdrop-blur-sm hover:bg-slate-100 dark:border-white/30 dark:text-white dark:hover:bg-white/10"
            >
              Nos vendeurs
            </button>
          </div>
        </div>

        {/* COLONNE DE DROITE */}
        <div className="flex flex-col gap-6">
          <div className="lift bg-ink text-cream p-6 rounded-3xl border border-transparent flex flex-col justify-between min-h-[180px] md:min-h-[208px] shadow-sm">
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-1.5 text-promo font-bold text-xs uppercase tracking-wider">
                <Zap className="h-4 w-4 fill-current animate-pulse" />
                Ventes Flash
              </div>
              <h2 className="text-4xl font-black mt-2">-40%</h2>
              <p className="text-sm opacity-60 mt-1">
                Sur la sélection high-tech, aujourd'hui uniquement.
              </p>
            </div>
            <a
              href="#"
              className="nav-link text-xs font-bold inline-flex items-center gap-1 mt-4 w-fit"
            >
              Voir les offres →
            </a>
          </div>

          <div className="lift bg-surface text-ink p-6 rounded-3xl border border-hairline shadow-sm flex flex-col justify-between min-h-[180px] md:min-h-[208px]">
            <div className="flex flex-col gap-2">
              <div className="h-10 w-10 rounded-xl bg-cream flex items-center justify-center border border-hairline">
                <Store className="h-5 w-5 text-teal" />
              </div>
              <h2 className="text-lg font-bold mt-2">Vendez sur Marché</h2>
              <p className="text-sm opacity-60">
                Ouvrez votre boutique et touchez des milliers d'acheteurs.
              </p>
            </div>
            <a
              href="/register"
              className="nav-link text-xs font-bold inline-flex items-center gap-1 mt-4 w-fit"
            >
              Devenir vendeur →
            </a>
          </div>
        </div>
      </div>

      {/* 2. BARRE DES ENGAGEMENTS */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mt-8 p-6 bg-cream/60 rounded-3xl border border-hairline">
        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <Truck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Livraison gratuite</h4>
            <p className="text-xs opacity-60">Dès 50€ d'achat</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <ShieldCheck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Paiement sécurisé</h4>
            <p className="text-xs opacity-60">100% protégé</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <BadgeCheck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Vendeurs certifiés</h4>
            <p className="text-xs opacity-60">Identité vérifiée</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <RotateCcw className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Retour 30 jours</h4>
            <p className="text-xs opacity-60">Satisfait ou remboursé</p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HomeHero;
