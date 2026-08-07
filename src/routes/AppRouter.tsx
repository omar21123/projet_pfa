import { lazy, Suspense } from "react";
import { Route, Routes } from "react-router-dom";
import { ProtectedRoute } from "@/routes/ProtectedRoute";
import { RoleProtectedRoute } from "@/routes/RoleProtectedRoute";
import GoogleCallback from "@/pages/GoogleCallback";

// --- IMPORTS DES PAGES CLIENTS ---
const Index = lazy(() => import("@/pages/Index"));
const AdDetails = lazy(() => import("@/pages/AdDetails"));
const Login = lazy(() => import("@/pages/Login"));
const Register = lazy(() => import("@/pages/Register"));
const AuthCallback = lazy(() => import("@/pages/AuthCallback"));
const VerifyEmail = lazy(() => import("@/pages/VerifyEmail"));
const CompleteGoogleProfile = lazy(() =>
  import("@/pages/CompleteGoogleProfile").then((module) => ({
    default: module.CompleteGoogleProfile ?? module.default,
  })),
);
const CreateAd = lazy(() => import("@/pages/NouvelleAnnoncePage"));
const UserDashboard = lazy(() => import("@/pages/UserDashboard"));
const Messages = lazy(() => import("@/pages/Messages"));
const Favorites = lazy(() => import("@/pages/Favorites"));
const Wishlists = lazy(() => import("@/pages/Wishlists"));
const Cart = lazy(() => import("@/pages/Cart"));
const NotFound = lazy(() => import("@/pages/NotFound"));
const Unauthorized = lazy(() => import("@/pages/Unauthorized"));
const Profile = lazy(() => import("@/pages/Profile"));
const Settings = lazy(() => import("@/pages/Settings"));
const MyAds = lazy(() => import("@/pages/vendor/MyAdsPage"));
const VendorDashboard = lazy(() => import("@/pages/vendor/VendorDashboard"));
const VendorProductDetailPage = lazy(() => import("@/pages/vendor/VendorProductDetailPage"));
import MainLayout from "@/components/layout/MainLayout";

// --- IMPORTS DES PAGES ADMIN (Vérifie bien la casse de tes fichiers sous /pages/admin/) ---
const AppLayoutAdmin = lazy(() => import("@/pages/admin/AppLayout"));
const Analytics = lazy(() => import("@/pages/admin/analytics"));
const VendorsPage = lazy(() => import("@/pages/admin/VendorsPage"));
const Listings = lazy(() =>
  import("@/pages/admin/ProductsAdminPage").then((module) => ({
    default: module.ProductsAdminPage,
  })),
);
const Categories = lazy(() => import("@/pages/admin/categories"));
const UsersList = lazy(() => import("@/pages/admin/users"));
const TagsUnitsPage = lazy(() => import("@/pages/admin/TagsUnits"));
const BrandsModelsPage = lazy(() => import("@/pages/admin/BrandsModels"));
const ProductDetailsPage = lazy(() => import("@/pages/admin/ProductDetailsPage"));
const PromotionsPage = lazy(() => import("@/pages/admin/PromotionsPage"));

export const AppRouter = () => {
  return (
    <Suspense
    /*fallback={
        <div className="min-h-screen flex items-center justify-center text-sm text-muted-foreground">
          Chargement de l'application...
        </div>
      }*/
    >
      <Routes>
        {/* Routes Publiques & Standard */}
        <Route path="/" element={<Index />} />
        <Route path="/ad/:id" element={<AdDetails />} />
        {/* Legacy / localized product route (French) used across the UI; keep in sync with /ad/:id */}
        <Route path="/produit/:id" element={<AdDetails />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/auth/google/callback" element={<GoogleCallback />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="/oauth-callback" element={<AuthCallback />} />
        {/* 🟢 FIX : route manquante — c'est ici que GoogleAuthController::handleGoogleCallback
            redirige quand requires_onboarding est vrai (flow de redirection navigateur classique,
            GET /auth/google). Sans cette route, l'utilisateur tombait sur la page 404. */}
        <Route path="/complete-profile" element={<CompleteGoogleProfile />} />
        <Route path="/complete-google-profile" element={<CompleteGoogleProfile />} />
        <Route path="/verify-email" element={<VerifyEmail />} />

        {/* Routes Utilisateurs Sécurisées */}
        <Route
          path="/create"
          element={
            <ProtectedRoute>
              <CreateAd />
            </ProtectedRoute>
          }
        />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <UserDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/messages"
          element={
            <ProtectedRoute>
              <Messages />
            </ProtectedRoute>
          }
        />
        <Route
          path="/favorites"
          element={
            <ProtectedRoute>
              <Favorites />
            </ProtectedRoute>
          }
        />
        <Route
          path="/wishlists"
          element={
            <ProtectedRoute>
              <Wishlists />
            </ProtectedRoute>
          }
        />
        <Route path="/cart" element={<Cart />} />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />
        <Route
          path="/settings"
          element={
            <ProtectedRoute>
              <Settings />
            </ProtectedRoute>
          }
        />
        {/* ==================================================================== */}
        {/*   ESPACE VENDEUR (avec Navbar via MainLayout)                      */}
        {/* ==================================================================== */}
        <Route element={<MainLayout />}>
          <Route
            path="/my-ads"
            element={
              <RoleProtectedRoute allowedRoles={["VENDOR"]}>
                <MyAds />
              </RoleProtectedRoute>
            }
          />
          <Route
            path="/vendor/dashboard"
            element={
              <RoleProtectedRoute allowedRoles={["VENDOR"]}>
                <VendorDashboard />
              </RoleProtectedRoute>
            }
          />
          <Route
            path="/products/:id"
            element={
              <RoleProtectedRoute allowedRoles={["VENDOR"]}>
                <VendorProductDetailPage />
              </RoleProtectedRoute>
            }
          />
          <Route
            path="/products/:id/edit"
            element={
              <RoleProtectedRoute allowedRoles={["VENDOR"]}>
                <VendorProductDetailPage />
              </RoleProtectedRoute>
            }
          />
        </Route>

        {/* ==================================================================== */}
        {/*   ESPACE ADMINISTRATION CONTÔLÉ                                      */}
        {/* ==================================================================== */}
        <Route
          path="/admin"
          element={
            <RoleProtectedRoute allowedRoles={["ADMIN"]}>
              <AppLayoutAdmin />
            </RoleProtectedRoute>
          }
        >
          {/* Sous-routes enfants injectées dans l'Outlet d'AppLayoutAdmin */}
          <Route index element={<Analytics />} />
          <Route path="dashboard" element={<Analytics />} />
          <Route path="analytics" element={<Analytics />} />
          <Route path="vendors" element={<VendorsPage />} />
          <Route path="listings" element={<Listings />} />
          <Route path="categories" element={<Categories />} />
          <Route path="users" element={<UsersList />} />
          <Route path="tags-units" element={<TagsUnitsPage />} />
          <Route path="brands-models" element={<BrandsModelsPage />} />
          <Route path="/admin/products/:id" element={<ProductDetailsPage />} />
          <Route path="/admin/promotions" element={<PromotionsPage />} />
        </Route>
        {/* Erreurs de routage */}
        <Route path="/unauthorized" element={<Unauthorized />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Suspense>
  );
};
