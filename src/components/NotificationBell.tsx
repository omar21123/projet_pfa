import { Bell } from "lucide-react";
import { useState } from "react";
import { useNotificationContext } from "@/contexts/NotificationContext";
import { NotificationDropdown } from "@/features/notifications/components/NotificationDropdown";

export function NotificationBell() {
  const { unreadCount } = useNotificationContext();
  const [open, setOpen] = useState(false);

  return (
    <div style={{ position: "relative" }}>
      <button
        onClick={() => setOpen((o) => !o)}
        style={{ position: "relative", background: "none", border: "none", cursor: "pointer" }}
      >
        <Bell size={22} />
        {unreadCount > 0 && (
          <span
            style={{
              position: "absolute",
              top: -4,
              right: -4,
              background: "#E24B4A",
              color: "#fff",
              fontSize: 10,
              fontWeight: 600,
              borderRadius: "99px",
              padding: "1px 5px",
              minWidth: 16,
              textAlign: "center",
            }}
          >
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </button>
      {open && <NotificationDropdown onClose={() => setOpen(false)} />}
    </div>
  );
}
