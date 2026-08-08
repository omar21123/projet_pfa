import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AuthProvider, UserProvider, GoogleProvider } from "@/contexts";
import { NotificationProvider } from "@/contexts/NotificationContext";
import { CartProvider } from "@/contexts/CartContext";
import { LanguageProvider } from "@/contexts/LanguageContext";
import { AppRouter } from "@/routes/AppRouter";
import { useCategories } from "@/hooks/useCategories";
import { useState } from "react";
import { SplashScreen } from "@/pages/SplashScreen_ameliore";
import { env } from "./config";

/*const CategoriesPrefetch = () => {
  useCategories();
  return null;
};*/

const queryClient = new QueryClient();

const App = () => {
  const [isLoading, setIsLoading] = useState(true);

  if (isLoading) {
    return <SplashScreen duration={4000} onFinish={() => setIsLoading(false)} />;
  }

  return (
    <GoogleProvider>
      <QueryClientProvider client={queryClient}>
        <LanguageProvider>
          <AuthProvider>
            <UserProvider>
              <NotificationProvider>
                <CartProvider>
                  <TooltipProvider>
                    <Toaster />
                    <Sonner />
                    <BrowserRouter>
                      {/*<CategoriesPrefetch />*/}
                      <AppRouter />
                    </BrowserRouter>
                  </TooltipProvider>
                </CartProvider>
              </NotificationProvider>
            </UserProvider>
          </AuthProvider>
        </LanguageProvider>
      </QueryClientProvider>
    </GoogleProvider>
  );
};

export default App;
