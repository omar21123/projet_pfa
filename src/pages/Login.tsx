// src/pages/Login.tsx
import { Link, useLocation, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/contexts";
import { useLanguage } from "@/contexts/LanguageContext";
import { useAuthForm } from "@/features/auth";
import { Mail, Lock, ArrowRight } from "lucide-react";
import axios from "axios";
import AuthLayout from "./Authlayout";

// Déclaration pour TypeScript afin de reconnaître l'objet global Google Identity
declare global {
  interface Window {
    google?: any;
  }
}

const Login = () => {
  const [showPwd, setShowPwd] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [isBlocked, setIsBlocked] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);
  const intervalRef = useRef<number | null>(null);

  const navigate = useNavigate();
  const location = useLocation();
  const { login, loginWithGoogle } = useAuth(); // 💡 Utilisation de notre nouvelle méthode
  const { t } = useLanguage();

  const { values, error, isLoading, setEmail, setPassword, setError } = useAuthForm();

  const validateEmail = (email: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

  // 💡 CHARGEMENT ET INITIALISATION DE GOOGLE IDENTITY SERVICES
  useEffect(() => {
    // 1. Injection du script officiel Google
    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.async = true;
    script.defer = true;
    document.head.appendChild(script);

    script.onload = () => {
      if (window.google) {
        // 2. Initialisation avec votre Client ID Google (À remplacer idéalement par une variable d'environnement)
        window.google.accounts.id.initialize({
          client_id: "VOTRE_CLIENT_ID_GOOGLE_DE_LA_CONSOLE.apps.googleusercontent.com",
          callback: handleGoogleCredentialResponse,
        });

        // 3. Rendu automatique du bouton Google officiel dans notre container
        window.google.accounts.id.renderButton(
          document.getElementById("google-button-div"),
          { 
            theme: "outline", 
            size: "large", 
            width: "100%", 
            text: "continue_with",
            shape: "square" 
          }
        );
      }
    };

    return () => {
      // Nettoyage à la destruction du composant
      const scriptElement = document.querySelector('script[src="https://accounts.google.com/gsi/client"]');
      if (scriptElement) document.head.removeChild(scriptElement);
    };
  }, []);

  // 💡 CALLBACK APRÈS SÉLECTION DU COMPTE GOOGLE
  const handleGoogleCredentialResponse = async (response: any) => {
    setIsGoogleLoading(true);
    setError("");
    setErrorMessage("");

    try {
      // response.credential contient l'id_token JWT généré par Google !
      const idToken = response.credential;
      
      // Envoi de l'id_token à votre API Laravel (Rôle par défaut: CUSTOMER comme spécifié sur votre schéma)
      const authResponse = await loginWithGoogle(idToken, "CUSTOMER");
      
      // Redirection selon la réponse reçue de votre serveur
      navigate(authResponse.role === "ADMIN" ? "/admin/vendors" : "/");
    } catch (err) {
      console.error("Échec auth Google:", err);
    } finally {
      setIsGoogleLoading(false);
    }
  };

  // Cooldown de brute-force (429)
  useEffect(() => {
    if (countdown <= 0) return;
    intervalRef.current = window.setInterval(() => {
      setCountdown((c) => {
        if (c <= 1) {
          setIsBlocked(false);
          setErrorMessage("");
          return 0;
        }
        return c - 1;
      });
    }, 1000);
    return () => clearInterval(intervalRef.current!);
  }, [countdown]);

  // Connexion Classique (Email/Password)
  const handleLogin = async () => {
    if (isBlocked) return;
    setError("");
    setErrorMessage("");

    if (!values.email || !values.password) {
      setError(t("fill_all_fields"));
      return;
    }

    if (!validateEmail(values.email)) {
      setError(t("invalid_email"));
      return;
    }

    try {
      const response = await login(values.email, values.password);
      navigate(response.role === "ADMIN" ? "/admin/vendors" : "/");
    } catch (err: unknown) {
      if (axios.isAxiosError(err)) {
        const status = err.response?.status;

        if (status === 429) {
          setIsBlocked(true);
          setCountdown(60);
          setErrorMessage("Trop de tentatives. Veuillez patienter 60s.");
          return;
        }

        const data = err.response?.data;
        if (data?.errors && typeof data.errors === "object") {
          const firstErrorArray = Object.values(data.errors)[0];
          if (Array.isArray(firstErrorArray) && firstErrorArray.length > 0) {
            setErrorMessage(firstErrorArray[0] as string);
            return;
          }
        }

        setErrorMessage(data?.message ?? "Email ou mot de passe incorrect.");
      } else {
        setErrorMessage(err instanceof Error ? err.message : "Une erreur imprévue est survenue.");
      }
    }
  };

  return (
    <AuthLayout
      eyebrow="Espace membre"
      title={
        <>
          Bienvenue,
          <br />
          <span className="text-[#d09a3f]">bon retour.</span>
        </>
      }
      description="Marché est la marketplace marocaine qui connecte fournisseurs vérifiés et acheteurs exigeants. Connectez-vous pour continuer."
      stats={[
        { k: "12k+", v: "produits actifs" },
        { k: "480+", v: "vendeurs vérifiés" },
        { k: "24 / 7", v: "modération" },
      ]}
    >
      <div className="mb-8">
        <h2 className="text-3xl font-black tracking-tight text-slate-900">Se connecter</h2>
        <p className="mt-2 text-sm text-slate-500 leading-relaxed">
          Heureux de vous revoir parmi nous.
        </p>
      </div>

      <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
        <AnimatePresence mode="wait">
          {(errorMessage || error) && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              role="alert"
              className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-3 font-medium flex items-center gap-2 border border-red-100"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
              {errorMessage || error}
            </motion.div>
          )}
        </AnimatePresence>

        <div>
          <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
            {t("email")}
          </label>
          <div className="mt-1.5 relative">
            <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
            <input
              type="email"
              value={values.email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isBlocked || isGoogleLoading}
              placeholder="vous@marche.ma"
              className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition disabled:opacity-50"
            />
          </div>
        </div>

        <div>
          <div className="flex items-center justify-between">
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              {t("password")}
            </label>
            <button
              type="button"
              className="text-xs text-slate-500 hover:text-slate-900 hover:underline transition-colors"
            >
              Oublié ?
            </button>
          </div>
          <div className="mt-1.5 relative">
            <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
            <input
              type={showPwd ? "text" : "password"}
              value={values.password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isBlocked || isGoogleLoading}
              placeholder="••••••••"
              className="w-full h-12 pl-10 pr-12 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition disabled:opacity-50"
            />
            <button
              type="button"
              onClick={() => setShowPwd((v) => !v)}
              className="absolute right-2 top-1/2 -translate-y-1/2 size-8 rounded-lg text-slate-400 hover:text-slate-900 hover:bg-slate-100 flex items-center justify-center transition-all"
            >
              <span className="text-[10px] font-bold uppercase tracking-wider">
                {showPwd ? "Cache" : "Voir"}
              </span>
            </button>
          </div>
        </div>

        <button
          type="button"
          onClick={handleLogin}
          disabled={isLoading || isBlocked || isGoogleLoading}
          className="w-full h-12 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md active:scale-[0.99] gap-2 flex items-center justify-center disabled:opacity-50 text-sm"
        >
          {isBlocked ? (
            `Attendez ${countdown}s`
          ) : isLoading ? (
            <div className="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              Se connecter
              <ArrowRight className="size-4" />
            </>
          )}
        </button>

        <div className="flex items-center gap-4 py-2">
          <div className="flex-1 h-px bg-slate-200" />
          <span className="text-[10px] font-bold uppercase tracking-widest text-slate-400">ou</span>
          <div className="flex-1 h-px bg-slate-200" />
        </div>

        {/* 💡 CONTENANT DU BOUTON GOOGLE OFFICIEL GIS */}
        <div className="w-full min-h-[48px] relative flex justify-center items-center">
          {isGoogleLoading && (
            <div className="absolute inset-0 z-10 bg-white/80 flex items-center justify-center rounded-xl">
              <div className="h-5 w-5 border-2 border-[#2c3e50]/20 border-t-[#2c3e50] rounded-full animate-spin" />
            </div>
          )}
          <div id="google-button-div" className="w-full overflow-hidden rounded-xl" />
        </div>

        <p className="text-xs text-slate-500 text-center pt-4 font-medium">
          Nouveau sur Marché ?{" "}
          <Link to="/register" className="text-slate-900 font-bold hover:underline ml-1">
            Créer un compte
          </Link>
        </p>
      </form>
    </AuthLayout>
  );
};

export default Login;