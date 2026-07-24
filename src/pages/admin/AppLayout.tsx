import React, { useState, useEffect } from "react";
import { Link, useLocation, Outlet, useNavigate } from "react-router-dom";
import { 
  LayoutDashboard, 
  Store, 
  ShoppingBag, 
  Tags, 
  Users, 
  BarChart3, 
  Menu, 
  X,
  LogOut,
  Search,
  Bell,
  ChevronDown,
  Layers,       // Nouvelle icône pour Tags & Unités
  ShieldCheck   // Nouvelle icône pour Marques & Modèles
} from "lucide-react";
import { Button } from "@/components/ui/button";

// Importations (API, types et contexte global)
import { adminApi } from "@/api/admin.api";
import { AdminProfileData } from "@/types/admin.types";
import { useAuth } from "@/contexts";

// Tableau des éléments de navigation mis à jour
const menuItems = [
  { label: "Dashboard", path: "/admin/dashboard", icon: LayoutDashboard },
  { label: "Vendor Management", path: "/admin/vendors", icon: Store },
  { label: "Annonces", path: "/admin/listings", icon: ShoppingBag, badge: 6 },
  { label: "Catégories", path: "/admin/categories", icon: Tags },
  { label: "Tags & Unités", path: "/admin/tags-units", icon: Layers },       // <-- AJOUT PAGE 1
  { label: "Marques & Modèles", path: "/admin/brands-models", icon: ShieldCheck }, // <-- AJOUT PAGE 2
  { label: "Utilisateurs", path: "/admin/users", icon: Users },
  { label: "Rapports", path: "/admin/analytics", icon: BarChart3 },
];

export default function AppLayout() {
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [profile, setProfile] = useState<AdminProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  
  const location = useLocation();
  const navigate = useNavigate();

  // Extraction de la fonction logout du Contexte global
  const { logout } = useAuth(); 

  const currentMenuItem = menuItems.find(item => location.pathname === item.path) || menuItems[0];
  const CurrentIcon = currentMenuItem.icon;

  // 1. Charger le profil de l'admin au montage du Layout
  useEffect(() => {
    let isMounted = true;

    adminApi.getProfile()
      .then((res) => {
        if (isMounted && res.success) {
          setProfile(res.data);
        }
      })
      .catch((err) => {
        console.error("Impossible de charger le profil de l'administrateur :", err);
        if (err.response?.status === 401) {
          navigate("/login");
        }
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [navigate]);

  // 2. Handler de déconnexion utilisant le state global
  const handleLogout = () => {
    logout(); 
  };

  // 3. Générateur d'initiales pour l'avatar par défaut
  const getInitials = () => {
    if (!profile) return "AD";
    const first = profile.user.first_name?.[0] || "";
    const last = profile.user.last_name?.[0] || "";
    return `${first}${last}`.toUpperCase();
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#F4F6F8] text-slate-900 antialiased">
      
      {/* SIDEBAR VERTICALE (Desktop) */}
      <aside className="hidden md:flex flex-col w-72 bg-[#124E54] text-white shrink-0">
        <div className="p-6 flex items-center gap-3">
          <div className="w-9 h-9 bg-[#CCEC53] text-[#124E54] font-bold rounded-xl flex items-center justify-center text-lg shadow-sm">
            s
          </div>
          <span className="text-xl font-bold tracking-tight text-white">
            souq<span className="text-[#CCEC53]">admin</span>
          </span>
        </div>
        
        <nav className="flex-1 px-4 py-2 space-y-1 overflow-y-auto">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-4 py-3.5 rounded-xl text-[15px] font-medium transition-all duration-150 ${
                  isActive 
                    ? "bg-[#0D3B40] text-[#CCEC53]" 
                    : "text-[#9BB9BC] hover:bg-white/5 hover:text-white"
                }`}
              >
                <Icon className={`w-5 h-5 ${isActive ? "text-[#CCEC53]" : "text-[#9BB9BC]"}`} />
                <span className="flex-1">{item.label}</span>
                
                {item.badge && (
                  <span className={`w-6 h-6 text-xs flex items-center justify-center rounded-full font-semibold ${
                    isActive ? "bg-[#1A5258] text-white" : "bg-[#245D66] text-white"
                  }`}>
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-[#1A5258]">
          <button 
            onClick={handleLogout}
            className="flex items-center gap-3 w-full px-4 py-3 text-sm font-medium text-rose-300 hover:bg-rose-500/10 rounded-xl transition-colors"
          >
            <LogOut className="w-5 h-5" />
            Déconnexion
          </button>
        </div>
      </aside>

      {/* ZONE PRINCIPALE (Header + Contenu) */}
      <div className="flex flex-1 flex-col overflow-hidden">
        
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between shrink-0 shadow-sm">
          
          <div className="flex items-center gap-3">
            <Button 
              variant="ghost" 
              size="icon" 
              className="md:hidden text-[#124E54]" 
              onClick={() => setIsMobileOpen(true)}
            >
              <Menu className="w-6 h-6" />
            </Button>
            
            <div className="hidden md:flex items-center gap-2.5 text-[#124E54] font-semibold text-base">
              <CurrentIcon className="w-5 h-5 text-[#124E54]" />
              <span>{currentMenuItem.label}</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            
            <div className="relative hidden sm:block w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <input 
                type="text" 
                placeholder="Rechercher..." 
                className="w-full pl-9 pr-4 py-1.5 bg-[#F4F7F9] border border-slate-200 rounded-xl text-sm text-slate-700 placeholder-slate-400 focus:outline-none focus:border-[#124E54] focus:ring-1 focus:ring-[#124E54] transition-all"
              />
            </div>

            <button className="p-2 text-slate-500 hover:bg-slate-50 rounded-lg relative transition-colors">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full" />
            </button>

            <div className="h-6 w-px bg-slate-200 mx-1 hidden sm:block" />

            {/* Profil Administrateur Dynamique */}
            <div className="flex items-center gap-2 cursor-pointer hover:bg-slate-50 py-1.5 px-2 rounded-xl transition-colors">
              {loading ? (
                <div className="w-8 h-8 bg-slate-200 rounded-full animate-pulse" />
              ) : profile?.user.avatar_url ? (
                <img 
                  src={profile.user.avatar_url} 
                  alt={profile.user.display_name} 
                  className="w-8 h-8 rounded-full object-cover border border-slate-100"
                />
              ) : (
                <div className="w-8 h-8 bg-[#E2EDF0] text-[#124E54] font-bold rounded-full flex items-center justify-center text-xs border border-slate-100">
                  {getInitials()}
                </div>
              )}

              <div className="flex flex-col text-left hidden sm:flex">
                <span className="text-sm font-semibold text-slate-700 leading-none">
                  {loading ? "Chargement..." : profile?.user.display_name}
                </span>
                {profile && (
                  <span className="text-[10px] text-slate-400 mt-1">
                    {profile.admin_profile.position}
                  </span>
                )}
              </div>
              <ChevronDown className="w-4 h-4 text-slate-400" />
            </div>

          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-6 md:p-8">
          <Outlet />
        </main>
      </div>

      {/* MENU MOBILE DRAWER */}
      <div className="md:hidden">
        {isMobileOpen && (
          <div 
            className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-sm" 
            onClick={() => setIsMobileOpen(false)} 
          />
        )}
        <aside className={`fixed top-0 bottom-0 left-0 z-50 w-72 bg-[#124E54] flex flex-col transition-transform duration-300 ease-in-out transform ${
          isMobileOpen ? 'translate-x-0' : '-translate-x-full'
        }`}>
          <div className="p-6 flex justify-between items-center border-b border-[#1A5258]">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-[#CCEC53] text-[#124E54] font-bold rounded-lg flex items-center justify-center text-base">
                s
              </div>
              <span className="font-bold text-white text-lg">souq<span className="text-[#CCEC53]">admin</span></span>
            </div>
            <Button variant="ghost" size="icon" className="text-white hover:bg-white/10" onClick={() => setIsMobileOpen(false)}>
              <X className="w-5 h-5" />
            </Button>
          </div>
          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            {menuItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setIsMobileOpen(false)}
                  className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium ${
                    isActive ? "bg-[#0D3B40] text-[#CCEC53]" : "text-[#9BB9BC]"
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="flex-1">{item.label}</span>
                  {item.badge && (
                    <span className="bg-[#245D66] text-white text-xs px-2 py-0.5 rounded-full">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>
        </aside>
      </div>

    </div>
  );
}