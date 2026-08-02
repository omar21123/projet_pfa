import { useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/contexts";

const GoogleCallback = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { loginWithGoogle, loginWithAccessToken } = useAuth();

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const token = params.get("token");
    const idToken = params.get("id_token") || params.get("credential");
    const role = params.get("role");
    const error = params.get("error");

    if (error) {
      navigate(`/login?error=${encodeURIComponent(error)}`, { replace: true });
      return;
    }

    const completeLogin = async () => {
      try {
        if (idToken) {
          const response = await loginWithGoogle(idToken);
          if (response.requires_onboarding) {
            sessionStorage.setItem("google_token", idToken);
            navigate("/complete-profile", {
              replace: true,
              state: { googleToken: idToken },
            });
            return;
          }

          const responseRole = Array.isArray(response.role)
            ? response.role[0]
            : response.role;
          navigate(responseRole === "ADMIN" ? "/admin" : responseRole === "VENDOR" ? "/vendor/dashboard" : "/", {
            replace: true,
          });
          return;
        }

        if (token) {
          loginWithAccessToken(token, role ?? undefined);
          navigate(role === "ADMIN" ? "/admin" : role === "VENDOR" ? "/vendor/dashboard" : "/", {
            replace: true,
          });
          return;
        }

        navigate("/login?error=invalid_token", { replace: true });
      } catch {
        navigate("/login?error=google_failed", { replace: true });
      }
    };

    void completeLogin();
  }, [location.search, loginWithAccessToken, loginWithGoogle, navigate]);

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
