import type { UserProfile } from "@/types/user.types";

export interface AvisItem {
  id: number | string;
  id_utilisateur?: number;
  nomUtilisateur?: string;
  note: number;
  commentaire?: string;
  cmt?: string;
  dateCreation?: string;
  avatar?: string | null;
  utilisateur?: UserProfile | null;
}
