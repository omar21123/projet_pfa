interface Env {
  apiUrl: string;
  googleClientId: string;
}

const normalizeUrl = (value: string): string => value.replace(/\/$/, "");

const resolveApiUrl = (): string =>
  // If no API URL is provided via env, default to an empty string so axios
  // will use the current origin (relative requests). This prevents requests
  // being sent to http://localhost:80 which often causes 401/404 in dev.
  import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || "";

const resolveGoogleClientId = (): string => {
  const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;

  if (!clientId) {
    // Ne bloque pas le build, mais signale clairement le problème en dev
    console.warn(
      "[env] VITE_GOOGLE_CLIENT_ID n'est pas défini — le bouton de connexion Google ne fonctionnera pas.",
    );
  }

  return clientId ?? "";
};

export const env: Env = {
  apiUrl: normalizeUrl(resolveApiUrl()),
  googleClientId: resolveGoogleClientId(),
};
