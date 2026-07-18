// src/contexts/NotificationContext.tsx
import React, { createContext, useContext, useState } from "react";

// Structure d'une notification
interface Notification {
  id: string | number;
  title: string;
  message: string;
  isRead: boolean;
  createdAt?: string;
}

// Structure du Context acceptant toutes les variantes de ton projet
interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number; // Utilisé par certains composants
  nonLues: number;     // Utilisé par tes tests et d'autres composants
  markAsRead: (id: string | number) => Promise<void>;
  markAllAsRead: () => Promise<void>;
  addNotification: (title: string, message: string, type?: string) => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const NotificationProvider = ({ children }: { children: React.ReactNode }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [nonLues, setNonLues] = useState(0);

  // Permet d'ajouter une notification localement (utile pour les tests ou les simulations)
  const addNotification = (title: string, message: string) => {
    const newNotif: Notification = {
      id: Date.now().toString(),
      title,
      message,
      isRead: false,
    };
    setNotifications((prev) => [newNotif, ...prev]);
    setNonLues((prev) => prev + 1);
  };

  const markAsRead = async (id: string | number) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
    );
    setNonLues((prev) => Math.max(0, prev - 1));
  };

  const markAllAsRead = async () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
    setNonLues(0);
  };

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        unreadCount: nonLues,
        nonLues,
        markAsRead,
        markAllAsRead,
        addNotification,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

/* -------------------------------------------------------------------------- */
/*             🛡️ ALIAS DE SECURITE POUR EVITER LES ERREURS D'IMPORT           */
/* -------------------------------------------------------------------------- */

// 1. Le Hook principal
export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error("useNotifications must be used within a NotificationProvider");
  }
  return context;
};

// 2. L'alias demandé par NotificationDropdown.tsx (résout l'erreur de ta console !)
export const useNotificationContext = useNotifications;

// 3. L'alias demandé par tes fichiers de tests
export const useNotification = useNotifications;