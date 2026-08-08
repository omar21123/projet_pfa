// src/pages/Login.tsx
import axios from "axios";
import React, { useState } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom";
import { jwtDecode } from "jwt-decode";
import { useAuth } from "@/contexts";
import AuthLayout from "@/pages/Authlayout";
import { Button } from "@/components/ui/button";
import { GoogleLogin } from "@react-oauth/google";
import { Loader2, Mail, Lock, ArrowRight } from "lucide-react";
import type { LaravelAuthResponse } from "@/types/users.types";

type LoginLocationState = {
  from?: {
    pathname?: string;
    search?: string;
    hash?: string;
  };
};

type TokenClaims = {
  role?: string | string[];
  roles?: string | string[];
};

const getRole = (response: LaravelAuthResponse): string | null => {
  const rawRole = response.role || response.user?.role || response.roles;
  const role = Array.isArray(rawRole) ? rawRole[0] : rawRole;

  if (typeof role === "string" && role) {
    return role.toUpperCase();
  }

  if (response.access_token) {
    try {
      const claims = jwtDecode<TokenClaims>(response.access_token);
      const tokenRole = claims.role || claims.roles;
      const resolvedRole = Array.isArray(tokenRole) ? tokenRole[0] : tokenRole;
      return typeof resolvedRole === "string" ? resolvedRole.toUpperCase() : null;
    } catch {
      return null;
    }
  }

  return null;
};

const getRequestedPath = (state: unknown): string | null => {
  if (!state || typeof state !== "object" || !("from" in state)) return null;

  const from = (state as LoginLocationState).from;
  if (!from?.pathname || !from.pathname.startsWith("/") || from.pathname.startsWith("//")) {
    return null;
  }

  return `${from.pathname}${from.search ?? ""}${from.hash ?? ""}`;
};

const getPostLoginPath = (role: string | null, requestedPath: string | null): string => {
  const isAdminPath = requestedPath === "/admin" || requestedPath?.startsWith("/admin/");
  const isVendorPath =
    requestedPath === "/my-ads" ||
    requestedPath?.startsWith("/vendor/") ||
    requestedPath?.startsWith("/products/");

  if (role === "ADMIN") return isAdminPath && requestedPath ? requestedPath : "/admin";
  if (role === "VENDOR") return isVendorPath && requestedPath ? requestedPath : "/vendor/dashboard";
  if (role === "CUSTOMER") return requestedPath && !isAdminPath && !isVendorPath ? requestedPath : "/";
  return requestedPath ?? "/";
};

export const Login: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { loginWithGoogle, login } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  /**
   * Gestion de la connexion via Google
   */
  const handleGoogleSuccess = async (credentialResponse: { credential?: string }) => {
    setIsLoading(true);
    setError("");

    try {
      const idToken = credentialResponse.credential;

      if (!idToken) {
        throw new Error("Impossible de récupérer le jeton Google.");
      }

      // 1. Appel API de connexion backend
      const response = await loginWithGoogle(idToken);

      // 2. Vérification du rôle existant
      const rawRole = response?.role || response?.user?.role || response?.roles;
      const userRole = Array.isArray(rawRole) ? rawRole[0] : rawRole;

      const requiresOnboarding = response.requires_onboarding;

      // 🟢 Si le rôle existe déjà et qu'aucun onboarding n'est requis
      if (userRole && !requiresOnboarding) {
        sessionStorage.removeItem("google_token");
        sessionStorage.removeItem("google_session_token");

        if (userRole === "VENDOR") {
          navigate("/vendor/dashboard");
        } else if (userRole === "ADMIN") {
          navigate("/admin");
        } else {
          navigate("/");
        }
      } else {
        // 🔴 Nouvel utilisateur : Redirection vers le choix du rôle
        sessionStorage.setItem("google_token", idToken);
        navigate("/complete-profile", {
          state: { googleToken: idToken },
        });
      }
    } catch (err: unknown) {
      console.error("Erreur lors de la connexion Google :", err);
      setError(
        (axios.isAxiosError(err) ? err.response?.data?.message : undefined) ||
          "Échec de la connexion avec Google. Veuillez réessayer."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleError = () => {
    setError("La connexion via Google a échoué ou a été annulée.");
  };

  /**
   * Connexion classique (Email / Mot de passe)
   */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    try {
      const response = await login(email, password);
      const role = getRole(response);
      const requestedPath = getRequestedPath(location.state);
      navigate(getPostLoginPath(role, requestedPath), { replace: true });
    } catch (err: unknown) {
      console.error("Erreur de connexion :", err);
      setError(
        (axios.isAxiosError(err) ? err.response?.data?.message : undefined) ||
          "Identifiants incorrects. Veuillez réessayer."
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout
      eyebrow="Bienvenue"
      title={
        <>
          Connectez-vous à <br />
          <span className="text-[#d09a3f]">votre compte.</span>
        </>
      }
      description="Accédez à votre espace personnel et gérez vos activités."
      stats={[
        { k: "100%", v: "Sécurisé" },
        { k: "Rapide", v: "< 1 minute" },
      ]}
    >
      <div className="space-y-6">
        {error && (
          <div className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-3 font-medium flex items-center gap-2 border border-red-100">
            <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
            {error}
          </div>
        )}

        {/* Bouton Officiel Google */}
        <div className="flex flex-col items-center justify-center w-full">
          <GoogleLogin
            onSuccess={handleGoogleSuccess}
            onError={handleGoogleError}
            useOneTap
            theme="outline"
            size="large"
            shape="pill"
            width="100%"
          />
        </div>

        <div className="relative flex py-2 items-center">
          <div className="flex-grow border-t border-slate-200" />
          <span className="flex-shrink mx-4 text-xs font-semibold uppercase tracking-wider text-slate-400">
            ou avec votre email
          </span>
          <div className="flex-grow border-t border-slate-200" />
        </div>

        {/* Formulaire Classique Email / Mot de passe */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              Adresse e-mail
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
                placeholder="exemple@domaine.com"
                className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
              />
            </div>
          </div>

          <div>
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              Mot de passe
            </label>
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
                className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
              />
            </div>
          </div>

          <Button
            type="submit"
            disabled={isLoading}
            className="w-full h-12 mt-2 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md gap-2 flex items-center justify-center disabled:opacity-50"
          >
            {isLoading ? (
              <Loader2 className="animate-spin text-white" size={20} />
            ) : (
              <>
                Se connecter
                <ArrowRight className="size-4" />
              </>
            )}
          </Button>
        </form>

        <div className="text-center text-xs text-slate-500 pt-2">
          Vous n'avez pas encore de compte ?{" "}
          <Link
            to="/register"
            className="font-bold text-slate-900 hover:underline"
          >
            S'inscrire
          </Link>
        </div>
      </div>
    </AuthLayout>
  );
};

export default Login;
