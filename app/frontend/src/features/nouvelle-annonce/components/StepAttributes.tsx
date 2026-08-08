import { useState } from "react";
import { Check, Layers, Plus, Trash2 } from "lucide-react";
import type { FormState, ProductAttributeGroup } from "@/features/nouvelle-annonce/types";
import { usePublicAttributes } from "@/hooks/useConfigAttributes";
import { usePublicOptions } from "@/hooks/useConfigAttributeOptions";
import { SectionTitle, inputCls } from "./shared";

interface StepAttributesProps {
  form: FormState;
  setField: <K extends keyof FormState>(field: K, value: FormState[K]) => void;
}

export function StepAttributes({ form, setField }: StepAttributesProps) {
  const { data: attributesResponse, isLoading } = usePublicAttributes({});
  const availableAttributes = attributesResponse?.data ?? [];
  const [customAttr, setCustomAttr] = useState("");

  const handleToggleAttribute = (attr: any) => {
    const attrName = attr.Name || attr.name || "";
    const attrId = attr.id || attr.ID || attr.AttributeID;

    const exists = form.attributes.some((g) => g.configName === attrName);

    if (exists) {
      const updated = form.attributes.filter((g) => g.configName !== attrName);
      setField("attributes", updated);
    } else {
      const newGroup: ProductAttributeGroup & { attributeId?: number } = {
        id: String(attrId),
        attributeId: Number(attrId),
        configName: attrName,
        options: [],
      };
      setField("attributes", [...form.attributes, newGroup]);
    }
  };

  const handleToggleOption = (attrName: string, optionName: string) => {
    const updatedGroups = form.attributes.map((group) => {
      if (group.configName !== attrName) return group;

      const optionExists = group.options.some((o) => o.name === optionName);
      const updatedOptions = optionExists
        ? group.options.filter((o) => o.name !== optionName)
        : [...group.options, { id: crypto.randomUUID(), name: optionName, isDefault: false }];

      return { ...group, options: updatedOptions };
    });

    setField("attributes", updatedGroups);
  };

  const handleAddCustomAttribute = () => {
    const name = customAttr.trim();
    if (!name) return;
    if (form.attributes.some((g) => g.configName.toLowerCase() === name.toLowerCase())) return;

    const newGroup: ProductAttributeGroup = {
      id: crypto.randomUUID(),
      configName: name,
      options: [],
    };
    setField("attributes", [...form.attributes, newGroup]);
    setCustomAttr("");
  };

  const handleAddCustomOption = (attrName: string, optionName: string) => {
    if (!optionName.trim()) return;
    handleToggleOption(attrName, optionName.trim());
  };

  if (isLoading) {
    return <div className="p-8 text-center text-slate-500 text-sm">Chargement des attributs...</div>;
  }

  return (
    <div className="space-y-6">
      <SectionTitle
        title="1. Choisissez les attributs du produit"
        subtitle="Cochez les attributs applicables, ou ajoutez un attribut personnalisé."
      />

      {/* Ajout d'un attribut personnalisé */}
      <div className="flex items-center gap-2">
        <input
          type="text"
          value={customAttr}
          onChange={(e) => setCustomAttr(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleAddCustomAttribute()}
          placeholder="Nom du nouvel attribut..."
          className={`${inputCls} flex-1`}
        />
        <button
          type="button"
          onClick={handleAddCustomAttribute}
          disabled={!customAttr.trim()}
          className="h-10 px-4 rounded-lg bg-[#375260] text-white text-sm font-semibold hover:bg-[#2c424e] disabled:opacity-40 flex items-center gap-1.5 shrink-0"
        >
          <Plus className="size-4" /> Ajouter
        </button>
      </div>

      {/* Liste des attributs disponibles */}
      <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-3">
        {availableAttributes.map((attr: any, index: number) => {
          const attrName = attr.Name || attr.name || "";
          const attrId = attr.id || attr.ID || attr.AttributeID || index;
          const isSelected = form.attributes.some((g) => g.configName === attrName);

          return (
            <button
              key={`attr-btn-${attrId}-${index}`}
              type="button"
              onClick={() => handleToggleAttribute(attr)}
              className={`flex items-center justify-between p-4 rounded-xl border transition-all text-left ${
                isSelected
                  ? "border-[#375260] bg-[#375260]/5 font-semibold text-[#375260]"
                  : "border-slate-200 bg-white text-slate-700 hover:border-slate-300"
              }`}
            >
              <div className="flex items-center gap-2.5">
                <Layers className="size-4" />
                <span className="text-sm">{attrName}</span>
              </div>
              <div
                className={`size-5 rounded flex items-center justify-center border ${
                  isSelected ? "bg-[#375260] border-[#375260] text-white" : "border-slate-300 bg-white"
                }`}
              >
                {isSelected && <Check className="size-3.5" />}
              </div>
            </button>
          );
        })}
      </div>

      {/* Options pour chaque attribut sélectionné */}
      {form.attributes.length > 0 && (
        <div className="space-y-6 pt-6 border-t border-slate-200">
          <SectionTitle
            title="2. Sélectionnez les options pour chaque attribut"
            subtitle="Cochez les options disponibles ou ajoutez une option personnalisée."
          />

          {form.attributes.map((group: any, groupIndex: number) => {
            const attrObj = availableAttributes.find(
              (a: any) => (a.Name || a.name) === group.configName
            );
            const rawId = group.attributeId ?? (attrObj as any)?.ID ?? attrObj?.id ?? group.id;

            return (
              <AttributeOptionsCard
                key={`group-card-${group.configName}-${groupIndex}`}
                group={group}
                attributeId={Number(rawId)}
                onToggleOption={(optName) => handleToggleOption(group.configName, optName)}
                onAddCustomOption={(optName) => handleAddCustomOption(group.configName, optName)}
                onRemove={() => handleToggleAttribute({ Name: group.configName })}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}

function AttributeOptionsCard({
  group,
  attributeId,
  onToggleOption,
  onAddCustomOption,
  onRemove,
}: {
  group: ProductAttributeGroup;
  attributeId?: number;
  onToggleOption: (optionName: string) => void;
  onAddCustomOption: (optionName: string) => void;
  onRemove?: () => void;
}) {
  const { data: optionsResponse, isLoading } = usePublicOptions({
    productsConfigAttributeID: attributeId,
  });
  const [customOpt, setCustomOpt] = useState("");

  const options = optionsResponse?.data ?? [];

  const handleAdd = () => {
    const name = customOpt.trim();
    if (!name) return;
    if (group.options.some((o) => o.name.toLowerCase() === name.toLowerCase())) return;

    onAddCustomOption(name);
    setCustomOpt("");
  };

  return (
    <div className="p-4 bg-slate-50 border border-slate-200 rounded-xl space-y-3">
      <div className="flex items-center justify-between border-b border-slate-200 pb-2">
        <div className="flex items-center gap-2">
          <h4 className="font-bold text-slate-800 text-sm uppercase tracking-wide">
            {group.configName}
          </h4>
          {onRemove && (
            <button
              type="button"
              onClick={onRemove}
              className="p-1 text-red-500 hover:bg-red-50 rounded transition-colors"
              title="Supprimer cet attribut"
            >
              <Trash2 className="size-3.5" />
            </button>
          )}
        </div>
        <span className="text-xs font-semibold text-[#375260]">
          {group.options.length} option(s) sélectionnée(s)
        </span>
      </div>

      {/* Ajout d'une option personnalisée */}
      <div className="flex items-center gap-2">
        <input
          type="text"
          value={customOpt}
          onChange={(e) => setCustomOpt(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleAdd()}
          placeholder="Nouvelle option..."
          className={`${inputCls} flex-1 h-9 text-sm`}
        />
        <button
          type="button"
          onClick={handleAdd}
          disabled={!customOpt.trim()}
          className="h-9 px-3 rounded-lg bg-[#375260] text-white text-xs font-semibold hover:bg-[#2c424e] disabled:opacity-40 flex items-center gap-1 shrink-0"
        >
          <Plus className="size-3.5" /> Ajouter
        </button>
      </div>

      {isLoading ? (
        <div className="text-xs text-slate-500 py-2">Chargement des options...</div>
      ) : options.length === 0 && group.options.length === 0 ? (
        <div className="text-xs text-slate-400 py-2 italic">Aucune option. Ajoutez-en une ci-dessus.</div>
      ) : (
        <div className="flex flex-wrap gap-2 pt-1">
          {/* Options existantes de l'API */}
          {options.map((opt: any, optIndex: number) => {
            const label = opt.OptionLabel || opt.name || opt.label || "";
            const optId = opt.OptionID ?? opt.id ?? opt.ID ?? `${label}-${optIndex}`;
            const isChecked = group.options.some((o) => o.name === label);

            return (
              <button
                key={`opt-btn-${optId}-${optIndex}`}
                type="button"
                onClick={() => onToggleOption(label)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all flex items-center gap-1.5 ${
                  isChecked
                    ? "bg-[#375260] text-white border-[#375260]"
                    : "bg-white text-slate-700 border-slate-200 hover:border-slate-300"
                }`}
              >
                {label}
                {isChecked && <Check className="size-3" />}
              </button>
            );
          })}

          {/* Options personnalisées ajoutées par l'utilisateur */}
          {group.options
            .filter((o) => !options.some((opt: any) => (opt.OptionLabel || opt.name || opt.label || "") === o.name))
            .map((opt) => (
              <button
                key={opt.id}
                type="button"
                onClick={() => onToggleOption(opt.name)}
                className="px-3 py-1.5 rounded-lg text-xs font-medium border transition-all flex items-center gap-1.5 bg-[#375260] text-white border-[#375260]"
              >
                {opt.name}
                <Check className="size-3" />
              </button>
            ))}
        </div>
      )}
    </div>
  );
}
