// src/components/auth/Login.tsx
import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { GoogleLogin } from "@react-oauth/google";
import { Button } from "@/components/ui/button";
import { Mail, Lock, ArrowRight } from "lucide-react";
import { useAuth } from "@/contexts"; // 👈 Import du hook d'authentification
import AuthLayout from "./Authlayout";

const PANEL_CONTENT = {
  eyebrow: "Bon retour",
  title: (
    <>
      Connectez-vous à <br />
      <span className="text-[#d09a3f]">votre espace.</span>
    </>
  ),
  description:
    "Accédez à vos commandes, vos ventes et votre tableau de bord personnalisé en toute sécurité.",
  stats: [
    { k: "100%", v: "sécurisé" },
    { k: "24/7", v: "accès direct" },
    { k: "480+", v: "vendeurs actifs" },
  ],
};

const Login = () => {
  const navigate = useNavigate();
  // 👈 Récupération des méthodes centralisées de AuthContext
  const { login, loginWithGoogle } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  /**
   * Gestion centralisée des redirections après connexion réussie
   */
  const handleAuthSuccess = (response: {
    requires_onboarding?: boolean;
    role?: string | string[] | null;
  }) => {
    if (response.requires_onboarding) {
      navigate("/complete-profile");
      return;
    }

    if (response.role === "VENDOR") {
      navigate("/vendor/dashboard");
    } else {
      navigate("/");
    }
  };

  /**
   * Connexion classique Email / Mot de passe via AuthContext
   */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Veuillez remplir tous les champs.");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      // 🟢 Utilisation de login() du AuthContext (met à jour le state React immédiatement)
      const response = await login(email, password);
      handleAuthSuccess(response);
    } catch (err: any) {
      setError(
        err.response?.data?.message ||
          "Identifiants invalides. Veuillez réessayer."
      );
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Connexion via Google OAuth via AuthContext
   */
  const handleGoogleSuccess = async (credentialResponse: any) => {
    if (!credentialResponse.credential) {
      setError("Échec de l'authentification Google.");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      // 🟢 Utilisation de loginWithGoogle() du AuthContext (met à jour le state React immédiatement)
      const response = await loginWithGoogle(credentialResponse.credential);
      handleAuthSuccess(response);
    } catch (err: any) {
      setError(
        err.response?.data?.message ||
          "Erreur lors de la connexion avec Google."
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout
      eyebrow={PANEL_CONTENT.eyebrow}
      title={PANEL_CONTENT.title}
      description={PANEL_CONTENT.description}
      stats={PANEL_CONTENT.stats}
    >
      <div>
        <div className="mb-8">
          <h2 className="text-3xl font-black tracking-tight text-slate-900">
            Se connecter
          </h2>
          <p className="mt-2 text-sm text-slate-500 leading-relaxed">
            Entrez vos identifiants pour accéder à votre compte.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <AnimatePresence mode="wait">
            {error && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                role="alert"
                className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-3 font-medium flex items-center gap-2 border border-red-100"
              >
                <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
                {error}
              </motion.div>
            )}
          </AnimatePresence>

          <div>
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              Email
            </label>
            <div className="mt-1.5 relative">
              <Mail
                className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                size={15}
              />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="vous@marche.ma"
                className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
              />
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center">
              <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                Mot de passe
              </label>
              <Link
                to="/forgot-password"
                className="text-xs font-semibold text-slate-500 hover:text-slate-900 transition-colors"
              >
                Mot de passe oublié ?
              </Link>
            </div>
            <div className="mt-1.5 relative">
              <Lock
                className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                size={15}
              />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
              />
            </div>
          </div>

          <Button
            type="submit"
            disabled={isLoading}
            className="w-full h-12 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md active:scale-[0.99] gap-2 flex items-center justify-center disabled:opacity-50"
          >
            {isLoading ? (
              <div className="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                Se connecter
                <ArrowRight className="size-4" />
              </>
            )}
          </Button>
        </form>

        {/* Séparateur */}
        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-slate-200" />
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-[#f8fafc] px-3 font-semibold text-slate-400">
              Ou continuer avec
            </span>
          </div>
        </div>

        {/* Bouton Google Sign-In */}
        <div className="flex justify-center w-full">
          <GoogleLogin
            onSuccess={handleGoogleSuccess}
            onError={() => setError("Erreur lors de la connexion Google.")}
            theme="outline"
            shape="rectangular"
            width="100%"
          />
        </div>

        <p className="text-xs text-slate-500 text-center pt-6 font-medium">
          Pas encore de compte ?{" "}
          <Link
            to="/register"
            className="text-slate-900 font-bold hover:underline ml-1"
          >
            S'inscrire
          </Link>
        </p>
      </div>
    </AuthLayout>
  );
};

export default Login;