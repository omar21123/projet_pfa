import React from "react";
import { LucideIcon } from "lucide-react";

// La couleur d'accentuation par défaut de ton projet (Indigo)
export const BRAND = "#4F46E5";

// ============================================================
// 1. AVATAR (Génère un rond avec les initiales si pas d'image)
// ============================================================
interface AvatarProps {
  name: string;
  size?: number;
}

export function Avatar({ name, size = 32 }: AvatarProps) {
  const initials = name
    ? name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .slice(0, 2)
        .toUpperCase()
    : "U";

  return (
    <div
      className="rounded-full flex items-center justify-center font-bold bg-slate-100 text-slate-700 border border-slate-200 shrink-0"
      style={{ width: size, height: size, fontSize: size * 0.38 }}
    >
      {initials}
    </div>
  );
}

// ============================================================
// 2. BADGE (Statuts colorés : actif, en attente, danger)
// ============================================================
interface BadgeProps {
  children: React.ReactNode;
  tone?: "active" | "pending" | "danger" | "default";
}

export function Badge({ children, tone = "default" }: BadgeProps) {
  let toneClass = "bg-slate-100 text-slate-700 border-slate-200";
  if (tone === "active") toneClass = "bg-emerald-50 text-emerald-700 border-emerald-200";
  if (tone === "pending") toneClass = "bg-amber-50 text-amber-700 border-amber-200";
  if (tone === "danger") toneClass = "bg-rose-50 text-rose-700 border-rose-200";

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${toneClass}`}>
      {children}
    </span>
  );
}

// ============================================================
// 3. ICON BUTTON (Boutons d'action rapides avec survol dynamique)
// ============================================================
interface IconBtnProps {
  icon: LucideIcon;
  onClick?: () => void;
  title?: string;
  disabled?: boolean;
  tone?: "approved" | "rejected" | "default";
}

export function IconBtn({
  icon: Icon,
  onClick,
  title,
  disabled = false,
  tone = "default",
}: IconBtnProps) {
  let toneClass = "text-slate-500 hover:bg-slate-100 hover:text-slate-800";
  if (tone === "approved") toneClass = "text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700";
  if (tone === "rejected") toneClass = "text-rose-600 hover:bg-rose-50 hover:text-rose-700";

  return (
    <button
      onClick={onClick}
      title={title}
      disabled={disabled}
      className={`p-2 rounded-lg border border-transparent transition-all duration-150 disabled:opacity-30 disabled:pointer-events-none ${toneClass}`}
    >
      <Icon className="w-4 h-4" />
    </button>
  );
}

// ============================================================
// 4. STAT CARD (Petite boîte de statistiques élégante)
// ============================================================
interface StatCardProps {
  icon: LucideIcon;
  label: string;
  value: string | number;
  color?: string;
}

export function StatCard({ icon: Icon, label, value, color }: StatCardProps) {
  return (
    <div className="bg-slate-50 p-4 rounded-xl border border-slate-150 flex items-center gap-3 w-full">
      <div 
        className="p-2 rounded-lg bg-white shadow-sm shrink-0" 
        style={{ color: color || BRAND }}
      >
        <Icon className="w-5 h-5" />
      </div>
      <div className="min-w-0">
        <div className="text-[10px] uppercase font-bold text-slate-400 tracking-wider truncate">{label}</div>
        <div className="text-base font-bold text-slate-900 leading-tight mt-0.5">{value}</div>
      </div>
    </div>
  );
}

// ============================================================
// 5. TOAST (Notification temporaire en bas d'écran)
// ============================================================
export function Toast({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <div className="fixed bottom-6 right-6 z-50 bg-slate-900 text-white px-5 py-3 rounded-lg shadow-xl text-sm font-medium animate-in slide-in-from-bottom duration-300">
      {message}
    </div>
  );
}

// ============================================================
// 6. MODAL SHELL (Conteneur de boîte de dialogue centré)
// ============================================================
interface ModalShellProps {
  children: React.ReactNode;
  onClose: () => void;
}

export function ModalShell({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div 
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4" 
      onClick={onClose}
    >
      <div
        className="w-full max-w-md bg-white rounded-xl border border-slate-200 p-6 shadow-xl animate-in fade-in zoom-in duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  );
}

// ============================================================
// 7. MODAL ACTIONS (Boutons Valider / Annuler pour les modales)
// ============================================================
interface ModalActionsProps {
  onCancel: () => void;
  onConfirm: () => void;
  confirmLabel: string;
  confirmColor?: string;
  disabled?: boolean;
}

export function ModalActions({
  onCancel,
  onConfirm,
  confirmLabel,
  confirmColor,
  disabled = false,
}: ModalActionsProps) {
  return (
    <div className="flex justify-end gap-3 mt-4">
      <button
        type="button"
        onClick={onCancel}
        className="px-4 py-2 text-sm font-medium rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors"
      >
        Annuler
      </button>
      <button
        type="button"
        onClick={onConfirm}
        disabled={disabled}
        className="px-4 py-2 text-sm font-medium rounded-lg text-white transition-colors disabled:opacity-40 disabled:pointer-events-none"
        style={{ backgroundColor: confirmColor || BRAND }}
      >
        {confirmLabel}
      </button>
    </div>
  );
}