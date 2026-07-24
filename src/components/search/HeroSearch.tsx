import { ArrowRight, Zap, Store, Truck, ShieldCheck, BadgeCheck, RotateCcw } from "lucide-react";
import RegisterVendorForm from "@/pages/Registervendorform";

const HeroSearch = () => {
  return (
    <section className="py-8 px-4 max-w-7xl mx-auto">
      {/* 1. Grille principale */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* ================= CARTE PRINCIPALE
              Light mode  : claire et lumineuse (image visible, voile léger côté texte)
              Dark mode   : reste sombre et cinématique (voile marqué)
              → couleurs volontairement explicites (dark:) plutôt que tokens auto-inversants,
                car cette carte a un traitement asymétrique, pas un simple miroir clair/sombre. */}
        <div className="lg:col-span-2 relative rounded-3xl overflow-hidden bg-white dark:bg-slate-900 min-h-[380px] md:min-h-[440px] flex flex-col justify-between p-8 md:p-12 shadow-sm border border-slate-200 dark:border-slate-800/50 transition-colors duration-300">
          <div className="absolute inset-0 z-0">
            <img src="public/home.jpg" alt="Background" className="w-full h-full object-cover" />
            {/* Overlay léger qui s'adapte au mode */}
            <div className="absolute inset-0 bg-slate-400/20 dark:bg-slate-900/40" />
          </div>

          <div className="relative z-10 flex flex-col gap-2 max-w-lg">
            <span className="text-xs font-bold uppercase tracking-widest text-slate-600 dark:text-slate-400">
              Nouvelle Saison
            </span>
            <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight text-slate-900 dark:text-white leading-tight mt-2">
              Milliers de produits, un seul marché.
            </h1>
            <p className="text-sm md:text-base text-slate-700 dark:text-slate-300 mt-4 leading-relaxed">
              Découvrez les sélections de nos vendeurs certifiés — livraison rapide, paiement
              sécurisé, retours faciles.
            </p>
          </div>

          {/* Boutons : sombres sur fond clair en light mode, clairs sur fond sombre en dark mode.
              Couleurs explicites (pas .btn-cream/.btn-dark) car le fond de cette carte
              n'est plus fixe — .btn garde juste la mécanique (lift + reflet + enfoncement). */}
          <div className="relative z-10 flex flex-wrap gap-4 mt-8">
            <button
              type="button"
              className="btn bg-slate-900 text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
            >
              Explorer le catalogue <ArrowRight className="h-4 w-4" />
            </button>
            <button
              type="button"
              className="btn border border-slate-300 text-slate-900 bg-transparent hover:bg-slate-100 dark:border-white/30 dark:text-white dark:hover:bg-white/10"
            >
              Nos vendeurs
            </button>
          </div>
        </div>

        {/* ================= COLONNE DE DROITE (1/3) ================= */}
        <div className="flex flex-col gap-6">
          {/* CARTE HAUT : Ventes Flash
              bg-ink / text-cream s'inversent automatiquement entre les modes :
              sombre en light mode, clair-crème en dark mode — sans dark: */}
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

          {/* CARTE BAS : Vendez sur Marché
              bg-surface / text-ink s'inversent aussi automatiquement */}
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

      {/* ================= 2. BARRE DES ENGAGEMENTS ================= */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mt-8 p-6 bg-cream/60 rounded-3xl border border-hairline">
        {/* Engagement 1 : Livraison */}
        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <Truck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Livraison gratuite</h4>
            <p className="text-xs opacity-60">Dès 50€ d'achat</p>
          </div>
        </div>

        {/* Engagement 2 : Paiement */}
        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <ShieldCheck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Paiement sécurisé</h4>
            <p className="text-xs opacity-60">100% protégé</p>
          </div>
        </div>

        {/* Engagement 3 : Certifications */}
        <div className="flex items-center gap-4">
          <div className="lift h-12 w-12 rounded-full bg-surface flex items-center justify-center shadow-sm border border-hairline shrink-0">
            <BadgeCheck className="h-5 w-5 text-teal" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-ink">Vendeurs certifiés</h4>
            <p className="text-xs opacity-60">Identité vérifiée</p>
          </div>
        </div>

        {/* Engagement 4 : Retours */}
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

export default HeroSearch;
