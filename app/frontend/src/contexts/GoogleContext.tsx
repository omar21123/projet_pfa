import type { ReactNode } from "react";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { env } from "@/config/env";

export const GoogleProvider = ({ children }: { children: ReactNode }) => {
  return (
    <GoogleOAuthProvider clientId={env.googleClientId}>
      {children}
    </GoogleOAuthProvider>
  );
};