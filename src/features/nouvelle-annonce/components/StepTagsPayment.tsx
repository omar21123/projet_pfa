import { useState } from "react";
import { X } from "lucide-react";
import type { FormState } from "@/features/nouvelle-annonce/types";
import { MOCK_PAYMENTS } from "@/features/nouvelle-annonce/types";
import { SectionTitle, inputCls } from "./shared";

interface StepTagsPaymentProps {
  form: FormState;
  setField: <K extends keyof FormState>(field: K, value: FormState[K]) => void;
}

export function StepTagsPayment({ form, setField }: StepTagsPaymentProps) {
  const [newTag, setNewTag] = useState("");

  const commitTags = (raw: string) => {
    const parts = raw
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);

    if (parts.length === 0) return;
    const merged = Array.from(new Set([...form.tags, ...parts]));
    setField("tags", merged);
    setNewTag("");
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && newTag.trim()) {
      e.preventDefault();
      commitTags(newTag);
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setField("tags", form.tags.filter((t) => t !== tagToRemove));
  };

  const handleTogglePayment = (id: number) => {
    const active = form.allowedPayment.includes(id);
    setField("allowedPayment", active ? form.allowedPayment.filter((x) => x !== id) : [...form.allowedPayment, id]);
  };

  return (
    <div className="space-y-6">
      <div>
        <SectionTitle
          title="Mots-clés (Tags)"
          subtitle="Ajoutez autant de tags que souhaité (séparez par une virgule ou appuyez sur Entrée)."
        />
        <div className="mt-3 flex gap-2">
          <input
            type="text"
            value={newTag}
            onChange={(e) => setNewTag(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ex: Casque, Solde, Premium... (Entrée ou virgule)"
            className={inputCls}
          />
          <button
            type="button"
            onClick={() => commitTags(newTag)}
            disabled={!newTag.trim()}
            className="h-11 px-4 rounded-lg bg-[#375260] text-white text-sm font-semibold disabled:opacity-40 shrink-0"
          >
            Ajouter
          </button>
        </div>

        <div className="flex flex-wrap gap-2 mt-3">
          {form.tags.map((t) => (
            <span
              key={`tag-chip-${t}`}
              className="inline-flex items-center gap-1 px-3 py-1 bg-slate-100 ring-1 ring-black/5 rounded-full text-xs font-semibold text-gray-700"
            >
              {t}
              <button type="button" onClick={() => handleRemoveTag(t)} className="hover:text-red-600">
                <X className="size-3" />
              </button>
            </span>
          ))}
        </div>
      </div>

      <div className="pt-6 border-t">
        <SectionTitle title="Modes de règlement" subtitle="Cochez les moyens autorisés." />
        <div className="grid gap-3 sm:grid-cols-3 mt-4">
          {MOCK_PAYMENTS.map((p) => {
            const active = form.allowedPayment.includes(p.id);
            return (
              <button
                key={`pay-method-${p.id}`}
                type="button"
                onClick={() => handleTogglePayment(p.id)}
                className={`p-4 rounded-xl border text-center font-medium text-sm transition-all ${
                  active
                    ? "bg-[#375260] text-white border-transparent"
                    : "bg-white border-gray-200 text-gray-700 hover:bg-slate-50"
                }`}
              >
                {p.nom}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}