// src/components/Testimonials.tsx
import { Star } from "lucide-react";
import { motion } from "framer-motion";
import { useLanguage } from "@/contexts/LanguageContext"; //

// Conservation de vos données d'origine[cite: 10]
const testimonials = [
  {
    id: 1,
    name: "Mohammed Ali",
    role: "Vendeur de voitures",
    image: "https://picsum.photos/100/100?random=13",
    text: "MARCHÉ a transformé mon business. J'ai vendu plus de 50 voitures en 6 mois!",
    rating: 5,
  },
  {
    id: 2,
    name: "Fatima Ben",
    role: "Acheteuse régulière",
    image: "https://picsum.photos/100/100?random=14",
    text: "Interface intuitive et transactions sécurisées. Très satisfaite!",
    rating: 5,
  },
  {
    id: 3,
    name: "Hassan Rachid",
    role: "Agent immobilier",
    image: "https://picsum.photos/100/100?random=15",
    text: "Plateforme fiable avec une excellente visibilité. Recommandé!",
    rating: 4,
  },
];

const Testimonials = () => {
  const { t } = useLanguage(); //[cite: 10]

  // Variantes d'animation pour l'apparition en cascade de la grille au chargement
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.15,
      },
    },
  };

  const cardVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: { 
      opacity: 1, 
      y: 0, 
      transition: { type: "spring", stiffness: 100, damping: 15 } 
    },
  };

  return (
    <section className="py-20 bg-gradient-to-b from-transparent to-secondary/5">
      <div className="container px-4 mx-auto">
        {/* Titre principal */}
        <h2 className="text-3xl md:text-4xl font-heading font-extrabold text-center mb-4 text-foreground">
          {t("testimonials_title")} {/*[cite: 10] */}
        </h2>
        <p className="text-center text-muted-foreground max-w-lg mx-auto mb-16">
          Découvrez les retours d'expérience des membres de notre communauté à travers le Maroc.
        </p>

        {/* GRILLE HORIZONTALE (3 colonnes sur PC, 1 sur mobile) */}
        <motion.div 
          className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
        >
          {testimonials.map((item) => (
            <motion.div
              key={item.id}
              variants={cardVariants}
              /* 
                Application de notre classe magique "interactive-card" 
                et de "group" pour synchroniser les animations internes au survol
              */
              className="interactive-card group rounded-2xl p-8 border border-secondary/15 flex flex-col justify-between cursor-pointer"
            >
              <div>
                {/* Étoiles de notation colorées et animées */}
                <div className="flex gap-1 mb-6">
                  {Array(item.rating)
                    .fill(0)
                    .map((_, i) => (
                      <Star 
                        key={i} 
                        className="h-4 w-4 fill-yellow-500 text-yellow-500 transition-transform duration-300 group-hover:scale-110" 
                      />
                    ))}
                </div>

                {/* Message du témoignage */}
                <p className="text-base text-muted-foreground leading-relaxed italic mb-8 relative z-10">
                  "{item.text}"
                </p>
              </div>

              {/* Pied de la carte (Auteur) */}
              <div className="flex items-center gap-4 mt-auto border-t border-secondary/10 pt-6">
                
                {/* Image de profil avec zoom à scale(1.05) sur 500ms */}
                <div className="w-12 h-12 rounded-full overflow-hidden shrink-0 border border-secondary/25">
                  <img
                    src={item.image}
                    alt={item.name}
                    className="w-full h-full object-cover transition-transform duration-500 ease-out group-hover:scale-105"
                  />
                </div>

                {/* Identité avec transition de couleur Teal au survol du bloc */}
                <div className="text-left">
                  <p className="font-bold text-foreground transition-colors duration-300 group-hover:text-teal-600">
                    {item.name}
                  </p>
                  <p className="text-xs text-muted-foreground font-medium">
                    {item.role}
                  </p>
                </div>

              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};

export default Testimonials;