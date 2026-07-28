import React from "react";
import { VendorProductItem } from "@/types/prodcut";
import { ImageWithFallback } from "./ImageWithFallback";
import { getMediaUrl } from "@/utils/mediaUtils";

interface Props {
  products: VendorProductItem[];
  loading: boolean;
  onViewDetails: (id: number) => void;
  onOpenCombinations: (id: number, name: string) => void;
  onOpenPromo: (product: VendorProductItem) => void;
  onEdit: (id: number) => void;
}

export const MyAdsTable: React.FC<Props> = ({
  products,
  loading,
  onViewDetails,
  onOpenCombinations,
  onOpenPromo,
  onEdit,
}) => {
  if (loading) {
    return (
      <div className="bg-white border border-slate-200 rounded-2xl p-12 text-center text-slate-400 font-semibold animate-pulse shadow-sm">
        Chargement de vos annonces...
      </div>
    );
  }

  if (!products || products.length === 0) {
    return (
      <div className="bg-white border border-slate-200 rounded-2xl p-12 text-center text-slate-500 shadow-sm">
        <div className="text-4xl mb-2">📦</div>
        <h3 className="text-base font-bold text-slate-700">Aucune annonce trouvée</h3>
        <p className="text-xs text-slate-400 mt-1">
          Vous n'avez actuellement aucun produit enregistré dans cette sélection.
        </p>
      </div>
    );
  }

  const renderStatusBadge = (statusNum?: number, statusLabel?: string) => {
    switch (statusNum) {
      case 2:
        return (
          <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-bold">
            Validé
          </span>
        );
      case 3:
        return (
          <span className="px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 border border-rose-200 text-xs font-bold">
            Refusé
          </span>
        );
      case 1:
      default:
        return (
          <span className="px-2.5 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 text-xs font-bold">
            {statusLabel || "En attente"}
          </span>
        );
    }
  };

  return (
    <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs divide-y divide-slate-100">
          <thead className="bg-slate-50/80 text-slate-500 font-bold uppercase text-[10px] tracking-wider border-b border-slate-200">
            <tr>
              <th className="py-3.5 px-4">Visuel</th>
              <th className="py-3.5 px-4">Produit</th>
              <th className="py-3.5 px-4">Prix de base</th>
              <th className="py-3.5 px-4">Stock</th>
              <th className="py-3.5 px-4">Modération</th>
              <th className="py-3.5 px-4">Statut</th>
              <th className="py-3.5 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {products.map((product) => (
              <tr key={product.product_id} className="hover:bg-slate-50/70 transition-colors">
                <td className="py-3 px-4">
                  <div className="size-11 rounded-xl border border-slate-200 bg-slate-50 overflow-hidden flex items-center justify-center">
                    <ImageWithFallback src={getMediaUrl(product.main_image)} alt={product.name} />
                  </div>
                </td>

                <td className="py-3 px-4">
                  <div className="font-bold text-slate-800 text-sm">{product.name}</div>
                  <div className="text-xs text-slate-400 mt-0.5 flex items-center gap-1.5">
                    {product.brand_name && <span>{product.brand_name}</span>}
                    {product.barcode && (
                      <span className="font-mono text-[10px] bg-slate-100 px-1 rounded">
                        #{product.barcode}
                      </span>
                    )}
                  </div>
                </td>

                <td className="py-3 px-4 font-bold text-slate-900 text-sm">
                  {product.base_price ? `${product.base_price.toFixed(2)} DH` : "—"}
                </td>

                <td className="py-3 px-4 font-semibold text-slate-700">
                  <span className={product.stock < 5 ? "text-amber-600 font-bold" : ""}>
                    {product.stock ?? 0} u.
                  </span>
                </td>

                <td className="py-3 px-4">
                  {renderStatusBadge(product.status, product.status_label)}
                </td>

                <td className="py-3 px-4">
                  {product.is_blocked ? (
                    <span className="text-xs font-bold text-rose-600 bg-rose-50 px-2 py-0.5 rounded-full border border-rose-200">
                      🔒 Bloqué
                    </span>
                  ) : (
                    <span
                      className={`text-xs font-bold ${product.is_active ? "text-emerald-600" : "text-slate-400"}`}
                    >
                      {product.is_active ? "● Actif" : "○ Inactif"}
                    </span>
                  )}
                </td>

                <td className="py-3 px-4 text-right">
                  <div className="flex items-center justify-end gap-1.5">
                    <button
                      onClick={() => onViewDetails(product.product_id)}
                      className="px-2.5 py-1.5 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-200 rounded-lg text-xs font-semibold transition-colors"
                    >
                      👁️ Voir
                    </button>

                    <button
                      onClick={() => onOpenCombinations(product.product_id, product.name)}
                      className="px-2.5 py-1.5 bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200 rounded-lg text-xs font-semibold transition-colors"
                    >
                      🔀 Variantes
                    </button>

                    <button
                      onClick={() => onOpenPromo(product)}
                      className="px-2.5 py-1.5 bg-amber-50 text-amber-700 hover:bg-amber-100 border border-amber-200 rounded-lg text-xs font-semibold transition-colors"
                    >
                      🏷️ Promo
                    </button>

                    <button
                      onClick={() => onEdit(product.product_id)}
                      className="px-2.5 py-1.5 bg-slate-800 text-white hover:bg-slate-700 rounded-lg text-xs font-semibold transition-colors"
                    >
                      Éditer
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
