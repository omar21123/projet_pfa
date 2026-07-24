// src/features/nouvelle-annonce/components/shared.tsx
import { Check } from "lucide-react";

export const inputCls =
  "w-full h-11 px-3.5 rounded-lg bg-white ring-1 ring-black/10 text-sm focus:outline-none focus:ring-2 focus:ring-[#375260]/40 transition";

export function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block space-y-1.5">
      <span className="text-xs font-semibold uppercase tracking-wide text-ink/60">{label}</span>
      {children}
    </label>
  );
}

export function SectionTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div>
      <h2 className="text-lg font-extrabold text-ink">{title}</h2>
      {subtitle && <p className="text-sm text-ink/60 mt-0.5">{subtitle}</p>}
    </div>
  );
}

export function CategoryChip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex items-center gap-1 h-7 px-2.5 rounded-full text-xs font-medium transition-all ${
        active ? "bg-[#375260] text-cream" : "bg-white text-ink/70 ring-1 ring-black/5"
      }`}
    >
      {active && <Check className="size-3" />}
      {label}
    </button>
  );
}
