// src/pages/vendor/VendorDashboard.tsx
import Navbar from "@/components/layout/Navbar"; // 👈 Ajustez le chemin vers votre Navbar si nécessaire
import { useAuth } from "@/contexts";
import { 
  ShoppingBag, 
  DollarSign, 
  Package, 
  TrendingUp 
} from "lucide-react";

export const VendorDashboard = () => {
  const { email, roles } = useAuth();

  return (
    <div className="min-h-screen bg-slate-50 font-sans">
      {/* 🟢 Affichage de la Navbar globale */}
      <Navbar />

      {/* Contenu du Dashboard Vendeur */}
      <main className="max-w-7xl mx-auto p-6 space-y-6">
        {/* Banner de bienvenue */}
        <div className="bg-gradient-to-r from-slate-900 to-slate-800 rounded-2xl p-6 text-white shadow-lg flex justify-between items-center">
          <div>
            <span className="inline-block px-3 py-1 bg-teal/20 text-teal-300 text-xs font-bold rounded-full mb-2">
              Rôle : {roles.join(", ") || "VENDOR"}
            </span>
            <h1 className="text-2xl font-black">Mon Tableau de bord</h1>
            <p className="text-slate-300 text-sm mt-1">
              Connecté en tant que : <span className="text-white font-medium">{email}</span>
            </p>
          </div>
          <TrendingUp className="h-16 w-16 text-teal/40 hidden sm:block" />
        </div>

        {/* Cartes de statistiques */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Ventes du mois</p>
              <h3 className="text-2xl font-black text-slate-900 mt-1">12 450 DH</h3>
            </div>
            <div className="p-3 bg-emerald-50 text-emerald-600 rounded-xl">
              <DollarSign className="h-6 w-6" />
            </div>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Commandes</p>
              <h3 className="text-2xl font-black text-slate-900 mt-1">28</h3>
            </div>
            <div className="p-3 bg-blue-50 text-blue-600 rounded-xl">
              <ShoppingBag className="h-6 w-6" />
            </div>
          </div>

          <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Produits actifs</p>
              <h3 className="text-2xl font-black text-slate-900 mt-1">14</h3>
            </div>
            <div className="p-3 bg-amber-50 text-amber-600 rounded-xl">
              <Package className="h-6 w-6" />
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default VendorDashboard;