import React, { useState } from "react";
import { 
  Users, CheckCircle, AlertTriangle, Ban, Search, Filter, 
  Eye, ShieldCheck, ShieldAlert, Package, 
  Star, X, MapPin, Phone, Mail, RefreshCw, Info
} from "lucide-react";

// Importation de tes hooks de requêtes et mutations
import { 
  useVendorsList, 
  useVerifyVendorIdentity,
  useApproveVendor, 
  useRejectVendor, 
  useResetVendorToPending 
} from "@/hooks/useVendors";

// --- INTERFACE SCRUPULEUSEMENT ALIGNÉE SUR TON JSON ---
interface Vendor {
  vendorProfileId: number;
  storeName: string;
  logoUrl: string | null;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string | null;
  lastLoginAt: string | null;
  isActive: boolean;
  verificationStatus: "Pending" | "Verified" | string; 
  identityVerified: boolean;
  businessVerified: boolean;
  bankVerified: boolean;
  isApproved: boolean;
  isSuspended: boolean;
  suspendedAt: string | null;
  rating: number;
  reviewCount: number;
  createdAt: string;
  totalProducts: number;
  activeProducts: number;
  totalOrders: number;
  totalRevenue: number;
  withdrawableBalance: number;
}

export default function VendorsPage() {
  // États de filtrage de l'interface graphique
  const [searchTerm, setSearchTerm] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [selectedVendorId, setSelectedVendorId] = useState<number | null>(null);
  const [currentPage, setCurrentPage] = useState<number>(1);

  // --- CONFIGURATION DES FILTRES DE REQUÊTE (SWAGGER) ---
  const buildApiFilters = () => {
    const filters: any = {
      search: searchTerm.trim() || undefined,
      page: currentPage,
      page_size: 20,
    };

    // Alignement avec les paramètres numériques de ton Swagger (0 / 1)
    if (statusFilter === "pending") {
      filters.verification_status = 0;
      filters.is_suspended = 0;
    } else if (statusFilter === "approved") {
      filters.verification_status = 1;
      filters.is_suspended = 0;
    } else if (statusFilter === "suspended") {
      filters.is_suspended = 1;
    }

    return filters;
  };

  // Appel à React Query
  const { data, isLoading, isError } = useVendorsList(buildApiFilters());

  // Mutations du hook useVendors
  const verifyIdentityMutation = useVerifyVendorIdentity();
  const approveMutation = useApproveVendor();
  const rejectMutation = useRejectVendor();
  const resetPendingMutation = useResetVendorToPending();

  // Extraction stricte basée sur ton format : data.data.items
  const vendors: Vendor[] = (data as any)?.data?.items ?? (data as any)?.items ?? [];
  
  // Ciblage dynamique du vendeur sélectionné pour le Drawer
  const selectedVendor = vendors.find(v => v.vendorProfileId === selectedVendorId) || null;

  // Formatage monétaire marocain (MAD)
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("fr-MA", { style: "currency", currency: "MAD" }).format(amount);
  };

  // Statistiques basées sur les données reçues
  const globalStats = {
    total: vendors.length,
    pending: vendors.filter(v => v.verificationStatus === "Pending" && !v.isSuspended).length,
    approved: vendors.filter(v => v.isApproved && !v.isSuspended).length,
    suspended: vendors.filter(v => v.isSuspended).length,
  };

  if (isLoading) {
    return (
      <div className="flex flex-col justify-center items-center h-96 space-y-4">
        <RefreshCw className="w-9 h-9 text-indigo-600 animate-spin" />
        <p className="text-sm font-medium text-slate-500">Synchronisation des comptes vendeurs...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-4 bg-rose-50 text-rose-700 rounded-xl border border-rose-200 flex items-center gap-3">
        <AlertTriangle className="w-5 h-5 flex-shrink-0" />
        <span className="text-sm font-medium">Erreur lors de la récupération des données de l'API Vendors.</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* --- EN-TÊTE --- */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Gestion des Vendeurs</h1>
        <p className="text-sm text-slate-500 mt-0.5">
          Validation des comptes, vérifications des pièces justificatives KYC et suivi des volumes d'affaires.
        </p>
      </div>

      {/* --- CARTES DES STATISTIQUES --- */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-lg"><Users className="w-5 h-5" /></div>
          <div>
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Vendeurs</p>
            <p className="text-2xl font-bold text-slate-900 mt-0.5">{globalStats.total}</p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-amber-50 text-amber-600 rounded-lg"><AlertTriangle className="w-5 h-5" /></div>
          <div>
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">En Attente</p>
            <p className="text-2xl font-bold text-slate-900 mt-0.5">{globalStats.pending}</p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-lg"><CheckCircle className="w-5 h-5" /></div>
          <div>
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Approuvés</p>
            <p className="text-2xl font-bold text-slate-900 mt-0.5">{globalStats.approved}</p>
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-rose-50 text-rose-600 rounded-lg"><Ban className="w-5 h-5" /></div>
          <div>
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Suspendus</p>
            <p className="text-2xl font-bold text-slate-900 mt-0.5">{globalStats.suspended}</p>
          </div>
        </div>
      </div>

      {/* --- RECHERCHE & FILTRES --- */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row gap-3 items-center justify-between bg-slate-50/50">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Rechercher une boutique, email..."
              value={searchTerm}
              onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
              className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg text-sm bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
            />
          </div>
          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <Filter className="w-4 h-4 text-slate-400" />
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setCurrentPage(1); }}
              className="border border-slate-200 rounded-lg px-3 py-2 text-sm text-slate-600 bg-white focus:outline-hidden"
            >
              <option value="all">Tous les statuts</option>
              <option value="pending">En attente (Pending)</option>
              <option value="approved">Approuvés (Verified)</option>
              <option value="suspended">Suspendus</option>
            </select>
          </div>
        </div>

        {/* --- TABLEAU DE RENDU --- */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                <th className="py-3 px-6">Boutique / Gérant</th>
                <th className="py-3 px-6">Statut Compte</th>
                <th className="py-3 px-6">Vérifications (KYC)</th>
                <th className="py-3 px-6">Volume Articles</th>
                <th className="py-3 px-6 text-right">Chiffre d'affaires</th>
                <th className="py-3 px-6 text-center">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm">
              {vendors.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    <Info className="w-6 h-6 mx-auto mb-2 text-slate-300" />
                    Aucun compte marchand trouvé.
                  </td>
                </tr>
              ) : (
                vendors.map((v: Vendor, index: number) => (
                  <tr key={v.vendorProfileId ?? `vendor-${index}`} className="hover:bg-slate-50/50 transition-colors">
                    <td className="py-4 px-6">
                      <span className="font-semibold text-slate-900 block">{v.storeName ?? "Boutique sans nom"}</span>
                      <span className="text-xs text-slate-400 block mt-0.5">{v.firstName} {v.lastName} — {v.email}</span>
                    </td>
                    <td className="py-4 px-6">
                      {v.isSuspended ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-rose-50 text-rose-700 border border-rose-100">
                          <Ban className="w-3 h-3" /> Suspendu
                        </span>
                      ) : v.verificationStatus === "Verified" || v.isApproved ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-100">
                          <CheckCircle className="w-3 h-3" /> Vérifié / Approuvé
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-amber-50 text-amber-700 border border-amber-100">
                          <AlertTriangle className="w-3 h-3" /> En instruction
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-4 text-xs text-slate-500">
                        <span className="flex items-center gap-1" title="Pièce d'identité">
                          {v.identityVerified ? <ShieldCheck className="w-4 h-4 text-emerald-500" /> : <ShieldAlert className="w-4 h-4 text-slate-300" />} CIN
                        </span>
                        <span className="flex items-center gap-1" title="Registre de commerce">
                          {v.businessVerified ? <ShieldCheck className="w-4 h-4 text-emerald-500" /> : <ShieldAlert className="w-4 h-4 text-slate-300" />} RC
                        </span>
                        <span className="flex items-center gap-1" title="Coordonnées Bancaires">
                          {v.bankVerified ? <ShieldCheck className="w-4 h-4 text-emerald-500" /> : <ShieldAlert className="w-4 h-4 text-slate-300" />} RIB
                        </span>
                      </div>
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3 text-slate-500 text-xs">
                        <span className="flex items-center gap-1"><Package className="w-3.5 h-3.5 text-slate-400" /> {v.totalProducts} articles</span>
                        <span className="flex items-center gap-1"><Star className="w-3.5 h-3.5 text-slate-400" /> {v.totalOrders} cmd</span>
                      </div>
                    </td>
                    <td className="py-4 px-6 text-right font-semibold text-slate-900 font-mono">
                      {formatCurrency(v.totalRevenue)}
                    </td>
                    <td className="py-4 px-6 text-center">
                      <button
                        onClick={() => setSelectedVendorId(v.vendorProfileId)}
                        className="inline-flex items-center justify-center p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* --- PANNEAU LATÉRAL MODAL DE MODÉRATION (DRAWER) --- */}
      {selectedVendor && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex justify-end">
          <div className="w-full max-w-xl bg-white h-full shadow-2xl flex flex-col transform animate-in slide-in-from-right duration-200">
            
            <div className="p-6 border-b border-slate-200 flex items-center justify-between bg-slate-50">
              <div>
                <h2 className="text-lg font-bold text-slate-900">{selectedVendor.storeName ?? "Boutique sans nom"}</h2>
                <p className="text-xs text-slate-500 mt-0.5">Dossier # {selectedVendor.vendorProfileId} — Créé le {new Date(selectedVendor.createdAt).toLocaleDateString('fr-FR')}</p>
              </div>
              <button 
                onClick={() => setSelectedVendorId(null)} 
                className="p-2 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-200/50"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* KPIs financiers directs */}
              <div className="grid grid-cols-3 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-100">
                <div className="text-center">
                  <span className="text-xs font-medium text-slate-400 block mb-1">Total Produits</span>
                  <div className="text-lg font-bold text-slate-900">{selectedVendor.totalProducts}</div>
                </div>
                <div className="text-center border-x border-slate-200">
                  <span className="text-xs font-medium text-slate-400 block mb-1">Commandes</span>
                  <div className="text-lg font-bold text-slate-900">{selectedVendor.totalOrders}</div>
                </div>
                <div className="text-center">
                  <span className="text-xs font-medium text-slate-400 block mb-1">C.A. Global</span>
                  <div className="text-sm font-bold text-indigo-600 mt-1 font-mono">
                    {formatCurrency(selectedVendor.totalRevenue)}
                  </div>
                </div>
              </div>

              {/* Contacts de l'utilisateur */}
              <div className="space-y-3 bg-white border border-slate-200 rounded-xl p-4 text-sm text-slate-600">
                <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Responsable légal</h3>
                <div className="flex items-center gap-3"><Mail className="w-4 h-4 text-slate-400" /> <span className="text-slate-900">{selectedVendor.email}</span></div>
                <div className="flex items-center gap-3"><Phone className="w-4 h-4 text-slate-400" /> <span className="text-slate-900">{selectedVendor.phoneNumber ?? "Non renseigné"}</span></div>
              </div>

              {/* Section KYC */}
              <div className="border border-slate-200 rounded-xl bg-white overflow-hidden divide-y divide-slate-100">
                <div className="p-4 bg-slate-50/50"><h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">État des vérifications obligatoires</h3></div>
                
                <div className="p-4 flex items-center justify-between">
                  <span className="text-sm font-medium text-slate-700">Pièce d'identité nationale (CIN)</span>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-md ${selectedVendor.identityVerified ? 'text-emerald-700 bg-emerald-50' : 'text-amber-700 bg-amber-50'}`}>
                    {selectedVendor.identityVerified ? "Validée" : "À traiter"}
                  </span>
                </div>

                <div className="p-4 flex items-center justify-between">
                  <span className="text-sm font-medium text-slate-700">Registre du Commerce (RC)</span>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-md ${selectedVendor.businessVerified ? 'text-emerald-700 bg-emerald-50' : 'text-slate-400 bg-slate-50'}`}>
                    {selectedVendor.businessVerified ? "Vérifié" : "En attente"}
                  </span>
                </div>
              </div>
            </div>

            {/* --- REZ-DE-CHAUSSÉE : APPEL DYNAMIQUE AUX COMPOSANTS DU HOOK --- */}
            <div className="p-6 border-t border-slate-200 bg-slate-50 flex flex-col gap-3">
              
              {/* Action Intermédiaire : Validation d'identité */}
              {!selectedVendor.identityVerified && (
                <button
                  onClick={() => verifyIdentityMutation.mutate({ id: selectedVendor.vendorProfileId, notes: "Validation administrative de la pièce d'identité" })}
                  disabled={verifyIdentityMutation.isPending}
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2.5 px-4 rounded-xl text-sm transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
                >
                  {verifyIdentityMutation.isPending && <RefreshCw className="w-4 h-4 animate-spin" />}
                  Valider la Pièce d'Identité (CIN)
                </button>
              )}

              {/* État : Marchand en attente d'approbation globale (isApproved === false) */}
              {!selectedVendor.isApproved && (
                <div className="flex gap-3">
                  <button
                    onClick={() => approveMutation.mutate({ id: selectedVendor.vendorProfileId, notes: "Boutique officiellement validée" })}
                    disabled={approveMutation.isPending}
                    className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-2.5 px-4 rounded-xl text-sm transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
                  >
                    {approveMutation.isPending && <RefreshCw className="w-4 h-4 animate-spin" />}
                    Approuver et Activer
                  </button>

                  <button
                    onClick={() => {
                      const motif = prompt("Saisissez obligatoirement le motif du rejet :");
                      if (motif && motif.trim() !== "") {
                        rejectMutation.mutate({ id: selectedVendor.vendorProfileId, notes: motif });
                      }
                    }}
                    disabled={rejectMutation.isPending}
                    className="flex-1 bg-rose-600 hover:bg-rose-700 text-white font-semibold py-2.5 px-4 rounded-xl text-sm transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
                  >
                    {rejectMutation.isPending && <RefreshCw className="w-4 h-4 animate-spin" />}
                    Rejeter le dossier
                  </button>
                </div>
              )}

              {/* État : Marchand déjà actif / approuvé */}
              {selectedVendor.isApproved && (
                <div className="flex gap-3">
                  <button
                    onClick={() => resetPendingMutation.mutate({ id: selectedVendor.vendorProfileId, notes: "Rétrogradation temporaire en attente de complément" })}
                    disabled={resetPendingMutation.isPending}
                    className="flex-1 bg-amber-50 hover:bg-amber-100 text-amber-700 border border-amber-200 font-semibold py-2.5 px-4 rounded-xl text-sm transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
                  >
                    {resetPendingMutation.isPending && <RefreshCw className="w-4 h-4 animate-spin" />}
                    Remettre en attente
                  </button>

                  <button
                    onClick={() => {
                      const motif = prompt("Indiquez la raison du blocage ou de la suspension :");
                      if (motif && motif.trim() !== "") {
                        rejectMutation.mutate({ id: selectedVendor.vendorProfileId, notes: motif });
                      }
                    }}
                    disabled={rejectMutation.isPending}
                    className="flex-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 font-semibold py-2.5 px-4 rounded-xl text-sm transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
                  >
                    {rejectMutation.isPending && <RefreshCw className="w-4 h-4 animate-spin" />}
                    Suspendre le compte
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}