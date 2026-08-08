import React, { useState, useEffect, useCallback } from "react";
import { moderationApi } from "@/api/moderationApi";
import { ImageWithFallback } from "./ImageWithFallback";
import { CombinationDetailModal } from "./CombinationDetailModal";
import { isValidId } from "@/utils/validation";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { VendorCombination, VendorCombinationOption } from "@/types/prodcut";

interface Props {
  productId: number | null;
  productName: string;
  isOpen: boolean;
  onClose: () => void;
  onOpenPromo: (combo: VendorCombination) => void;
}

type FetchState = "idle" | "loading" | "success" | "error" | "invalid";

export const VendorCombinationsModal: React.FC<Props> = ({
  productId,
  productName,
  isOpen,
  onClose,
  onOpenPromo,
}) => {
  const [combinations, setCombinations] = useState<VendorCombination[]>([]);
  const [fetchState, setFetchState] = useState<FetchState>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const [selectedComboId, setSelectedComboId] = useState<number | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState<boolean>(false);

  const fetchCombinations = useCallback(async () => {
    if (!isValidId(productId)) {
      setFetchState("invalid");
      setErrorMessage("Identifiant produit invalide.");
      return;
    }

    setFetchState("loading");
    setErrorMessage("");

    try {
      const response = await moderationApi.getProductCombinations(productId);
      setCombinations(response.data || []);
      setFetchState("success");
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 404) {
        setErrorMessage("Combinaisons introuvables pour ce produit.");
      } else {
        setErrorMessage("Erreur lors de la récupération des combinaisons.");
      }
      setCombinations([]);
      setFetchState("error");
    }
  }, [productId]);

  useEffect(() => {
    if (isOpen) {
      setCombinations([]);
      setFetchState("idle");
      setErrorMessage("");
      fetchCombinations();
    }
  }, [isOpen, fetchCombinations]);

  const handleOpenDetail = (comboId: number) => {
    if (!comboId) return;
    setSelectedComboId(comboId);
    setIsDetailOpen(true);
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
        <div className="bg-white rounded-2xl max-w-3xl w-full p-6 shadow-2xl border border-slate-200 max-h-[90vh] flex flex-col">
          <div className="flex justify-between items-center border-b border-slate-100 pb-4">
            <div>
              <h3 className="text-lg font-bold text-slate-800">Combinaisons & Variantes SKU</h3>
              <p className="text-xs text-slate-500">
                Produit : <span className="font-semibold">{productName}</span> (ID: #{productId})
              </p>
            </div>
            <button
              onClick={onClose}
              className="size-8 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 hover:bg-slate-200 flex items-center justify-center font-bold text-lg transition-colors"
            >
              ×
            </button>
          </div>

          <div className="flex-1 overflow-y-auto py-4">
            {fetchState === "loading" && (
              <div className="py-12 text-center text-slate-400 font-medium animate-pulse">
                Chargement des combinaisons...
              </div>
            )}

            {(fetchState === "error" || fetchState === "invalid") && (
              <div className="py-12 text-center">
                <div className="text-rose-500 font-semibold text-sm mb-1">
                  {errorMessage}
                </div>
                <button
                  onClick={fetchCombinations}
                  className="mt-2 px-4 py-1.5 bg-indigo-600 text-white rounded-lg text-xs font-semibold hover:bg-indigo-700"
                >
                  Réessayer
                </button>
              </div>
            )}

            {fetchState === "success" && combinations.length === 0 && (
              <div className="text-center py-8 text-slate-400 text-sm">
                Aucune combinaison enregistrée pour ce produit.
              </div>
            )}

            {fetchState === "success" && combinations.length > 0 && (
              <div className="overflow-hidden border border-slate-200 rounded-xl shadow-sm">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-500 font-bold border-b border-slate-200 uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="p-3">Visuel</th>
                      <th className="p-3">Options</th>
                      <th className="p-3">SKU</th>
                      <th className="p-3">Prix</th>
                      <th className="p-3">Stock</th>
                      <th className="p-3 text-center">Défaut</th>
                      <th className="p-3 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 bg-white">
                    {combinations.map((combo) => {
                      const comboId = combo.combination_id ?? combo.CombinationID ?? combo.id ?? 0;
                      return (
                        <tr key={comboId} className="hover:bg-slate-50/80 transition-colors">
                          <td className="p-3">
                            <div className="size-10 rounded-lg border border-slate-200 bg-slate-50 overflow-hidden flex items-center justify-center">
                              <ImageWithFallback src={getMediaUrl(combo.image_path || combo.ImagePath)} alt={combo.sku || combo.SKU || "Variante"} />
                            </div>
                          </td>
                          <td className="p-3 font-medium text-slate-800">
                            {Array.isArray(combo.options) && combo.options.length > 0 ? (
                              <div className="flex flex-wrap gap-1">
                                {combo.options.map((opt: VendorCombinationOption, idx: number) => (
                                  <span
                                    key={idx}
                                    className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-semibold text-[11px]"
                                  >
                                    {opt.config_name || opt.configName || "Opt"}:{" "}
                                    <span className="text-slate-900">
                                      {opt.option_name || opt.optionName || opt.option_value}
                                    </span>
                                  </span>
                                ))}
                              </div>
                            ) : (
                              <span className="text-slate-400 italic">Variante standard</span>
                            )}
                          </td>
                          <td className="p-3 font-mono text-slate-600">{combo.sku || combo.SKU || "—"}</td>
                          <td className="p-3 font-bold text-slate-900">{combo.price ?? combo.Price ?? 0} DH</td>
                          <td className="p-3 font-semibold text-slate-700">{combo.stock ?? combo.Stock ?? 0} u.</td>
                          <td className="p-3 text-center">
                            {combo.is_default || combo.IsDefault ? (
                              <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">Oui</span>
                            ) : (
                              <span className="text-slate-400 text-[10px]">Non</span>
                            )}
                          </td>
                          <td className="p-3 text-right">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() => handleOpenDetail(comboId)}
                                className="px-2.5 py-1 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-200 rounded-lg text-xs font-semibold transition-colors"
                              >
                                👁️ Voir
                              </button>
                              <button
                                onClick={() => onOpenPromo({ ...combo, product_id: productId ?? undefined })}
                                className="px-2.5 py-1 bg-amber-50 text-amber-700 hover:bg-amber-100 border border-amber-200 rounded-lg text-xs font-semibold transition-colors"
                              >
                                🏷️ Promo
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className="border-t border-slate-100 pt-3 flex justify-end">
            <button
              onClick={onClose}
              className="px-4 py-2 bg-slate-800 text-white rounded-xl text-xs font-semibold hover:bg-slate-700 transition-colors"
            >
              Fermer
            </button>
          </div>
        </div>
      </div>

      <CombinationDetailModal
        combinationId={selectedComboId}
        isOpen={isDetailOpen}
        onClose={() => setIsDetailOpen(false)}
      />
    </>
  );
};
