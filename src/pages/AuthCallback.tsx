import { useEffect } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { setAuthAccessToken } from "@/api/axiosInstance";

const AUTH_TOKEN_KEY = "authToken";
const ACCESS_TOKEN_KEY = "accessToken";

const isLikelyJwt = (token: string): boolean =>
  /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(token);

const decodeJwtPayload = (token: string): Record<string, unknown> | null => {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const normalized = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
    return JSON.parse(atob(padded)) as Record<string, unknown>;
  } catch {
    return null;
  }
};

const isTokenExpired = (token: string): boolean => {
  const payload = decodeJwtPayload(token);
  if (!payload || typeof payload.exp !== "number") {
    return true;
  }

  const now = Math.floor(Date.now() / 1000);
  return payload.exp <= now;
};

const AuthCallback = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    const params = new URLSearchParams(location.search);

    const error = params.get("error");
    if (error) {
      navigate(`/login?error=${encodeURIComponent(error)}`, { replace: true });
      return;
    }

    const accessToken = params.get("token");

    if (!accessToken) {
      navigate("/login?error=google_failed", { replace: true });
      return;
    }

    if (!isLikelyJwt(accessToken)) {
      navigate("/login?error=invalid_token", { replace: true });
      return;
    }

    if (isTokenExpired(accessToken)) {
      navigate("/login?error=token_expired", { replace: true });
      return;
    }

    localStorage.setItem(AUTH_TOKEN_KEY, accessToken);
    localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);

    setAuthAccessToken(accessToken);

    navigate("/dashboard", { replace: true });
  }, [location.search, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="text-center space-y-4">
        {/* ✅ Spinner visuel */}
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto" />
        <div className="text-sm text-muted-foreground">Connexion Google en cours...</div>
      </div>
    </div>
  );
};

export default AuthCallback;
