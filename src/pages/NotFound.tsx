import { Link, useLocation } from "react-router-dom";
import { motion } from "framer-motion";
import { useEffect } from "react";
import { useLanguage } from "@/contexts/LanguageContext";
import { Home, ChevronLeft } from "lucide-react";

const NotFound = () => {
  const location = useLocation();
  const { t } = useLanguage();

  useEffect(() => {
    console.error("404 Error:", location.pathname);
  }, [location.pathname]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4 }}
      className="flex min-h-screen items-center justify-center bg-muted px-4"
    >
      <div className="text-center max-w-md">
        {/* Illustration */}
        <div className="mb-6 flex justify-center">
          <svg width="180" height="120" viewBox="0 0 180 120" fill="none">
            {/* ... même SVG que ci-dessus ... */}
          </svg>
        </div>

        {/* 404 */}
        <h1 className="text-8xl font-medium tracking-tighter mb-2">
          4<span className="text-violet-600">0</span>4
        </h1>

        <p className="text-xl font-medium mb-2">{t("page_not_found")}</p>
        <p className="text-sm text-muted-foreground mb-8">{t("page_not_found_desc")}</p>

        {/* Boutons */}
        <div className="flex gap-3 justify-center flex-wrap">
          <Link
            to="/"
            className="inline-flex items-center gap-2 bg-violet-600 text-white rounded-lg px-5 py-2.5 text-sm font-medium hover:bg-violet-700 transition-colors"
          >
            <Home size={16} />
            {t("return_home")}
          </Link>
          <button
            onClick={() => history.back()}
            className="inline-flex items-center gap-2 bg-background border border-border rounded-lg px-5 py-2.5 text-sm font-medium hover:bg-muted transition-colors"
          >
            <ChevronLeft size={16} />
            {t("go_back")}
          </button>
        </div>

        <p className="text-xs text-muted-foreground mt-8">
          Code d'erreur : <code className="bg-muted px-1.5 py-0.5 rounded text-xs">HTTP 404</code>
        </p>
      </div>
    </motion.div>
  );
};

export default NotFound;
