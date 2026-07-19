import { useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/contexts"; // Ajustez le chemin selon votre projet

const GoogleCallback = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { handleSocialLoginSuccess } = useAuth(); // Nous allons définir cette méthode à l'étape 2

  useEffect(() => {
    // 1. Extraction des paramètres de l'URL renvoyés par Laravel
    const params = new URLSearchParams(location.search);
    const token = params.get("token");
    const role = params.get("role");
    const error = params.get("error");

    // 2. Gestion des erreurs renvoyées par le backend
    if (error) {
      navigate(`/login?error=${error}`);
      return;
    }

    // 3. Si tout est OK, on connecte l'utilisateur
    if (token && role) {
      // On enregistre le token en mémoire et met à jour le contexte
      handleSocialLoginSuccess(token, role);
      
      // Redirection selon le rôle (identique à votre logique de Login.tsx)
      navigate(role === "ADMIN" ? "/admin/vendors" : "/");
    } else {
      // Si aucun token n'est fourni et pas d'erreur explicite
      navigate("/login?error=invalid_token");
    }
  }, [location, navigate, handleSocialLoginSuccess]);

  // Écran de chargement esthétique en attendant la redirection (style Marché)
  return (
    <div className="min-h-screen flex items-center justify-center bg-[#f8f9fa]">
      <div className="flex flex-col items-center gap-3">
        <div className="h-8 w-8 border-4 border-[#2c3e50]/20 border-t-[#2c3e50] rounded-full animate-spin" />
        <p className="text-sm font-semibold text-slate-600 animate-pulse">
          Connexion sécurisée en cours...
        </p>
      </div>
    </div>
  );
};

export default GoogleCallback;