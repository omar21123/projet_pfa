import { useState } from "react";
import { Eye, RefreshCw, Tag, X } from "lucide-react";
import { usePromotion, usePromotionList, usePromotionLookups } from "@/hooks/usePromotions";
import type { Promotion, PromotionListParams } from "@/types/promotion";

const formatDate = (value: string) => {
  const date = new Date(value.includes(" ") ? value.replace(" ", "T") : value);
  return Number.isNaN(date.getTime())
    ? value
    : new Intl.DateTimeFormat("fr-FR", { dateStyle: "short", timeStyle: "short" }).format(date);
};

const formatDiscount = (promotion: Promotion) =>
  promotion.discount_type.code === "PERCENTAGE"
    ? `${promotion.discount_value}%`
    : `${promotion.discount_value.toFixed(2)} DH`;

const getErrorMessage = (error: unknown) => {
  if (error && typeof error === "object" && "response" in error) {
    const response = (error as { response?: { data?: { message?: string } } }).response;
    return response?.data?.message ?? "Impossible de récupérer les promotions.";
  }
  return "Impossible de récupérer les promotions.";
};

export default function PromotionsPage() {
  const [filters, setFilters] = useState<PromotionListParams>({ page: 1, page_size: 20 });
  const [selectedId, setSelectedId] = useState<number | null>(null);

  const lookups = usePromotionLookups();
  const promotions = usePromotionList(filters);
  const details = usePromotion(selectedId);

  const rows = promotions.data?.data ?? [];

  const updateFilter = (next: Partial<PromotionListParams>) => {
    setFilters((current) => ({ ...current, ...next, page: 1 }));
  };

  const resetFilters = () => setFilters({ page: 1, page_size: 20 });

  return (
    <section className="space-y-6">
      {/* En-tête */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="rounded-xl bg-[#E8F4E1] p-3 text-[#124E54]">
            <Tag className="h-6 w-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Promotions</h1>
            <p className="text-sm text-slate-500">Gestion des promotions produit et catégorie</p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => void promotions.refetch()}
          className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm hover:bg-slate-50"
        >
          <RefreshCw className={`h-4 w-4 ${promotions.isFetching ? "animate-spin" : ""}`} />
          Actualiser
        </button>
      </div>

      {/* Filtres */}
      <div className="grid gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:grid-cols-4">
        <label className="text-xs font-semibold text-slate-600">
          Statut
          <select
            value={filters.status ?? ""}
            onChange={(e) => updateFilter({ status: e.target.value || undefined })}
            className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-normal text-slate-700"
          >
            <option value="">Tous les statuts</option>
            {(lookups.data?.statuses ?? []).map((status) => (
              <option key={status.code} value={status.code}>{status.label}</option>
            ))}
          </select>
        </label>
        <label className="text-xs font-semibold text-slate-600">
          Portée
          <select
            value={filters.scope ?? ""}
            onChange={(e) => updateFilter({ scope: (e.target.value || undefined) as PromotionListParams["scope"] })}
            className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-normal text-slate-700"
          >
            <option value="">Toutes les portées</option>
            {(lookups.data?.scope_types ?? []).map((scope) => (
              <option key={scope.code} value={scope.code}>{scope.label}</option>
            ))}
          </select>
        </label>
        <label className="text-xs font-semibold text-slate-600">
          État actif
          <select
            value={filters.is_active === undefined ? "" : String(filters.is_active)}
            onChange={(e) => updateFilter({ is_active: e.target.value === "" ? undefined : (Number(e.target.value) as 0 | 1) })}
            className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-normal text-slate-700"
          >
            <option value="">Tous</option>
            <option value="1">Actives</option>
            <option value="0">Inactives</option>
          </select>
        </label>
        <button
          type="button"
          onClick={resetFilters}
          className="self-end rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50"
        >
          Réinitialiser
        </button>
      </div>

      {promotions.isError && (
        <div className="flex items-center justify-between rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700">
          <span>{getErrorMessage(promotions.error)}</span>
          <button type="button" onClick={() => void promotions.refetch()} className="font-bold underline">
            Réessayer
          </button>
        </div>
      )}

      {/* Tableau des promotions */}
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[920px] text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-5 py-4">Promotion</th>
                <th className="px-5 py-4">Portée</th>
                <th className="px-5 py-4">Réduction</th>
                <th className="px-5 py-4">Période</th>
                <th className="px-5 py-4">Statut</th>
                <th className="px-5 py-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {promotions.isPending && (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-slate-500">
                    Chargement des promotions...
                  </td>
                </tr>
              )}
              {!promotions.isPending && rows.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-12 text-center text-slate-500">
                    Aucune promotion trouvée.
                  </td>
                </tr>
              )}
              {rows.map((promotion) => (
                <tr key={promotion.promotion_id} className="hover:bg-slate-50/70">
                  <td className="px-5 py-4">
                    <div className="font-bold text-slate-800">{promotion.name}</div>
                    <div className="mt-1 text-xs text-slate-500">
                      {promotion.promo_code ? `Code : ${promotion.promo_code}` : "Sans code promo"} · #{promotion.promotion_id}
                    </div>
                  </td>
                  <td className="px-5 py-4">
                    <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700">
                      {promotion.scope_type.label}
                    </span>
                    <div className="mt-1 text-xs text-slate-500">
                      {promotion.product_name || promotion.category_name || (promotion.target_product_id ? `Produit #${promotion.target_product_id}` : `Catégorie #${promotion.target_category_id ?? "—"}`)}
                    </div>
                  </td>
                  <td className="px-5 py-4 font-bold text-emerald-700">{formatDiscount(promotion)}</td>
                  <td className="px-5 py-4 text-xs text-slate-600">
                    <div>{formatDate(promotion.start_date)}</div>
                    <div>au {formatDate(promotion.end_date)}</div>
                  </td>
                  <td className="px-5 py-4">
                    <span
                      className={`rounded-full px-2.5 py-1 text-xs font-bold ${
                        promotion.is_active ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500"
                      }`}
                    >
                      {promotion.status.label}
                    </span>
                  </td>
                  <td className="px-5 py-4 text-right">
                    <button
                      type="button"
                      onClick={() => setSelectedId(promotion.promotion_id)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50"
                    >
                      <Eye className="h-4 w-4" /> Détails
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between border-t border-slate-100 px-5 py-4 text-sm text-slate-500">
          <span>Page {promotions.data?.meta.page ?? filters.page ?? 1}</span>
          <button
            type="button"
            disabled={!promotions.data?.meta.has_more || promotions.isFetching}
            onClick={() => setFilters((current) => ({ ...current, page: (current.page ?? 1) + 1 }))}
            className="rounded-lg border border-slate-200 px-3 py-2 font-semibold text-slate-700 disabled:cursor-not-allowed disabled:opacity-40"
          >
            Page suivante
          </button>
        </div>
      </div>

      {/* Modale de Détails Améliorée et Complète */}
      {selectedId !== null && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4"
          role="dialog"
          aria-modal="true"
          aria-label="Détails de la promotion"
        >
          <div className="max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl">
            <div className="mb-5 flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <h2 className="text-lg font-bold text-slate-900">
                  Détails de la promotion #{selectedId}
                </h2>
                <p className="text-xs text-slate-500">Informations complètes reçues de l'API</p>
              </div>
              <button
                type="button"
                onClick={() => setSelectedId(null)}
                aria-label="Fermer"
                className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {details.isPending && <p className="py-8 text-center text-sm text-slate-500">Chargement des détails...</p>}
            {details.isError && <p className="text-sm text-rose-600">{getErrorMessage(details.error)}</p>}

            {details.data?.data && (
              <div className="space-y-5 text-sm">
                {/* Informations Générales */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <span className="text-xs font-medium text-slate-500">Nom de la promotion</span>
                    <p className="font-semibold text-slate-900">{details.data.data.name}</p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Code promo</span>
                    <p className="font-mono font-semibold text-slate-800">
                      {details.data.data.promo_code || "Aucun code"}
                    </p>
                  </div>
                  <div className="sm:col-span-2">
                    <span className="text-xs font-medium text-slate-500">Description</span>
                    <p className="text-slate-700">{details.data.data.description || "Aucune description"}</p>
                  </div>
                </div>

                <hr className="border-slate-100" />

                {/* Réduction & Cible */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <span className="text-xs font-medium text-slate-500">Réduction</span>
                    <p className="font-bold text-emerald-700">
                      {formatDiscount(details.data.data)} ({details.data.data.discount_type.label})
                    </p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Cible ({details.data.data.scope_type.label})</span>
                    <p className="font-semibold text-slate-800">
                      {details.data.data.product_name || details.data.data.category_name || (details.data.data.target_product_id ? `Produit #${details.data.data.target_product_id}` : `Catégorie #${details.data.data.target_category_id ?? "—"}`)}
                    </p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Remise Maximale</span>
                    <p className="text-slate-700">
                      {details.data.data.max_discount_amount ? `${details.data.data.max_discount_amount.toFixed(2)} DH` : "Sans limite"}
                    </p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Commande Minimum</span>
                    <p className="text-slate-700">
                      {details.data.data.min_order_amount ? `${details.data.data.min_order_amount.toFixed(2)} DH` : "Aucun minimum"}
                    </p>
                  </div>
                </div>

                <hr className="border-slate-100" />

                {/* Statut, Période & Limites */}
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <span className="text-xs font-medium text-slate-500">Statut & Actif</span>
                    <div className="mt-1 flex items-center gap-2">
                      <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-700">
                        {details.data.data.status.label}
                      </span>
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${
                          details.data.data.is_active ? "bg-emerald-100 text-emerald-800" : "bg-rose-100 text-rose-800"
                        }`}
                      >
                        {details.data.data.is_active ? "Actif" : "Inactif"}
                      </span>
                    </div>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Utilisations</span>
                    <p className="font-semibold text-slate-800">
                      {details.data.data.usage_count} / {details.data.data.usage_limit_total ?? "∞"}{" "}
                      <span className="text-xs text-slate-500">(Max/user : {details.data.data.usage_limit_per_user ?? "∞"})</span>
                    </p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Période de validité</span>
                    <p className="text-xs text-slate-700">
                      Du {formatDate(details.data.data.start_date)} <br />
                      au {formatDate(details.data.data.end_date)}
                    </p>
                  </div>
                  <div>
                    <span className="text-xs font-medium text-slate-500">Créée le</span>
                    <p className="text-xs text-slate-700">{formatDate(details.data.data.created_at)}</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </section>
  );
}
