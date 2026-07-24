import { useState, useRef, useEffect } from "react";
import { Plus, Sparkles, X, Loader2 } from "lucide-react";
import type { ChosenAttribute, FormState } from "@/types/types";
import type { ProductsConfigAttribute } from "@/types/config_attribute";
import type { ConfigAttributeOption } from "@/types/config_attribute_option";

import { usePublicAttributes } from "@/hooks/useConfigAttributes";
import { usePublicOptions, useCreateOption } from "@/hooks/useConfigAttributeOptions";
import { SectionTitle, inputCls } from "./shared";

interface StepAttributesProps {
  form: FormState;
  setField: (field: keyof FormState, value: any) => void;
}

export function StepAttributes({ form, setField }: StepAttributesProps) {
  // Saisies utilisateur
  const [typedAttr, setTypedAttr] = useState("");
  const [typedValue, setTypedValue] = useState("");

  // Attribut sélectionné depuis la BDD (ex: "ss")
  const [selectedAttribute, setSelectedAttribute] = useState<ProductsConfigAttribute | null>(null);

  // Visibilité des menus déroulants
  const [showAttrDropdown, setShowAttrDropdown] = useState(false);
  const [showValueDropdown, setShowValueDropdown] = useState(false);

  const attrRef = useRef<HTMLDivElement>(null);
  const valRef = useRef<HTMLDivElement>(null);

  // 1. Recherche d'attributs (GET /api/products-config-attributes)
  const { data: publicAttrsResponse, isLoading: loadingAttrs } = usePublicAttributes({
    name: typedAttr,
  });
  const matchedAttributes = publicAttrsResponse?.data ?? [];

  // 2. Recherche d'options légères (GET /api/config-attribute-options?productsConfigAttributeID=...&name=...)
  const { data: optionsResponse, isLoading: loadingOptions } = usePublicOptions({
    productsConfigAttributeID: selectedAttribute?.id,
    name: typedValue,
  });
  const matchedOptions = optionsResponse?.data ?? [];

  // 3. Mutation de création d'option (POST /api/config-attribute-options/create)
  const createOptionMutation = useCreateOption();

  // Fermeture des menus au clic extérieur
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (attrRef.current && !attrRef.current.contains(e.target as Node)) {
        setShowAttrDropdown(false);
      }
      if (valRef.current && !valRef.current.contains(e.target as Node)) {
        setShowValueDropdown(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Sélection d'un attribut suggéré
  const handleSelectAttribute = (attr: ProductsConfigAttribute) => {
    setSelectedAttribute(attr);
    setTypedAttr(attr.Name);
    setShowAttrDropdown(false);
    setTypedValue("");
  };

  // Sélection d'une option existante
  const handleSelectOption = (opt: ConfigAttributeOption) => {
    setTypedValue(opt.OptionLabel);
    setShowValueDropdown(false);
  };

  // Enregistrer l'option directement en BDD si elle n'existe pas encore
  const handleCreateOptionInDb = async () => {
    if (!selectedAttribute || !typedValue.trim()) return;

    try {
      const response = await createOptionMutation.mutateAsync({
        ProductsConfigAttributeID: selectedAttribute.id,
        OptionLabel: typedValue.trim(),
        OptionValue: typedValue.trim().toLowerCase().replace(/\s+/g, "_"),
        IsDefaultForAttribute: false,
      });

      if (response?.data) {
        setTypedValue(response.data.OptionLabel);
      }
      setShowValueDropdown(false);
    } catch (error: any) {
      alert(error?.response?.data?.message || "Erreur lors de la création de l'option.");
    }
  };

  // Ajout de la paire (Attribut / Option) au tableau local du formulaire
  const handleAdd = () => {
    if (!typedAttr.trim() || !typedValue.trim()) return;

    if (form.attributes.some((a) => a.configName.toLowerCase() === typedAttr.trim().toLowerCase())) {
      alert("Cet attribut a déjà été ajouté à la liste.");
      return;
    }

    const newAttr: ChosenAttribute = {
      id: crypto.randomUUID(),
      configName: typedAttr.trim(),
      optionName: typedValue.trim(),
    };

    setField("attributes", [...form.attributes, newAttr]);

    // Réinitialisation
    setTypedAttr("");
    setTypedValue("");
    setSelectedAttribute(null);
  };

  // Vérifier si l'option existe déjà exactement dans les résultats retournés par la BDD
  const isExactOptionInDb = matchedOptions.some(
    (opt) => opt.OptionLabel.toLowerCase() === typedValue.trim().toLowerCase()
  );

  return (
    <div className="space-y-6">
      <SectionTitle
        title="Spécifications & Attributs"
        subtitle="Sélectionnez un attribut et ses options enregistrées, ou créez-en de nouvelles."
      />

      <div className="grid gap-4 md:grid-cols-3 items-end p-4 bg-slate-50 rounded-xl border border-dashed border-slate-200">
        
        {/* 1. CARACTÉRISTIQUE */}
        <div className="relative" ref={attrRef}>
          <label className="block text-xs font-semibold uppercase text-slate-600 mb-1">
            Caractéristique
          </label>
          <div className="relative">
            <input
              type="text"
              value={typedAttr}
              onChange={(e) => {
                setTypedAttr(e.target.value);
                setSelectedAttribute(null);
                setShowAttrDropdown(true);
              }}
              onFocus={() => setShowAttrDropdown(true)}
              placeholder="Ex: Couleur, Taille..."
              className={inputCls}
            />
            {typedAttr && (
              <button
                type="button"
                onClick={() => {
                  setTypedAttr("");
                  setSelectedAttribute(null);
                }}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X className="size-4" />
              </button>
            )}
          </div>

          {/* Suggéstions Attributs */}
          {showAttrDropdown && typedAttr.trim().length > 0 && (
            <div className="absolute z-20 left-0 right-0 mt-1 bg-white border border-slate-200 rounded-lg shadow-lg max-h-60 overflow-auto">
              {loadingAttrs ? (
                <div className="p-3 text-xs text-slate-500 flex items-center gap-2">
                  <Loader2 className="size-3 animate-spin" /> Recherche...
                </div>
              ) : (
                <>
                  {matchedAttributes.map((attr) => (
                    <button
                      key={attr.id}
                      type="button"
                      onClick={() => handleSelectAttribute(attr)}
                      className="w-full text-left px-4 py-2.5 text-sm hover:bg-slate-50 flex items-center justify-between border-b border-slate-50"
                    >
                      <span className="font-medium text-slate-800">{attr.Name}</span>
                      <span className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-medium">
                        BDD
                      </span>
                    </button>
                  ))}

                  <button
                    type="button"
                    onClick={() => setShowAttrDropdown(false)}
                    className="w-full text-left px-4 py-2.5 text-sm hover:bg-blue-50 text-blue-700 font-medium flex items-center gap-2"
                  >
                    <Sparkles className="size-4 text-blue-600" />
                    Utiliser l'attribut "{typedAttr}"
                  </button>
                </>
              )}
            </div>
          )}
        </div>

        {/* 2. VALEUR / OPTION */}
        <div className="relative" ref={valRef}>
          <label className="block text-xs font-semibold uppercase text-slate-600 mb-1">
            Valeur / Option
          </label>
          <div className="relative">
            <input
              type="text"
              value={typedValue}
              onChange={(e) => {
                setTypedValue(e.target.value);
                setShowValueDropdown(true);
              }}
              onFocus={() => setShowValueDropdown(true)}
              placeholder="Ex: Rouge, XL..."
              className={inputCls}
            />
            {typedValue && (
              <button
                type="button"
                onClick={() => setTypedValue("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X className="size-4" />
              </button>
            )}
          </div>

          {/* Suggéstions Options & Bouton de création BDD */}
          {showValueDropdown && typedValue.trim().length > 0 && (
            <div className="absolute z-20 left-0 right-0 mt-1 bg-white border border-slate-200 rounded-lg shadow-lg max-h-60 overflow-auto">
              {loadingOptions ? (
                <div className="p-3 text-xs text-slate-500 flex items-center gap-2">
                  <Loader2 className="size-3 animate-spin" /> Recherche...
                </div>
              ) : (
                <>
                  {/* Options existantes retournées par l'API */}
                  {matchedOptions.map((opt) => (
                    <button
                      key={opt.OptionID ?? opt.id}
                      type="button"
                      onClick={() => handleSelectOption(opt)}
                      className="w-full text-left px-4 py-2.5 text-sm hover:bg-slate-50 flex items-center justify-between border-b border-slate-50"
                    >
                      <span className="font-medium text-slate-800">{opt.OptionLabel}</span>
                    </button>
                  ))}

                  {/* Bouton style identique aux captures d'écran */}
                  {selectedAttribute && !isExactOptionInDb && (
                    <button
                      type="button"
                      onClick={handleCreateOptionInDb}
                      disabled={createOptionMutation.isPending}
                      className="w-full text-left px-4 py-3 text-sm hover:bg-emerald-50 text-emerald-800 font-medium flex items-center gap-2 transition-colors"
                    >
                      {createOptionMutation.isPending ? (
                        <Loader2 className="size-4 animate-spin text-emerald-600" />
                      ) : (
                        <Sparkles className="size-4 text-emerald-600 shrink-0" />
                      )}
                      <span>
                        Ajouter "<strong>{typedValue}</strong>" dans la BDD pour <strong>{selectedAttribute.Name}</strong>
                      </span>
                    </button>
                  )}
                </>
              )}
            </div>
          )}
        </div>

        {/* Bouton Ajouter l'option */}
        <button
          type="button"
          onClick={handleAdd}
          disabled={!typedAttr.trim() || !typedValue.trim()}
          className="h-11 bg-[#375260] text-white rounded-lg px-4 text-sm font-semibold flex items-center justify-center gap-1.5 hover:bg-[#2c424e] disabled:opacity-40 transition-all"
        >
          <Plus className="size-4" /> Ajouter l'option
        </button>
      </div>

      {/* Tableau récapitulatif */}
      {form.attributes.length > 0 && (
        <div className="border border-slate-200 rounded-xl overflow-hidden bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-medium">
                <th className="p-3 pl-4">Nom de la caractéristique</th>
                <th className="p-3">Valeur / Option</th>
                <th className="p-3 text-right pr-4">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {form.attributes.map((attr) => (
                <tr key={attr.id} className="hover:bg-slate-50/50 transition-colors">
                  <td className="p-3 pl-4 font-semibold text-slate-800">{attr.configName}</td>
                  <td className="p-3 text-slate-600">{attr.optionName}</td>
                  <td className="p-3 text-right pr-4">
                    <button
                      type="button"
                      onClick={() =>
                        setField(
                          "attributes",
                          form.attributes.filter((a) => a.id !== attr.id)
                        )
                      }
                      className="text-red-600 hover:text-red-700 hover:underline text-xs font-medium"
                    >
                      Supprimer
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}