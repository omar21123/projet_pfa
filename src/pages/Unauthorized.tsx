// src/pages/Unauthorized.tsx
import { Link } from "react-router-dom";

export default function Unauthorized() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 text-center px-4">
      <h1 className="text-2xl font-semibold">Accès refusé</h1>
      <p className="text-sm text-muted-foreground max-w-sm">
        Vous n'avez pas les autorisations nécessaires pour accéder à cette page.
      </p>
      <Link to="/" className="text-sm underline">
        Retour à l'accueil
      </Link>
    </div>
  );
}