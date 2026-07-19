export interface MessageDto {
  idMessage: number;
  contenu: string;
  dateEnvoi: string;
  idExpediteur: number;
  nomExpediteur: string;
  estMonMessage: boolean;
  est_lu: boolean;
}

export interface CreateMessageRequest {
  idConversation: number;
  contenu: string;
}
