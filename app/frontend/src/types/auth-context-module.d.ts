declare module "@/context/AuthContext" {
  import type { ReactNode } from "react";

  export interface AuthContextValue {
    accessToken: string | null;
    email: string | null;
    isAuthenticated: boolean;
    isBootstrapping: boolean;
    login: (
      email: string,
      password: string,
    ) => Promise<{
      accessToken: string;
      refreshToken: string;
    }>;
    logout: () => Promise<void>;
  }

  export function AuthProvider(props: { children: ReactNode }): JSX.Element;
  export function useAuth(): AuthContextValue;
}
