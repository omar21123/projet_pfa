import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft } from "lucide-react";

const BackButton = () => {
  return (
    <motion.div
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.5, delay: 0.2 }}
      className="fixed top-6 left-6 z-50"
    >
      <motion.div
        whileHover={{
          y: -2,
          scale: 1.05,
        }}
        whileTap={{ scale: 0.95 }}
        transition={{ type: "spring", stiffness: 400, damping: 17 }}
      >
        <Link
          to="/"
          className="group relative flex items-center justify-center w-12 h-12 rounded-2xl 
            backdrop-blur-xl bg-white/10 
            border border-white/20 shadow-lg 
            hover:bg-white/20 hover:border-white/30 
            transition-all duration-300"
          aria-label="Retour à l'accueil"
        >
          <motion.div
            initial={{ x: 0 }}
            whileHover={{ x: -3 }}
            transition={{ type: "spring", stiffness: 300, damping: 20 }}
          >
            <ArrowLeft className="w-5 h-5 text-white/90 group-hover:text-white" strokeWidth={2.5} />
          </motion.div>

          {/* Glow effect on hover */}
          <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-primary/20 to-purple-500/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-md" />
        </Link>
      </motion.div>
    </motion.div>
  );
};

export default BackButton;
