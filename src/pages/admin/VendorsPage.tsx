import { useEffect, useState } from "react";
import {
  Search, Star, Mail, ShieldCheck, ShieldOff, Check, X, RotateCcw,
  Eye, Package, ClipboardList, CircleDollarSign, ChevronLeft, ChevronRight, AlertCircle, Trash2
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge"; // Ou utilise des spans stylisés si pas de shadcn

import {
  useVendorsList, useVerifyVendorIdentity, useApproveVendor, useRejectVendor,
  useResetVendorToPending,
} from "@/hooks/useVendors";
import {
  VendorProfile, VendorListFilters, VendorVerificationStatus, VERIFICATION_STATUS_LABEL,
} from "@/types/vendor.types";

// Helper de couleur pour les statuts
function getStatusBadgeClass(status: VendorVerificationStatus) {
  if (status === 1) return "bg-emerald-50 text-emerald-700 border-emerald-200"; // Approuvé
  if (status === 2) return "bg-rose-50 text-rose-700 border-rose-200"; // Rejeté
  return "bg-amber-50 text-amber-700 border-amber-200"; // En attente
}

function formatCurrency(value: number) {
  return `${value.toLocaleString("fr-FR")} DH`;
}

// ============================================================
// MODALE COMMUNE (Notes optionnelles / obligatoires)
// ============================================================
function NotesModal({
  title,
  description,
  confirmLabel,
  confirmVariant = "default",
  requireNotes = false,
  onClose,
  onConfirm,
}: {
  title: string;
  description: string;
  confirmLabel: string;
  confirmVariant?: "default" | "destructive" | "success";
  requireNotes?: boolean;
  onClose: () => void;
  onConfirm: (notes: string) => void;
}) {
  const [notes, setNotes] = useState("");
  const isDisabled = requireNotes ? !notes.trim() : false;

  const btnColorClass = 
    confirmVariant === "destructive" ? "bg-rose-600 hover:bg-rose-700 text-white" :
    confirmVariant === "success" ? "bg-emerald-600 hover:bg-emerald-700 text-white" :
    "bg-indigo-600 hover:bg-indigo-700 text-white";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4">
      <div className="w-full max-w-md bg-white rounded-xl border border-slate-200 p-6 shadow-xl animate-in fade-in zoom-in duration-200">
        <h3 className="text-lg font-bold text-slate-900 mb-1">{title}</h3>
        <p className="text-slate-500 text-sm mb-4 leading-relaxed">{description}</p>

        <label className="block text-xs font-semibold text-slate-600 mb-1.5 uppercase tracking-wider">
          Notes {requireNotes ? <span className="text-rose-500">*</span> : "(optionnel)"}
        </label>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={3}
          placeholder="Ajoutez un commentaire pour l'historique du vendeur..."
          className="w-full rounded-lg border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none mb-6"
        />

        <div className="flex justify-end gap-3">
          <Button variant="outline" onClick={onClose} className="border-slate-200 text-slate-600 hover:bg-slate-50">
            Annuler
          </Button>
          <Button 
            onClick={() => onConfirm(notes.trim())} 
            disabled={isDisabled}
            className={btnColorClass}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// PANNEAU DE DÉTAILS LATÉRAL (Drawer)
// ============================================================
function VendorDetailPanel({
  vendor,
  onClose,
  onVerifyIdentity,
  onApprove,
  onReject,
  onReset,
}: {
  vendor: VendorProfile;
  onClose: () => void;
  onVerifyIdentity: () => void;
  onApprove: () => void;
  onReject: () => void;
  onReset: () => void;
}) {
  const canApprove = vendor.identity_verified && vendor.business_verified && vendor.bank_verified;

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex justify-end" onClick={onClose}>
      <div 
        onClick={(e) => e.stopPropagation()} 
        className="w-full max-w-md bg-white h-full overflow-y-auto p-6 shadow-2xl flex flex-col gap-6 animate-in slide-in-from-right duration-200"
      >
        <button onClick={onClose} className="self-start text-slate-500 hover:text-slate-800 text-sm font-medium flex items-center gap-1">
          ← Fermer le profil
        </button>

        {/* En-tête profil */}
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center text-xl font-bold border border-indigo-100">
            {vendor.store_name.charAt(0).toUpperCase()}
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900">{vendor.store_name}</h2>
            <p className="text-slate-500 text-sm flex items-center gap-1.5 mt-0.5">
              <Mail className="w-3.5 h-3.5 text-slate-400" /> {vendor.email}
            </p>
          </div>
        </div>

        {/* Badges de statuts */}
        <div className="flex gap-2">
          <Badge className={`px-2.5 py-1 text-xs font-semibold border ${getStatusBadgeClass(vendor.verification_status)}`}>
            {VERIFICATION_STATUS_LABEL[vendor.verification_status]}
          </Badge>
          {vendor.is_suspended && (
            <Badge className="bg-rose-50 text-rose-700 border border-rose-200">Suspendu</Badge>
          )}
        </div>

        {/* Statistiques clés */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-slate-50 p-3 rounded-lg text-center border border-slate-100">
            <Package className="w-4 h-4 text-indigo-600 mx-auto mb-1" />
            <div className="text-lg font-bold text-slate-900">{vendor.stats.products_count}</div>
            <div className="text-[10px] uppercase font-semibold text-slate-400 tracking-wider">Produits</div>
          </div>
          <div className="bg-slate-50 p-3 rounded-lg text-center border border-slate-100">
            <ClipboardList className="w-4 h-4 text-amber-600 mx-auto mb-1" />
            <div className="text-lg font-bold text-slate-900">{vendor.stats.orders_count}</div>
            <div className="text-[10px] uppercase font-semibold text-slate-400 tracking-wider">Commandes</div>
          </div>
          <div className="bg-slate-50 p-3 rounded-lg text-center border border-slate-100">
            <CircleDollarSign className="w-4 h-4 text-emerald-600 mx-auto mb-1" />
            <div className="text-xs font-bold text-slate-900 overflow-hidden text-ellipsis whitespace-nowrap">
              {formatCurrency(vendor.stats.revenue)}
            </div>
            <div className="text-[10px] uppercase font-semibold text-slate-400 tracking-wider">Revenus</div>
          </div>
        </div>

        {/* Étapes de vérification */}
        <div>
          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2.5">Vérifications Requises</h4>
          <div className="flex flex-col gap-2">
            {[
              { label: "Identité", ok: vendor.identity_verified },
              { label: "Entreprise (Registre commerce)", ok: vendor.business_verified },
              { label: "Données bancaires", ok: vendor.bank_verified },
            ].map((item, idx) => (
              <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-100">
                <span className="text-sm font-medium text-slate-700">{item.label}</span>
                <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold ${
                  item.ok ? "bg-emerald-50 text-emerald-700" : "bg-amber-50 text-amber-700"
                }`}>
                  {item.ok ? "Vérifié" : "En attente"}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Historique de notes si existantes */}
        {vendor.verification_notes && (
          <div className="p-3 bg-slate-50 rounded-lg border border-slate-100 text-sm">
            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">Notes de vérification</h4>
            <p className="text-slate-700 leading-relaxed">{vendor.verification_notes}</p>
          </div>
        )}
        {vendor.rejection_notes && (
          <div className="p-3 bg-rose-50/50 rounded-lg border border-rose-100 text-sm text-rose-800">
            <h4 className="text-xs font-bold text-rose-500 uppercase tracking-wider mb-1">Motif du rejet</h4>
            <p className="leading-relaxed">{vendor.rejection_notes}</p>
          </div>
        )}

        {/* Actions sur le vendeur */}
        <div className="mt-auto flex flex-col gap-2 pt-6 border-t border-slate-100">
          {!vendor.identity_verified && (
            <Button onClick={onVerifyIdentity} className="w-full bg-indigo-600 hover:bg-indigo-700 text-white gap-2">
              <ShieldCheck className="w-4 h-4" /> Vérifier l'identité
            </Button>
          )}

          {vendor.verification_status !== 1 && (
            <div className="w-full">
              <Button 
                disabled={!canApprove} 
                onClick={onApprove} 
                className={`w-full gap-2 ${canApprove ? "bg-emerald-600 hover:bg-emerald-700 text-white" : "bg-slate-200 text-slate-400 cursor-not-allowed"}`}
              >
                <Check className="w-4 h-4" /> Approuver le vendeur
              </Button>
              {!canApprove && (
                <p className="text-[10px] text-slate-400 text-center mt-1">
                  L'identité, l'entreprise et la banque doivent être vérifiées.
                </p>
              )}
            </div>
          )}

          {vendor.verification_status !== 2 && (
            <Button onClick={onReject} variant="outline" className="w-full text-rose-600 hover:bg-rose-50 hover:text-rose-700 border-slate-200">
              <X className="w-4 h-4" /> Rejeter le vendeur
            </Button>
          )}

          {vendor.verification_status !== 0 && (
            <Button onClick={onReset} variant="ghost" className="w-full text-slate-600 hover:bg-slate-100">
              <RotateCcw className="w-4 h-4" /> Remettre en attente
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

// ============================================================
// PAGE PRINCIPALE VENDORS
// ============================================================
export default function VendorsPage() {
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<VendorVerificationStatus | "tous">("tous");
  const [suspendedFilter, setSuspendedFilter] = useState<0 | 1 | "tous">("tous");
  const [page, setPage] = useState(1);

  const [detailId, setDetailId] = useState<number | null>(null);
  const [rejectTarget, setRejectTarget] = useState<VendorProfile | null>(null);
  const [resetTarget, setResetTarget] = useState<VendorProfile | null>(null);
  const [verifyTarget, setVerifyTarget] = useState<VendorProfile | null>(null);
  const [approveTarget, setApproveTarget] = useState<VendorProfile | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  // Debounce de la recherche
  useEffect(() => {
    const delay = setTimeout(() => {
      setSearch(searchInput);
      setPage(1);
    }, 400);
    return () => clearTimeout(delay);
  }, [searchInput]);

  const filters: VendorListFilters = {
    search: search || undefined,
    verification_status: statusFilter === "tous" ? undefined : statusFilter,
    is_suspended: suspendedFilter === "tous" ? undefined : suspendedFilter,
    page,
    page_size: 20,
  };

  // Tes hooks d'API existants
  const { data, isLoading, isError } = useVendorsList(filters);
  const verifyIdentity = useVerifyVendorIdentity();
  const approve = useApproveVendor();
  const reject = useRejectVendor();
  const reset = useResetVendorToPending();

  const vendors = data?.data.items ?? [];
  const pagination = data?.data.pagination;
  const detailVendor = vendors.find((v) => v.id === detailId) ?? null;

  function notify(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  }

  // Statistiques locales de la page en cours
  const stats = {
    pending: vendors.filter((v) => v.verification_status === 0).length,
    approved: vendors.filter((v) => v.verification_status === 1).length,
    suspended: vendors.filter((v) => v.is_suspended).length,
  };

  return (
    <div className="space-y-6">
      {/* En-tête */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Vendeurs & Partenaires</h1>
          <p className="text-slate-500 text-sm">
            {pagination ? `${pagination.total} vendeur(s) enregistré(s) au total` : "Calcul de l'effectif..."}
          </p>
        </div>
      </div>

      {/* Cartes Statutaires de la page */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">En attente (page)</span>
            <div className="text-2xl font-bold text-slate-900 mt-1">{stats.pending}</div>
          </div>
          <div className="p-3 rounded-lg bg-amber-50 text-amber-600">
            <ClipboardList className="w-5 h-5" />
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Approuvés (page)</span>
            <div className="text-2xl font-bold text-slate-900 mt-1">{stats.approved}</div>
          </div>
          <div className="p-3 rounded-lg bg-emerald-50 text-emerald-600">
            <ShieldCheck className="w-5 h-5" />
          </div>
        </div>
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Suspendus (page)</span>
            <div className="text-2xl font-bold text-slate-900 mt-1">{stats.suspended}</div>
          </div>
          <div className="p-3 rounded-lg bg-rose-50 text-rose-600">
            <ShieldOff className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filtres & Recherche */}
      <div className="flex flex-col md:flex-row gap-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <Input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Rechercher par boutique ou adresse e-mail..."
            className="pl-9 bg-slate-50 border-slate-200"
          />
        </div>
        <div className="flex gap-2">
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value === "tous" ? "tous" : (Number(e.target.value) as VendorVerificationStatus)); setPage(1); }}
            className="px-3 py-2 rounded-lg border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="tous">Tous les statuts de vérification</option>
            <option value={0}>En attente</option>
            <option value={1}>Approuvé</option>
            <option value={2}>Rejeté</option>
          </select>
          <select
            value={suspendedFilter}
            onChange={(e) => { setSuspendedFilter(e.target.value === "tous" ? "tous" : (Number(e.target.value) as 0 | 1)); setPage(1); }}
            className="px-3 py-2 rounded-lg border border-slate-200 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="tous">Tous les comptes</option>
            <option value={0}>Actifs</option>
            <option value={1}>Suspendus</option>
          </select>
        </div>
      </div>

      {/* Tableau des Vendeurs */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading && (
          <div className="py-12 text-center text-slate-400 text-sm">Chargement des vendeurs...</div>
        )}
        {isError && (
          <div className="py-12 text-center text-rose-500 text-sm">
            Une erreur est survenue lors de la récupération des vendeurs. Réessayez plus tard.
          </div>
        )}
        {!isLoading && !isError && vendors.length === 0 && (
          <div className="py-12 text-center text-slate-400 text-sm">
            Aucun vendeur ne correspond aux critères définis.
          </div>
        )}

        {!isLoading && !isError && vendors.length > 0 && (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                  <th className="py-4 px-6">Boutique</th>
                  <th className="py-4 px-6">Indicateurs</th>
                  <th className="py-4 px-6 text-right">Chiffre d'Affaires</th>
                  <th className="py-4 px-6 text-center">Statut</th>
                  <th className="py-4 px-6 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
                {vendors.map((v) => (
                  <tr key={v.id} className={`hover:bg-slate-50/50 transition-colors ${v.is_suspended ? "opacity-60" : ""}`}>
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center font-bold">
                          {v.store_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-900">{v.store_name}</div>
                          <div className="text-xs text-slate-400 flex items-center gap-1"><Mail className="w-3 h-3" /> {v.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3 text-slate-500 text-xs">
                        <span className="flex items-center gap-1"><Package className="w-3.5 h-3.5 text-slate-400" /> {v.stats.products_count} prod.</span>
                        <span className="flex items-center gap-1"><Star className="w-3.5 h-3.5 text-slate-400" /> {v.stats.orders_count} cmd.</span>
                      </div>
                    </td>
                    <td className="py-4 px-6 text-right font-semibold text-slate-900 font-mono">
                      {formatCurrency(v.stats.revenue)}
                    </td>
                    <td className="py-4 px-6 text-center">
                      <Badge className={`px-2.5 py-0.5 text-xs font-semibold border ${getStatusBadgeClass(v.verification_status)}`}>
                        {VERIFICATION_STATUS_LABEL[v.verification_status]}
                      </Badge>
                    </td>
                    <td className="py-4 px-6 text-right space-x-1.5 whitespace-nowrap">
                      {/* Voir Détails */}
                      <Button variant="ghost" size="icon" onClick={() => setDetailId(v.id)} title="Voir les détails">
                        <Eye className="w-4 h-4 text-slate-600" />
                      </Button>

                      {/* Vérifier l'identité */}
                      {!v.identity_verified && (
                        <Button variant="ghost" size="icon" className="text-indigo-600 hover:bg-indigo-50" onClick={() => setVerifyTarget(v)} title="Vérifier l'identité">
                          <ShieldCheck className="w-4 h-4" />
                        </Button>
                      )}

                      {/* Approuver */}
                      {v.verification_status !== 1 && (
                        <Button 
                          variant="ghost" 
                          size="icon" 
                          className="text-emerald-600 hover:bg-emerald-50 disabled:opacity-30" 
                          disabled={!(v.identity_verified && v.business_verified && v.bank_verified)}
                          onClick={() => setApproveTarget(v)} 
                          title="Approuver le vendeur"
                        >
                          <Check className="w-4 h-4" />
                        </Button>
                      )}

                      {/* Rejeter */}
                      {v.verification_status !== 2 && (
                        <Button variant="ghost" size="icon" className="text-rose-600 hover:bg-rose-50" onClick={() => setRejectTarget(v)} title="Rejeter le vendeur">
                          <X className="w-4 h-4" />
                        </Button>
                      )}

                      {/* Remettre en attente */}
                      {v.verification_status !== 0 && (
                        <Button variant="ghost" size="icon" className="text-slate-500 hover:bg-slate-100" onClick={() => setResetTarget(v)} title="Remettre en attente">
                          <RotateCcw className="w-4 h-4" />
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {pagination && pagination.total_pages > 1 && (
        <div className="flex justify-center items-center gap-4 mt-6">
          <Button 
            variant="outline" 
            size="icon" 
            disabled={page <= 1} 
            onClick={() => setPage((p) => p - 1)}
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <span className="text-sm text-slate-500 font-medium">
            Page {pagination.current_page} / {pagination.total_pages}
          </span>
          <Button 
            variant="outline" 
            size="icon" 
            disabled={page >= pagination.total_pages} 
            onClick={() => setPage((p) => p + 1)}
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      )}

      {/* MODALE ET DRAWER CONDITIONNELS */}
      {detailVendor && (
        <VendorDetailPanel
          vendor={detailVendor}
          onClose={() => setDetailId(null)}
          onVerifyIdentity={() => setVerifyTarget(detailVendor)}
          onApprove={() => setApproveTarget(detailVendor)}
          onReject={() => setRejectTarget(detailVendor)}
          onReset={() => setResetTarget(detailVendor)}
        />
      )}

      {verifyTarget && (
        <NotesModal
          title="Vérifier l'identité"
          description={`Confirmer que les pièces justificatives d'identité de « ${verifyTarget.store_name} » ont bien été vérifiées de votre côté.`}
          confirmLabel="Confirmer l'identité"
          onClose={() => setVerifyTarget(null)}
          onConfirm={(notes) => {
            verifyIdentity.mutate(
              { id: verifyTarget.id, notes: notes || undefined },
              { onSuccess: () => notify(`Identité de « ${verifyTarget.store_name} » validée avec succès.`) }
            );
            setVerifyTarget(null);
          }}
        />
      )}

      {approveTarget && (
        <NotesModal
          title="Approuver le vendeur"
          description={`« ${approveTarget.store_name} » recevra un e-mail d'activation pour commencer à vendre.`}
          confirmLabel="Approuver"
          confirmVariant="success"
          onClose={() => setApproveTarget(null)}
          onConfirm={(notes) => {
            approve.mutate(
              { id: approveTarget.id, notes: notes || undefined },
              { onSuccess: () => notify(`Le vendeur « ${approveTarget.store_name} » est maintenant en ligne.`) }
            );
            setApproveTarget(null);
          }}
        />
      )}

      {rejectTarget && (
        <NotesModal
          title="Rejeter la demande"
          description={`Un e-mail explicatif sera envoyé à « ${rejectTarget.store_name} ». Le motif est obligatoire.`}
          confirmLabel="Confirmer le rejet"
          confirmVariant="destructive"
          requireNotes
          onClose={() => setRejectTarget(null)}
          onConfirm={(notes) => {
            reject.mutate(
              { id: rejectTarget.id, notes },
              { onSuccess: () => notify(`La demande de « ${rejectTarget.store_name} » a été rejetée.`) }
            );
            setRejectTarget(null);
          }}
        />
      )}

      {resetTarget && (
        <NotesModal
          title="Remettre en attente"
          description={`Le vendeur « ${resetTarget.store_name} » sera de nouveau mis en instruction et ne pourra plus publier.`}
          confirmLabel="Remettre en attente"
          onClose={() => setResetTarget(null)}
          onConfirm={(notes) => {
            reset.mutate(
              { id: resetTarget.id, notes: notes || undefined },
              { onSuccess: () => notify(`Le statut de « ${resetTarget.store_name} » a été réinitialisé.`) }
            );
            setResetTarget(null);
          }}
        />
      )}

      {/* Toast Notification Simple */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 bg-slate-900 text-white px-5 py-3 rounded-lg shadow-xl text-sm font-medium animate-in slide-in-from-bottom duration-300">
          {toast}
        </div>
      )}
    </div>
  );
}