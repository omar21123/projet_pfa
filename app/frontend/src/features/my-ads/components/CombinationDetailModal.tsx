import React, { useState, useEffect, useCallback } from "react";
import { moderationApi } from '@/api/moderationApi';
import { ImageWithFallback } from "./ImageWithFallback";
import { isValidId } from "@/utils/validation";
import { getMediaUrl } from "@/utils/mediaUtils";
import type { VendorCombinationDetail, VendorCombinationOption } from "@/types/prodcut";

interface Props {
  combinationId: number | null;
  isOpen: boolean;
  onClose: () => void;
}

type FetchState = "idle" | "loading" | "success" | "error" | "invalid";

export const CombinationDetailModal: React.FC<Props> = ({
  combinationId,
  isOpen,
  onClose,
}) => {
  const [details, setDetails] = useState<VendorCombinationDetail | null>(null);
  const [fetchState, setFetchState] = useState<FetchState>("idle");
  const [errorMessage, setErrorMessage] = useState("");

  const fetchCombinationDetails = useCallback(async () => {
    if (!isValidId(combinationId)) {
      setFetchState("invalid");
      setErrorMessage("Identifiant de combinaison invalide.");
      return;
    }

    setFetchState("loading");
    setErrorMessage("");

    try {
      const response = await moderationApi.getCombinationDetails(combinationId);
      setDetails(response.data);
      setFetchState("success");
    } catch (err: unknown) {
      const status = (err as { response?: { status?: number } })?.response?.status;
      if (status === 404) {
        setErrorMessage("Combinaison introuvable.");
      } else {
        setErrorMessage("Erreur lors de la récupération des détails.");
      }
      setDetails(null);
      setFetchState("error");
    }
  }, [combinationId]);

  useEffect(() => {
    if (isOpen) {
      setDetails(null);
      setFetchState("idle");
      setErrorMessage("");
      fetchCombinationDetails();
    }
  }, [isOpen, fetchCombinationDetails]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
        <div className="flex justify-between items-center border-b border-slate-100 pb-3 mb-4">
          <div>
            <h3 className="text-base font-bold text-slate-800">
              Détails de la combinaison
            </h3>
            <p className="text-xs text-slate-400">ID: #{combinationId}</p>
          </div>
          <button
            onClick={onClose}
            className="size-7 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 flex items-center justify-center font-bold text-base"
          >
            ✕
          </button>
        </div>

        {fetchState === "loading" && (
          <div className="py-12 text-center text-slate-400 text-xs font-medium animate-pulse">
            Chargement de la combinaison...
          </div>
        )}

        {(fetchState === "error" || fetchState === "invalid") && (
          <div className="py-12 text-center">
            <div className="text-rose-500 font-semibold text-sm mb-1">
              {errorMessage}
            </div>
            <button
              onClick={fetchCombinationDetails}
              className="mt-2 px-4 py-1.5 bg-indigo-600 text-white rounded-lg text-xs font-semibold hover:bg-indigo-700"
            >
              Réessayer
            </button>
          </div>
        )}

        {fetchState === "success" && details && (
          <div className="space-y-4">
            <div className="flex gap-4 items-center bg-slate-50 p-3 rounded-xl border border-slate-100">
              <div className="size-16 rounded-lg border border-slate-200 bg-white overflow-hidden flex-shrink-0">
                <ImageWithFallback
                  src={getMediaUrl(details.ImagePath || details.image_path)}
                  alt={details.SKU || details.sku || "Variante"}
                />
              </div>
              <div className="space-y-0.5">
                <div className="text-xs font-mono font-bold text-slate-700">
                  SKU : {details.SKU || details.sku || "—"}
                </div>
                <div className="text-sm font-bold text-slate-900">
                  {details.Price || details.price} DH
                  {(details.CompareAtPrice || details.compare_at_price) && (
                    <span className="ml-2 text-xs text-slate-400 line-through font-normal">
                      {details.CompareAtPrice || details.compare_at_price} DH
                    </span>
                  )}
                </div>
                <div className="text-xs text-slate-500">
                  Stock : <span className="font-bold text-slate-800">{details.Stock ?? details.stock ?? 0} u.</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">Variante par défaut</span>
                <span className="font-semibold text-slate-700">
                  {details.IsDefault || details.is_default ? "Oui" : "Non"}
                </span>
              </div>
              <div className="bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                <span className="text-slate-400 block text-[10px] uppercase font-bold">État</span>
                <span className="font-semibold text-emerald-600">
                  {details.IsActive || details.is_active ? "● Actif" : "○ Inactif"}
                </span>
              </div>
            </div>

            <div>
              <h4 className="text-xs font-bold text-slate-700 mb-2">Attributs configurés :</h4>
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 space-y-1.5 text-xs">
                {details.ConfigName ? (
                  <div className="flex justify-between">
                    <span className="text-slate-500 font-medium">{details.ConfigName} :</span>
                    <span className="font-bold text-slate-800">{details.OptionName} ({details.OptionValue})</span>
                  </div>
                ) : Array.isArray(details.options) && details.options.length > 0 ? (
                  details.options.map((opt: VendorCombinationOption, idx: number) => (
                    <div key={idx} className="flex justify-between">
                      <span className="text-slate-500 font-medium">{opt.config_name || opt.configName || "Option"} :</span>
                      <span className="font-bold text-slate-800">{opt.option_name || opt.optionName || opt.option_value}</span>
                    </div>
                  ))
                ) : (
                  <p className="text-xs text-slate-400 italic">Aucun attribut spécifique.</p>
                )}
              </div>
            </div>
          </div>
        )}

        <div className="mt-6 text-right">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 text-white rounded-xl text-xs font-semibold hover:bg-slate-700 transition-colors"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
};
