import React, { useState, useEffect } from "react";
import axios from "axios";
import { useCreateProductPromotion } from "@/hooks/usePromotions";
import type { VendorProductItem, VendorCombination } from "@/types/prodcut";
import type { CreateProductPromotionPayload, DiscountTypeCode } from "@/types/promotion";

interface Props {
  product: VendorProductItem | VendorCombination | null;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const VendorPromoModal: React.FC<Props> = ({
  product,
  isOpen,
  onClose,
  onSuccess,
}) => {
  // Champs obligatoires
  const [name, setName] = useState<string>("");
  const [discountType, setDiscountType] = useState<DiscountTypeCode>("PERCENTAGE");
  const [discountValue, setDiscountValue] = useState<string>("");
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");

  // Champs optionnels
  const [description, setDescription] = useState<string>("");
  const [promoCode, setPromoCode] = useState<string>("");
  const [maxDiscountAmount, setMaxDiscountAmount] = useState<string>("");
  const [minOrderAmount, setMinOrderAmount] = useState<string>("");
  const [usageLimitTotal, setUsageLimitTotal] = useState<string>("");
  const [usageLimitPerUser, setUsageLimitPerUser] = useState<string>("");

  const [showAdvanced, setShowAdvanced] = useState<boolean>(false);
  const [apiError, setApiError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string[]>>({});

  const createPromotionMutation = useCreateProductPromotion();

  useEffect(() => {
    if (product && isOpen) {
      setName(`Offre Spéciale - ${product.name || "Produit"}`);
      setDiscountType("PERCENTAGE");
      setDiscountValue("");
      setStartDate("");
      setEndDate("");
      setDescription("");
      setPromoCode("");
      setMaxDiscountAmount("");
      setMinOrderAmount("");
      setUsageLimitTotal("");
      setUsageLimitPerUser("");
      setShowAdvanced(false);
      setApiError(null);
      setFieldErrors({});
    }
  }, [product, isOpen]);

  if (!isOpen || !product) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setApiError(null);
    setFieldErrors({});

    // Formatage strict de la date en YYYY-MM-DD HH:mm:ss
    const formattedStartDate = startDate ? `${startDate} 00:00:00` : "";
    const formattedEndDate = endDate ? `${endDate} 23:59:59` : "";

    // Payload conforme à la documentation Swagger
    const payload: CreateProductPromotionPayload = {
      ProductID: Number("product_id" in product ? product.product_id : product.id),
      Name: name,
      Description: description.trim() || undefined,
      PromoCode: promoCode.trim() ? promoCode.trim().toUpperCase() : undefined,
      DiscountTypeCode: discountType,
      DiscountValue: parseFloat(discountValue),
      MaxDiscountAmount: maxDiscountAmount ? parseFloat(maxDiscountAmount) : undefined,
      MinOrderAmount: minOrderAmount ? parseFloat(minOrderAmount) : undefined,
      UsageLimitTotal: usageLimitTotal ? parseInt(usageLimitTotal, 10) : undefined,
      UsageLimitPerUser: usageLimitPerUser ? parseInt(usageLimitPerUser, 10) : undefined,
      StartDate: formattedStartDate,
      EndDate: formattedEndDate,
    };

    try {
      await createPromotionMutation.mutateAsync(payload);
      onSuccess();
      onClose();
    } catch (error: unknown) {
      if (axios.isAxiosError(error) && error.response?.status === 422) {
        const responseData = error.response.data as {
          message?: string;
          errors?: Record<string, string[]>;
        };
        setApiError(responseData.message || "Données invalides.");
        if (responseData.errors) {
          setFieldErrors(responseData.errors);
        }
      } else {
        setApiError("Une erreur est survenue lors de la création de la promotion.");
      }
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 overflow-y-auto">
      <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 my-8">
        <div className="flex justify-between items-center border-b border-slate-100 pb-3 mb-4">
          <div>
            <h3 className="text-lg font-bold text-slate-800">
              Créer une Promotion
            </h3>
            <p className="text-xs text-slate-500">
              Produit : <span className="font-semibold text-slate-700">{product.name}</span>
            </p>
          </div>
          <button
            onClick={onClose}
            className="size-8 rounded-full bg-slate-100 text-slate-400 hover:text-slate-700 flex items-center justify-center font-bold text-lg"
          >
            ×
          </button>
        </div>

        {/* Message d'erreur API */}
        {apiError && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs">
            <p className="font-bold">{apiError}</p>
            {Object.keys(fieldErrors).length > 0 && (
              <ul className="mt-1 list-disc list-inside space-y-0.5">
                {Object.entries(fieldErrors).map(([field, msgs]) => (
                  <li key={field}>
                    <span className="font-semibold">{field}</span>: {Array.isArray(msgs) ? msgs.join(", ") : msgs}
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Nom de la promotion */}
          <div>
            <label className="block text-xs font-semibold text-slate-600 mb-1">
              Nom de la promotion <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="ex: Soldes d'été -20%"
              className="w-full px-3 py-2 border border-slate-200 rounded-xl text-xs font-medium text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          {/* Type & Valeur */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1">
                Type de réduction <span className="text-rose-500">*</span>
              </label>
              <select
                value={discountType}
                onChange={(e) => setDiscountType(e.target.value as DiscountTypeCode)}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="PERCENTAGE">Pourcentage (%)</option>
                <option value="FIXED_AMOUNT">Montant fixe (DH)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1">
                Valeur <span className="text-rose-500">*</span>
              </label>
              <input
                type="number"
                step="0.01"
                required
                value={discountValue}
                onChange={(e) => setDiscountValue(e.target.value)}
                placeholder={discountType === "PERCENTAGE" ? "ex: 20" : "ex: 50.00"}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-xs font-bold text-emerald-600 focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
          </div>

          {/* Dates de Début et Fin */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1">
                Date de début <span className="text-rose-500">*</span>
              </label>
              <input
                type="date"
                required
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-xs text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1">
                Date de fin <span className="text-rose-500">*</span>
              </label>
              <input
                type="date"
                required
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-xs text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          {/* Toggle Options Avancées */}
          <div className="pt-1">
            <button
              type="button"
              onClick={() => setShowAdvanced(!showAdvanced)}
              className="text-xs font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
            >
              <span>{showAdvanced ? "▼" : "▶"}</span> Options avancées (Code Promo, Limites, Description)
            </button>
          </div>

          {/* Section Options Avancées */}
          {showAdvanced && (
            <div className="space-y-3 pt-2 border-t border-slate-100 bg-slate-50/50 p-3 rounded-xl border">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">
                  Code Promo (Optionnel)
                </label>
                <input
                  type="text"
                  value={promoCode}
                  onChange={(e) => setPromoCode(e.target.value)}
                  placeholder="ex: ETE20"
                  className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-xs font-mono uppercase text-slate-800"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">
                  Description
                </label>
                <textarea
                  rows={2}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Description commerciale de l'offre..."
                  className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-xs text-slate-700"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                    Réduction Max (DH)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={maxDiscountAmount}
                    onChange={(e) => setMaxDiscountAmount(e.target.value)}
                    placeholder="ex: 50"
                    className="w-full px-2.5 py-1.5 border border-slate-200 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                    Commande Min (DH)
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={minOrderAmount}
                    onChange={(e) => setMinOrderAmount(e.target.value)}
                    placeholder="ex: 100"
                    className="w-full px-2.5 py-1.5 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                    Limite d'utilisation globale
                  </label>
                  <input
                    type="number"
                    value={usageLimitTotal}
                    onChange={(e) => setUsageLimitTotal(e.target.value)}
                    placeholder="ex: 500"
                    className="w-full px-2.5 py-1.5 border border-slate-200 rounded-lg text-xs"
                  />
                </div>

                <div>
                  <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                    Limite par client
                  </label>
                  <input
                    type="number"
                    value={usageLimitPerUser}
                    onChange={(e) => setUsageLimitPerUser(e.target.value)}
                    placeholder="ex: 1"
                    className="w-full px-2.5 py-1.5 border border-slate-200 rounded-lg text-xs"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Boutons d'action */}
          <div className="flex gap-2 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 bg-slate-100 text-slate-600 rounded-xl text-xs font-semibold hover:bg-slate-200 transition-colors"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={createPromotionMutation.isPending}
              className="flex-1 py-2.5 bg-emerald-600 text-white rounded-xl text-xs font-bold hover:bg-emerald-700 shadow-md shadow-emerald-100 transition-colors disabled:opacity-50"
            >
              {createPromotionMutation.isPending ? "Création..." : "Enregistrer"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
