import { Bell, MessageCircle, Heart, Megaphone } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useNotificationContext } from "@/contexts/NotificationContext";

const formatTimeAgo = (dateString: string) => {
  const date = new Date(dateString);
  const seconds = Math.floor((new Date().getTime() - date.getTime()) / 1000);

  if (seconds < 60) return "À l'instant";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `Il y a ${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `Il y a ${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `Il y a ${days}j`;
  return date.toLocaleDateString("fr-FR");
};

const getIcon = (type: string) => {
  switch (type) {
    case "MESSAGE":
      return <MessageCircle className="h-5 w-5 text-blue-500" />;
    case "FAVORI":
      return <Heart className="h-5 w-5 text-amber-500" />;
    case "ANNONCE":
      return <Megaphone className="h-5 w-5 text-emerald-500" />;
    default:
      return <Bell className="h-5 w-5 text-slate-500" />;
  }
};

interface NotificationDropdownProps {
  onClose?: () => void;
}

export function NotificationDropdown({ onClose }: NotificationDropdownProps) {
  const { notifs, unreadCount, markAsRead, markAllAsRead } = useNotificationContext();
  const navigate = useNavigate();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="relative text-muted-foreground hover:text-primary hover:bg-secondary/10"
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white transform translate-x-1/2 -translate-y-1/2 bg-red-600 rounded-full animate-pulse">
              {unreadCount > 9 ? "9+" : unreadCount}
            </span>
          )}
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent align="end" className="w-80">
        <div className="border-b border-border px-4 py-3 flex items-center justify-between">
          <h3 className="font-semibold text-sm">Notifications</h3>
          {unreadCount > 0 && (
            <button onClick={markAllAsRead} className="text-xs text-primary hover:underline">
              Tout marquer comme lu
            </button>
          )}
        </div>

        <div className="max-h-96 overflow-y-auto">
          {notifs.length === 0 ? (
            <div className="px-4 py-8 text-center text-muted-foreground">
              <Bell className="h-8 w-8 mx-auto mb-2 opacity-50" />
              <p className="text-sm">Aucune notification</p>
            </div>
          ) : (
            notifs.map((notif) => (
              <DropdownMenuItem
                key={notif.id}
                className={`flex flex-col gap-2 px-4 py-3 cursor-pointer ${!notif.estLue ? "bg-primary/5" : ""}`}
                onClick={() => {
                  if (notif.id !== undefined) {
                    markAsRead(notif.id);
                  }
                  if (notif.lienAction) {
                    navigate(notif.lienAction);
                  }
                  onClose?.();
                }}
              >
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <div className="flex-shrink-0 pt-1">{getIcon(notif.type)}</div>
                    <div className="min-w-0">
                      <p className="font-medium text-sm truncate">{notif.titre}</p>
                      <p className="text-xs text-muted-foreground">
                        {formatTimeAgo(notif.dateCreation)}
                      </p>
                    </div>
                  </div>
                  {!notif.estLue && <span className="text-xs text-primary">Nouveau</span>}
                </div>
                {notif.contenu && (
                  <p className="text-sm text-muted-foreground line-clamp-2">{notif.contenu}</p>
                )}
              </DropdownMenuItem>
            ))
          )}
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export default NotificationDropdown;
