import React, { useState, useRef, useCallback } from "react";
import {
  ImagePlus,
  Trash2,
  Plus,
  Sparkles,
  Check,
  AlertCircle,
  X,
  ZoomIn,
  ZoomOut,
  Move,
  Crop,
} from "lucide-react";
import { type FormState } from "../types";
import { SectionTitle, inputCls } from "./shared";

// ============================================================================
// COMPOSANT MODAL DE RECADRAGE ET CADRAGE PHOTO (1:1)
// ============================================================================
interface ImageCropperModalProps {
  imageSrc: string;
  onSave: (croppedFile: File) => void;
  onClose: () => void;
}

function ImageCropperModal({ imageSrc, onSave, onClose }: ImageCropperModalProps) {
  const [zoom, setZoom] = useState<number>(1);
  const [position, setPosition] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragStart, setDragStart] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

  const imageRef = useRef<HTMLImageElement | null>(null);

  const handleMouseDown = (e: React.MouseEvent | React.TouchEvent) => {
    setIsDragging(true);
    const clientX = "touches" in e ? e.touches[0].clientX : e.clientX;
    const clientY = "touches" in e ? e.touches[0].clientY : e.clientY;
    setDragStart({ x: clientX - position.x, y: clientY - position.y });
  };

  const handleMouseMove = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      if (!isDragging) return;
      const clientX = "touches" in e ? e.touches[0].clientX : e.clientX;
      const clientY = "touches" in e ? e.touches[0].clientY : e.clientY;
      setPosition({
        x: clientX - dragStart.x,
        y: clientY - dragStart.y,
      });
    },
    [isDragging, dragStart]
  );

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  const handleCropAndSave = () => {
    const img = imageRef.current;
    if (!img) return;

    const canvas = document.createElement("canvas");
    const outputSize = 600;
    canvas.width = outputSize;
    canvas.height = outputSize;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    ctx.fillStyle = "#FFFFFF";
    ctx.fillRect(0, 0, outputSize, outputSize);

    const previewSize = 280;
    const scaleFactor = outputSize / previewSize;

    const imgWidth = img.naturalWidth;
    const imgHeight = img.naturalHeight;

    const baseScale = Math.min(previewSize / imgWidth, previewSize / imgHeight);
    const currentScale = baseScale * zoom;

    const drawWidth = imgWidth * currentScale * scaleFactor;
    const drawHeight = imgHeight * currentScale * scaleFactor;

    const centerX = outputSize / 2 + position.x * scaleFactor;
    const centerY = outputSize / 2 + position.y * scaleFactor;

    const drawX = centerX - drawWidth / 2;
    const drawY = centerY - drawHeight / 2;

    ctx.drawImage(img, drawX, drawY, drawWidth, drawHeight);

    canvas.toBlob((blob) => {
      if (blob) {
        const file = new File([blob], `variant-${Date.now()}.jpg`, {
          type: "image/jpeg",
        });
        onSave(file);
      }
    }, "image/jpeg", 0.92);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-5 animate-in fade-in zoom-in duration-200">
        <div className="flex items-center justify-between border-b border-slate-100 pb-3">
          <div className="flex items-center gap-2 text-slate-800 font-bold text-base">
            <Crop className="size-5 text-[#375260]" />
            Ajuster et cadrer la photo
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors"
          >
            <X className="size-5" />
          </button>
        </div>

        <div className="flex flex-col items-center justify-center space-y-2">
          <p className="text-xs text-slate-500 font-medium flex items-center gap-1">
            <Move className="size-3.5" /> Glissez pour déplacer la photo dans le cadre
          </p>

          <div
            className="relative size-[280px] bg-slate-900 rounded-2xl overflow-hidden border-2 border-[#375260] shadow-inner cursor-move select-none flex items-center justify-center"
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
            onTouchStart={handleMouseDown}
            onTouchMove={handleMouseMove}
            onTouchEnd={handleMouseUp}
          >
            <div className="absolute inset-0 pointer-events-none grid grid-cols-3 grid-rows-3 z-10 opacity-30">
              <div className="border-r border-b border-white"></div>
              <div className="border-r border-b border-white"></div>
              <div className="border-b border-white"></div>
              <div className="border-r border-b border-white"></div>
              <div className="border-r border-b border-white"></div>
              <div className="border-b border-white"></div>
              <div className="border-r border-white"></div>
              <div className="border-r border-white"></div>
              <div></div>
            </div>

            <img
              ref={imageRef}
              src={imageSrc}
              alt="Ajustement"
              draggable={false}
              className="absolute max-w-none transition-transform duration-75"
              style={{
                transform: `translate(${position.x}px, ${position.y}px) scale(${zoom})`,
                maxHeight: "100%",
                maxWidth: "100%",
                objectFit: "contain",
              }}
            />
          </div>
        </div>

        <div className="space-y-2 px-2">
          <div className="flex items-center justify-between text-xs text-slate-600 font-semibold">
            <span className="flex items-center gap-1">
              <ZoomOut className="size-3.5 text-slate-400" /> Zoom
            </span>
            <span>{Math.round(zoom * 100)}%</span>
          </div>
          <div className="flex items-center gap-3">
            <input
              type="range"
              min="1"
              max="3"
              step="0.05"
              value={zoom}
              onChange={(e) => setZoom(parseFloat(e.target.value))}
              className="w-full accent-[#375260] cursor-pointer h-2 bg-slate-200 rounded-lg"
            />
            <ZoomIn className="size-4 text-slate-500 shrink-0" />
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 h-10 rounded-xl text-slate-600 font-semibold text-xs hover:bg-slate-100 transition-colors"
          >
            Annuler
          </button>
          <button
            type="button"
            onClick={handleCropAndSave}
            className="inline-flex items-center gap-2 px-5 h-10 rounded-xl bg-[#375260] text-white text-xs font-semibold hover:bg-[#2c424e] transition-colors shadow-md"
          >
            <Check className="size-4" /> Valider et appliquer
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// COMPOSANT PRINCIPAL STEP COMBINATIONS
// ============================================================================
interface StepCombinationsProps {
  form: FormState;
  setField: <K extends keyof FormState>(key: K, value: FormState[K]) => void;
}

export function StepCombinations({ form, setField }: StepCombinationsProps) {
  const combinations = form.combinations || [];

  const [cropperState, setCropperState] = useState<{
    index: number;
    imageSrc: string;
  } | null>(null);

  const updateCombination = (index: number, field: string, value: any) => {
    const updated = [...combinations];
    updated[index] = { ...updated[index], [field]: value };
    setField("combinations", updated);
  };

  const setDefaultCombination = (index: number) => {
    const updated = combinations.map((combo, i) => ({
      ...combo,
      isDefault: i === index,
    }));
    setField("combinations", updated);
  };

  const removeCombination = (index: number) => {
    const updated = combinations.filter((_, i) => i !== index);
    setField("combinations", updated);
  };

  const handleSelectImage = (index: number, file: File) => {
    const reader = new FileReader();
    reader.onload = () => {
      if (reader.result) {
        setCropperState({
          index,
          imageSrc: reader.result as string,
        });
      }
    };
    reader.readAsDataURL(file);
  };

  const handleSaveCroppedImage = (croppedFile: File) => {
    if (cropperState !== null) {
      updateCombination(cropperState.index, "image", croppedFile);
      setCropperState(null);
    }
  };

  const generateCombinations = () => {
    if (!form.attributes || form.attributes.length === 0) return;

    const cartesian = (args: any[][]): any[][] => {
      return args.reduce<any[][]>(
        (a, b) => a.flatMap((d) => b.map((e) => [d, e].flat())),
        [[]]
      );
    };

    const attributeOptions = form.attributes.map((attr) =>
      (attr.options || []).map((opt) => ({
        configName: attr.configName,
        optionName: opt.name,
      }))
    );

    const products = cartesian(attributeOptions);

    const globalBase = form.basePrice || "0";

    const newCombinations = products.map((opts, idx) => {
      const optionsArray = Array.isArray(opts) ? opts : [opts];
      const skuSuffix = optionsArray
        .map((o) => o.optionName.toUpperCase().replace(/\s+/g, "").slice(0, 3))
        .join("-");

      return {
        id: typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : `combo-${Date.now()}-${idx}`,
        sku: form.barcode ? `${form.barcode}-${skuSuffix}` : `SKU-${idx + 1}`,
        price: globalBase,
        compareAtPrice: "",
        stock: form.stock || "0",
        isDefault: idx === 0,
        image: null,
        options: optionsArray,
      };
    });

    setField("combinations", newCombinations);
  };

  return (
    <div className="space-y-6">
      {cropperState && (
        <ImageCropperModal
          imageSrc={cropperState.imageSrc}
          onClose={() => setCropperState(null)}
          onSave={handleSaveCroppedImage}
        />
      )}

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4 border-b border-slate-100">
        <SectionTitle
          title="Variantes & Combinaisons"
          subtitle="Gérez les prix et stocks spécifiques pour chaque variante."
        />

        {form.attributes && form.attributes.length > 0 && (
          <button
            type="button"
            onClick={generateCombinations}
            className="inline-flex items-center gap-2 px-4 h-10 rounded-xl bg-[#375260]/10 text-[#375260] text-xs font-bold hover:bg-[#375260]/20 transition-colors shrink-0"
          >
            <Sparkles className="size-4" />
            Régénérer les variantes
          </button>
        )}
      </div>

      {(!form.attributes || form.attributes.length === 0) && (
        <div className="p-4 rounded-xl bg-amber-50 border border-amber-200 flex items-center gap-3 text-amber-800 text-sm">
          <AlertCircle className="size-5 shrink-0 text-amber-600" />
          <span>
            Aucun attribut n'a été défini. Revenez à l'étape <strong>Attributs</strong> pour ajouter des options (ex: Taille, Couleur).
          </span>
        </div>
      )}

      {combinations.length === 0 ? (
        <div className="text-center py-12 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200">
          <p className="text-slate-500 text-sm font-medium">
            Aucune variante configurée pour le moment.
          </p>
          <button
            type="button"
            onClick={generateCombinations}
            disabled={!form.attributes || form.attributes.length === 0}
            className="mt-3 inline-flex items-center gap-2 px-4 h-10 rounded-lg bg-[#375260] text-white text-xs font-semibold disabled:opacity-50"
          >
            <Plus className="size-4" /> Générer automatiquement
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {combinations.map((combo, idx) => {
            const imageUrl =
              combo.image instanceof File
                ? URL.createObjectURL(combo.image)
                : typeof combo.image === "string"
                ? combo.image
                : null;

            return (
              <div
                key={combo.id || idx}
                className={`p-4 md:p-5 rounded-2xl border transition-all ${
                  combo.isDefault
                    ? "border-[#375260] bg-slate-50/50 ring-1 ring-[#375260]/20"
                    : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                <div className="flex flex-col lg:flex-row lg:items-center gap-4 justify-between">
                  
                  {/* Photo 1:1 & Options */}
                  <div className="flex items-center gap-4">
                    <div className="relative size-20 rounded-xl border border-slate-200 bg-slate-100 overflow-hidden shrink-0 group flex items-center justify-center">
                      {imageUrl ? (
                        <>
                          <img
                            src={imageUrl}
                            alt={combo.sku || `Variante ${idx + 1}`}
                            className="size-full object-cover"
                          />
                          <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1 p-1">
                            <button
                              type="button"
                              onClick={() => {
                                if (combo.image instanceof File) {
                                  handleSelectImage(idx, combo.image);
                                }
                              }}
                              className="text-[10px] text-white font-semibold flex items-center gap-1 hover:underline"
                            >
                              <Crop className="size-3" /> Cadrer
                            </button>
                            <button
                              type="button"
                              onClick={() => updateCombination(idx, "image", null)}
                              className="text-[10px] text-red-300 font-semibold flex items-center gap-1 hover:underline"
                            >
                              <Trash2 className="size-3" /> Effacer
                            </button>
                          </div>
                        </>
                      ) : (
                        <label className="size-full flex flex-col items-center justify-center cursor-pointer hover:bg-slate-200/60 transition-colors">
                          <ImagePlus className="size-5 text-slate-400" />
                          <span className="text-[10px] text-slate-500 font-semibold mt-1">
                            + Photo
                          </span>
                          <input
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={(e) => {
                              const file = e.target.files?.[0];
                              if (file) handleSelectImage(idx, file);
                            }}
                          />
                        </label>
                      )}
                    </div>

                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-1.5">
                        {combo.options?.map((opt, oIdx) => (
                          <span
                            key={oIdx}
                            className="inline-flex items-center px-2.5 py-1 rounded-md bg-slate-100 text-slate-800 text-xs font-semibold"
                          >
                            <span className="text-slate-400 font-normal mr-1">
                              {opt.configName}:
                            </span>
                            {opt.optionName}
                          </span>
                        ))}
                      </div>

                      <div>
                        <button
                          type="button"
                          onClick={() => setDefaultCombination(idx)}
                          className={`inline-flex items-center gap-1.5 text-xs font-medium transition-colors ${
                            combo.isDefault
                              ? "text-[#375260] font-bold"
                              : "text-slate-500 hover:text-slate-800"
                          }`}
                        >
                          <span
                            className={`size-4 rounded-full border flex items-center justify-center ${
                              combo.isDefault
                                ? "bg-[#375260] border-[#375260] text-white"
                                : "border-slate-300"
                            }`}
                          >
                            {combo.isDefault && <Check className="size-2.5 stroke-[3]" />}
                          </span>
                          Variante par défaut
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* COLONNES SIMPLIFIÉES : SKU, Prix Vente (DH), Stock */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 lg:w-[450px] items-center">
                    <div>
                      <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                        SKU
                      </label>
                      <input
                        type="text"
                        value={combo.sku || ""}
                        onChange={(e) => updateCombination(idx, "sku", e.target.value)}
                        placeholder="SKU-123"
                        className={inputCls}
                      />
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                        Prix Vente (DH)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        value={combo.price || ""}
                        onChange={(e) => updateCombination(idx, "price", e.target.value)}
                        placeholder="0.00"
                        className={inputCls}
                      />
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1">
                        Stock
                      </label>
                      <input
                        type="number"
                        value={combo.stock || "0"}
                        onChange={(e) => updateCombination(idx, "stock", e.target.value)}
                        placeholder="0"
                        className={inputCls}
                      />
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => removeCombination(idx)}
                    className="self-end lg:self-center text-slate-400 hover:text-red-500 p-2 rounded-lg hover:bg-red-50 transition-colors"
                    title="Supprimer la variante"
                  >
                    <Trash2 className="size-5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}