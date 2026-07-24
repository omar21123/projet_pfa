export interface ConversationDto {
  idConversation: number;
  dateCreation: string;
  idAutreUtilisateur: number;
  nomAutreUtilisateur?: string | null;
  prenomAutreUtilisateur?: string | null;
}
