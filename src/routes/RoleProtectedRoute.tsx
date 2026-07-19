// src/routes/RoleProtectedRoute.tsx
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../contexts";
import type { ReactNode } from "react";

interface RoleProtectedRouteProps {
  children: ReactNode;
  /** Rôles autorisés à accéder à cette route, ex: ["ADMIN"] ou ["ADMIN", "VENDOR"] */
  allowedRoles: string[];
}

export const RoleProtectedRoute = ({ children, allowedRoles }: RoleProtectedRouteProps) => {
  const { isAuthenticated, isBootstrapping, roles } = useAuth();
  const location = useLocation();

  if (isBootstrapping) {
    return (
      <div className="min-h-screen flex items-center justify-center text-sm text-muted-foreground">
        Loading...
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  const isAllowed = allowedRoles.some((role) => roles.includes(role));

  if (!isAllowed) {
    // L'utilisateur est connecté mais n'a pas le rôle requis
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
};