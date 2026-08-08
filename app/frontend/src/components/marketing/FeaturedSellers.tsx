import { Star, ShieldCheck } from "lucide-react";
import { motion } from "framer-motion";

// Les données exactes de votre capture d'écran !
const sellers = [
  {
    id: 1,
    name: "Sonora Pro",
    category: "Audio & Hi-Fi",
    initial: "S",
    rating: "4.9",
    sales: "12.4k ventes",
    city: "Casablanca",
  },
  {
    id: 2,
    name: "Maison Terra",
    category: "Art de vivre",
    initial: "M",
    rating: "4.8",
    sales: "8.1k ventes",
    city: "Marrakech",
  },
  {
    id: 3,
    name: "Nomad Gear",
    category: "Voyage & Outdoor",
    initial: "N",
    rating: "4.7",
    sales: "3.9k ventes",
    city: "Rabat",
  },
  {
    id: 4,
    name: "Optique Pro",
    category: "Photo & Vidéo",
    initial: "O",
    rating: "4.9",
    sales: "1.2k ventes",
    city: "Tanger",
  },
];

const FeaturedSellers = () => {
  return (
    <section className="py-12 bg-transparent">
      <div className="max-w-7xl mx-auto px-4">
        {/* Grille horizontale de 4 colonnes (identique à l'image) */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {sellers.map((seller) => (
            <div
              key={seller.id}
              /* 
                1. "interactive-card" applique la physique élastique et le reflet 
                2. "group" permet de déclencher la transition du texte en Teal
              */
              className="interactive-card group bg-[#F9F9F9] rounded-2xl p-5 border border-slate-100/50 cursor-pointer flex flex-col justify-between"
            >
              {/* Partie haute : Logo (Initiale) + Textes */}
              <div className="flex items-center gap-4">
                
                {/* Carré bleu ardoise arrondi contenant la lettre blanche */}
                <div className="w-14 h-14 rounded-xl bg-[#344E5E] flex items-center justify-center shrink-0 shadow-inner">
                  <span className="text-white text-xl font-bold font-heading tracking-wide">
                    {seller.initial}
                  </span>
                </div>

                {/* Nom du vendeur et badge certifié */}
                <div className="flex flex-col min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="font-extrabold text-slate-800 text-[15px] tracking-tight truncate transition-colors duration-300 group-hover:text-teal-600">
                      {seller.name}
                    </span>
                    {/* Badge bouclier certifié discret */}
                    <ShieldCheck className="h-4 w-4 text-slate-400 shrink-0" />
                  </div>
                  <span className="text-xs text-slate-400 font-medium truncate mt-0.5">
                    {seller.category}
                  </span>
                </div>
              </div>

              {/* Ligne de séparation horizontale fine */}
              <div className="h-[1px] bg-slate-200/60 w-full my-4" />

              {/* Partie basse : Statistiques de vente (Étoile, ventes, ville) */}
              <div className="flex items-center justify-between text-xs font-semibold text-slate-400">
                {/* Note moyenne */}
                <div className="flex items-center gap-1">
                  <Star className="h-4 w-4 fill-amber-400 text-amber-400 shrink-0" />
                  <span className="text-slate-800 font-extrabold">{seller.rating}</span>
                </div>
                
                {/* Volume de ventes */}
                <span className="font-medium text-slate-400/90">{seller.sales}</span>
                
                {/* Ville d'activité */}
                <span className="font-medium text-slate-400/90">{seller.city}</span>
              </div>

            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeaturedSellers;