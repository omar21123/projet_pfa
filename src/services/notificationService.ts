// src/services/notificationService.ts

/**
 * 💡 MOCK TEMPORAIRE - Évite l'erreur de compilation sur "envoyerNotification"
 */
export const envoyerNotification = async (titre: string, contenu: string, destinataireId?: string | number) => {
  console.log(`[Notification Mock] Envoi simulé : "${titre}" -> destinataire: ${destinataireId ?? "tous"}`);
  return undefined;
};

/**
 * 💡 MOCK TEMPORAIRE - Évite l'erreur CORS sur "/negotiate"
 */
export const buildNotificationConnection = () => {
  return {
    on: (eventName: string, callback: (...args: any[]) => void) => {
      console.log(`[SignalR Mock] Écoute de l'événement : ${eventName}`);
    },
    start: async () => {
      console.log("[SignalR Mock] Connexion temps réel démarrée virtuellement.");
      return undefined;
    },
    stop: async () => {
      console.log("[SignalR Mock] Connexion temps réel arrêtée virtuellement.");
      return undefined;
    },
  };
};

/**
 * 💡 MOCK TEMPORAIRE - Évite l'erreur 404 sur "/notifications"
 */
export const getNotifications = async () => {
  return [];
};

/**
 * 💡 MOCK TEMPORAIRE - Évite l'erreur 404 sur "/count-non-lues"
 */
export const getCountNonLues = async () => {
  return 0;
};

export const marquerLue = async (id: string | number) => {
  console.log(`[Notification Mock] Notification ${id} marquée comme lue.`);
  return undefined;
};

export const marquerToutesLues = async () => {
  console.log("[Notification Mock] Toutes les notifications ont été marquées comme lues.");
  return undefined;
};

// Export global
const notificationService = {
  envoyerNotification,
  buildNotificationConnection,
  getNotifications,
  getCountNonLues,
  marquerLue,
  marquerToutesLues,
};

export default notificationService;