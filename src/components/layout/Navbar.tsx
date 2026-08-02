// src/components/navigation/Navbar.tsx
import {
  Plus,
  User,
  Heart,
  MessageCircle,
  ShoppingCart,
  LayoutDashboard,
  LogOut,
  Settings,
  Moon,
  Sun,
  ChevronDown,
} from "lucide-react";
import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { useAuth } from "@/contexts";
import { useCart } from "@/hooks/useCart";
import { useLanguage } from "@/contexts/LanguageContext";
import LanguageSwitcher from "@/components/LanguageSwitcher";
import Categories from "@/components/navigation/Categories";
import SearchBar from "@/components/search/SearchBar";

/* ──────────────────────────────────────────────
   SOUS-COMPOSANTS
   ────────────────────────────────────────────── */

/** Toggle clair/sombre avec persistance localStorage */
const DarkModeToggle = () => {
  const [isDark, setIsDark] = React.useState(() =>
    document.documentElement.classList.contains("dark"),
  );

  const toggle = () => {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.classList.toggle("dark", next);
    localStorage.setItem("theme", next ? "dark" : "light");
  };

  React.useEffect(() => {
    const saved = localStorage.getItem("theme");
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const shouldBeDark = saved === "dark" || (!saved && prefersDark);
    setIsDark(shouldBeDark);
    document.documentElement.classList.toggle("dark", shouldBeDark);
  }, []);

  return (
    <Button
      variant="outline"
      size="icon"
      onClick={toggle}
      className="rounded-full h-8 w-8 border-border bg-background text-muted-foreground hover:text-teal hover:border-teal/40 shrink-0 transition-colors"
    >
      {isDark ? <Sun className="h-3.5 w-3.5" /> : <Moon className="h-3.5 w-3.5" />}
    </Button>
  );
};

/** Lien icône avec tooltip réutilisable */
const NavIconLink = ({
  to,
  icon: Icon,
  label,
  tooltip,
  accent = "teal",
}: {
  to: string;
  icon: React.ElementType;
  label: string;
  tooltip: string;
  accent?: "teal" | "promo";
}) => (
  <Tooltip>
    <TooltipTrigger asChild>
      <Link
        to={to}
        className={`relative flex items-center gap-1 text-foreground/90 transition-colors shrink-0 p-1.5 rounded-md hover:bg-muted active:scale-95 ${
          accent === "promo" ? "hover:text-promo" : "hover:text-teal"
        }`}
      >
        <Icon className="h-4 w-4" />
        <span className="hidden xl:inline">{label}</span>
      </Link>
    </TooltipTrigger>
    <TooltipContent side="bottom">
      <p>{tooltip}</p>
    </TooltipContent>
  </Tooltip>
);

/** Badge compteur pour le panier */
const CartBadge = ({ count }: { count: number }) => {
  if (count <= 0) return null;
  return (
    <span className="absolute -top-1 -right-1 h-4 w-4 bg-promo text-white text-[9px] font-bold flex items-center justify-center rounded-full">
      {count}
    </span>
  );
};

/* ──────────────────────────────────────────────
   COMPOSANT PRINCIPAL
   ────────────────────────────────────────────── */

const Navbar = () => {
  const { isAuthenticated, isBootstrapping, logout } = useAuth();
  const { totalItems } = useCart();
  const { t } = useLanguage();
  const navigate = useNavigate();

  /* ── Handlers ── */
  const handleLogout = () => logout();

  const handleCategoryFilter = (filters: { categoryId?: number; subCategoryId?: number }) => {
    const params = new URLSearchParams();
    if (filters.categoryId !== undefined) {
      params.set("category", String(filters.categoryId));
    }
    if (filters.subCategoryId !== undefined) {
      params.set("subCategory", String(filters.subCategoryId));
    }
    navigate(`/?${params.toString()}`);
  };

  /* ── Rendu ── */
  return (
    <header className="sticky top-0 z-50 bg-background/90 backdrop-blur-md border-b border-border">
      <nav className="mx-auto max-w-7xl px-2 md:px-4 h-14 flex items-center justify-between gap-3">
        {/* LOGO */}
        <Link to="/" className="shrink-0">
          <span className="text-xl font-black tracking-tight text-teal font-heading">
            CONNECTIA
          </span>
        </Link>

        <SearchBar />

        {/* ═══════════════════════════════════════
            ZONE ACTIONS (DROITE)
            ═══════════════════════════════════════ */}
        <TooltipProvider>
          <div className="flex items-center gap-2 md:gap-3 text-xs font-medium shrink-0">
            {/* 1. Thème */}
            <DarkModeToggle />

            {/* 2. Langue */}
            <div className="shrink-0">
              <LanguageSwitcher />
            </div>

            {/* 3. Panier */}
            <Tooltip>
              <TooltipTrigger asChild>
                <Link
                  to="/cart"
                  className="relative flex items-center gap-1 text-foreground/90 hover:text-teal transition-colors shrink-0 p-1.5 rounded-md hover:bg-teal/10 active:scale-95"
                >
                  <ShoppingCart className="h-4 w-4" />
                  <span className="hidden xl:inline">Panier</span>
                  <CartBadge count={totalItems} />
                </Link>
              </TooltipTrigger>
              <TooltipContent side="bottom">
                <p>Voir le panier</p>
              </TooltipContent>
            </Tooltip>

            {/* 4. Auth */}
            {isBootstrapping ? (
              <div className="h-8 w-24 bg-muted/60 animate-pulse rounded-lg shrink-0" />
            ) : isAuthenticated ? (
              <>
                <NavIconLink
                  to="/favorites"
                  icon={Heart}
                  label="Favoris"
                  tooltip="Mes favoris"
                  accent="promo"
                />

                <NavIconLink
                  to="/messages"
                  icon={MessageCircle}
                  label="Messages"
                  tooltip="Messagerie"
                />

                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <button className="flex items-center gap-1.5 text-foreground/90 hover:text-teal transition-colors focus:outline-none shrink-0 font-semibold p-1.5 rounded-md hover:bg-teal/10 active:scale-95">
                      <User className="h-4 w-4" />
                      <span className="hidden sm:inline">Mon compte</span>
                      <ChevronDown className="h-3 w-3 text-muted-foreground" />
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-48 z-50">
                    <DropdownMenuItem asChild>
                      <Link to="/dashboard" className="cursor-pointer">
                        <LayoutDashboard className="mr-2 h-4 w-4" />
                        {t("dashboard")}
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link to="/profile" className="cursor-pointer">
                        <User className="mr-2 h-4 w-4" />
                        {t("profile")}
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link to="/my-ads" className="cursor-pointer">
                        <User className="mr-2 h-4 w-4" />
                        {t("my-ads")}
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem asChild>
                      <Link to="/settings" className="cursor-pointer">
                        <Settings className="mr-2 h-4 w-4" />
                        {t("settings")}
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem onClick={handleLogout}>
                      <LogOut className="mr-2 h-4 w-4" />
                      {t("logout")}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </>
            ) : (
              <Link to="/login" className="shrink-0">
                <button
                  type="button"
                  className="btn btn-sm rounded-lg border border-teal text-teal bg-transparent hover:bg-teal hover:text-cream gap-1.5"
                >
                  <User className="h-3.5 w-3.5" />
                  <span>Se connecter</span>
                </button>
              </Link>
            )}

            {/* 5. Publier */}
            <Link to="/create" className="shrink-0">
              <button
                type="button"
                className="btn btn-sm rounded-lg bg-teal text-cream hover:bg-teal-dark gap-1 shadow-sm"
              >
                <Plus className="h-3 w-3" />
                <span>Publier</span>
              </button>
            </Link>
          </div>
        </TooltipProvider>
      </nav>

      {/* CATÉGORIES */}
      <Categories onFilter={handleCategoryFilter} />
    </header>
  );
};

export default Navbar;
