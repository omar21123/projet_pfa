import { lazy, Suspense } from "react";
import { Route, Routes } from "react-router-dom";
import { ProtectedRoute } from "@/routes/ProtectedRoute";
import { RoleProtectedRoute } from "@/routes/RoleProtectedRoute";
import GoogleCallback from "@/pages/GoogleCallback"; 


const Index = lazy(() => import("@/pages/Index"));
const AdDetails = lazy(() => import("@/pages/AdDetails"));
const Login = lazy(() => import("@/pages/Login"));
const Register = lazy(() => import("@/pages/Register"));
const AuthCallback = lazy(() => import("@/pages/AuthCallback"));
const VerifyEmail = lazy(() => import("@/pages/VerifyEmail"));
const CreateAd = lazy(() => import("@/pages/CreateAd"));
const UserDashboard = lazy(() => import("@/pages/UserDashboard"));
const Messages = lazy(() => import("@/pages/Messages"));
const Favorites = lazy(() => import("@/pages/Favorites"));
const Cart = lazy(() => import("@/pages/Cart"));
const NotFound = lazy(() => import("@/pages/NotFound"));
const Unauthorized = lazy(() => import("@/pages/Unauthorized"));
const Profile = lazy(() => import("@/pages/Profile"));
const Settings = lazy(() => import("@/pages/Settings"));
const MyAds = lazy(() => import("@/pages/MyAds"));

// --- IMPORTS ADMIN ---
const AppLayoutAdmin = lazy(() => import("@/pages/admin/AppLayout")); // Ton Layout (AppLayout.tsx)
const Analytics = lazy(() => import("@/pages/admin/analytics"));       // Page d'Analyses / Dashboard
const VendorsPage = lazy(() => import("@/pages/admin/VendorsPage"));   // Ta page Vendeurs fusionnée
const Listings = lazy(() => import("@/pages/admin/listings"));         // Page des Annonces
const Categories = lazy(() => import("@/pages/admin/categories"));     // Page des Catégories
const UsersList = lazy(() => import("@/pages/admin/users"));  
const TagsUnitsPage = lazy(() => import("@/pages/admin/TagsUnits"));             // Page des Tags et Unités  
const BrandsModelsPage = lazy(() => import("@/pages/admin/BrandsModels"));         // Page des Utilisateurs

export const AppRouter = () => {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center text-sm text-muted-foreground">
          Loading...
        </div>
      }
    >
      <Routes>
        <Route path="/" element={<Index />} />
        <Route path="/ad/:id" element={<AdDetails />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/auth/google/callback" element={<GoogleCallback />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="/oauth-callback" element={<AuthCallback />} />
        <Route path="/verify-email" element={<VerifyEmail />} />
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

        {/* ==================================================================== */}
        {/*   ZONE ADMIN FUSIONNÉE : Toutes les pages partagent l'AppLayout      */}
        {/* ==================================================================== */}
        <Route
          path="/admin"
          element={
            <RoleProtectedRoute allowedRoles={["ADMIN"]}>
              <AppLayoutAdmin /> {/* Le composant parent qui contient la Sidebar et l'Outlet */}
            </RoleProtectedRoute>
          }
        >
          {/* Les sous-routes enfants de /admin (s'injectent dans l'Outlet du Layout) */}
          <Route index element={<Analytics />} /> {/* Par défaut sur /admin, on affiche les analyses */}
          <Route path="dashboard" element={<Analytics />} />
          <Route path="analytics" element={<Analytics />} />
          <Route path="vendors" element={<VendorsPage />} />
          <Route path="listings" element={<Listings />} />
          <Route path="categories" element={<Categories />} />
          <Route path="users" element={<UsersList />} />
          <Route path="tags-units" element={<TagsUnitsPage />} />
          <Route path="brands-models" element={<BrandsModelsPage />} />
        </Route>
        {/* ==================================================================== */}

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
          path="/ads"
          element={
            <ProtectedRoute>
              <MyAds />
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
        <Route
          path="/my-ads"
          element={
            <ProtectedRoute>
              <MyAds />
            </ProtectedRoute>
          }
        />
        <Route path="/unauthorized" element={<Unauthorized />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Suspense>
  );
};