// src/components/admin/ui.tsx
import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

// ============================================================
// TOKENS — repris de la maquette admin existante
// ============================================================
export const BRAND = "#375260";
export const BRAND_DARK = "#293F49";
export const BRAND_LIGHT = "#4A6B7A";

export const ADMIN_GLOBAL_STYLE = `
  .lift { transition: transform 0.15s ease, box-shadow 0.15s ease, filter 0.15s ease; }
  .lift:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(55,82,96,0.16); filter: brightness(1.03); }
  .lift:active { transform: translateY(0px) scale(0.98); box-shadow: 0 2px 6px rgba(55,82,96,0.14); filter: brightness(0.97); }
`;

export function Avatar({ name, size = 34 }: { name: string; size?: number }) {
  const initials = name
    .split(" ")
    .filter(Boolean)
    .map((p) => p[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: "#E7ECEE",
        color: BRAND,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontWeight: 600,
        fontSize: size * 0.36,
        flexShrink: 0,
      }}
    >
      {initials || "?"}
    </div>
  );
}

export type BadgeTone = "active" | "pending" | "off" | "danger" | "info";

const BADGE_TONES: Record<BadgeTone, { bg: string; fg: string }> = {
  active: { bg: "#E7F5EC", fg: "#1E8E5A" },
  pending: { bg: "#FCF3DA", fg: "#8A6608" },
  off: { bg: "#EEF1F4", fg: "#5B6B79" },
  danger: { bg: "#FBE7E2", fg: "#B23A21" },
  info: { bg: "#EDE6FB", fg: "#6C4AB6" },
};

export function Badge({ tone = "off", children }: { tone?: BadgeTone; children: ReactNode }) {
  const t = BADGE_TONES[tone];
  return (
    <span
      style={{
        background: t.bg,
        color: t.fg,
        fontSize: 11.5,
        fontWeight: 600,
        padding: "3px 9px",
        borderRadius: 999,
        whiteSpace: "nowrap",
      }}
    >
      {children}
    </span>
  );
}

export type IconBtnTone = "approved" | "rejected" | "banned";

const ICONBTN_TONES: Record<IconBtnTone, { fg: string; bg: string }> = {
  approved: { fg: "#1E8E5A", bg: "#E7F5EC" },
  rejected: { fg: "#B23A21", bg: "#FBE7E2" },
  banned: { fg: "#fff", bg: "#16202B" },
};

export function IconBtn({
  icon: Icon,
  onClick,
  title,
  tone,
  disabled,
}: {
  icon: LucideIcon;
  onClick?: () => void;
  title: string;
  tone?: IconBtnTone;
  disabled?: boolean;
}) {
  const t = tone ? ICONBTN_TONES[tone] : null;
  return (
    <button
      type="button"
      className="lift"
      onClick={onClick}
      title={title}
      disabled={disabled}
      style={{
        width: 32,
        height: 32,
        borderRadius: 8,
        border: t ? "none" : "1px solid #DCE1E7",
        background: t ? t.bg : "#fff",
        color: t ? t.fg : "#5B6B79",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        opacity: disabled ? 0.45 : 1,
        cursor: disabled ? "not-allowed" : "pointer",
      }}
    >
      <Icon size={14} strokeWidth={2} />
    </button>
  );
}

export function StatCard({
  icon: Icon,
  label,
  value,
  color,
}: {
  icon: LucideIcon;
  label: string;
  value: string | number;
  color: string;
}) {
  return (
    <div
      className="lift"
      style={{
        background: "#fff",
        borderRadius: 12,
        border: "1px solid #E4E8ED",
        padding: "16px 18px",
        display: "flex",
        alignItems: "center",
        gap: 14,
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: 10,
          border: "1px solid #E4E8ED",
          background: "#fff",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          flexShrink: 0,
        }}
      >
        <Icon size={19} color={color} strokeWidth={1.7} />
      </div>
      <div>
        <div style={{ fontSize: 12.5, color: "#5B6B79", marginBottom: 3 }}>{label}</div>
        <div style={{ fontFamily: "Space Grotesk, sans-serif", fontSize: 21, fontWeight: 600 }}>
          {value}
        </div>
      </div>
    </div>
  );
}

export function Toast({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <div
      style={{
        position: "fixed",
        bottom: 24,
        left: "50%",
        transform: "translateX(-50%)",
        background: "#16202B",
        color: "#fff",
        padding: "12px 20px",
        borderRadius: 10,
        fontSize: 13.5,
        zIndex: 100,
      }}
    >
      {message}
    </div>
  );
}

export function ModalShell({
  onClose,
  children,
  width = 420,
}: {
  onClose: () => void;
  children: ReactNode;
  width?: number;
}) {
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(41,63,73,0.4)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 60,
      }}
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ width, background: "#fff", borderRadius: 14, padding: 24 }}
      >
        {children}
      </div>
    </div>
  );
}

export function ModalActions({
  onCancel,
  onConfirm,
  confirmLabel,
  confirmColor = BRAND,
  disabled,
}: {
  onCancel: () => void;
  onConfirm: () => void;
  confirmLabel: string;
  confirmColor?: string;
  disabled?: boolean;
}) {
  return (
    <div style={{ display: "flex", gap: 10 }}>
      <button
        type="button"
        className="lift"
        onClick={onCancel}
        style={{
          flex: 1,
          padding: "10px 0",
          borderRadius: 8,
          border: "1px solid #DCE1E7",
          background: "#fff",
          color: "#5B6B79",
          fontWeight: 500,
          fontSize: 13.5,
        }}
      >
        Annuler
      </button>
      <button
        type="button"
        className="lift"
        disabled={disabled}
        onClick={onConfirm}
        style={{
          flex: 1,
          padding: "10px 0",
          borderRadius: 8,
          border: "none",
          background: disabled ? "#B7C4BC" : confirmColor,
          color: "#fff",
          fontWeight: 600,
          fontSize: 13.5,
        }}
      >
        {confirmLabel}
      </button>
    </div>
  );
}
