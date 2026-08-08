import { apiClient } from "@/api/client";
import type { ConversationDto } from "@/types/conversation.types";

const unwrapConversation = (
  payload: ConversationDto | { data?: ConversationDto },
): ConversationDto => {
  if (payload && typeof payload === "object" && "data" in payload && payload.data) {
    return payload.data;
  }

  return payload as ConversationDto;
};

const unwrapConversations = (
  payload: ConversationDto[] | { data?: ConversationDto[] },
): ConversationDto[] => {
  if (Array.isArray(payload)) {
    return payload;
  }

  return payload.data ?? [];
};

export const conversationApi = {
  getMyConversations: async (): Promise<ConversationDto[]> => {
    const response = await apiClient.get<ConversationDto[] | { data?: ConversationDto[] }>(
      "/api/Conversation/mes-conversations",
    );

    return unwrapConversations(response.data);
  },

  createConversation: async (userId2: number): Promise<ConversationDto> => {
    const response = await apiClient.post<ConversationDto | { data?: ConversationDto }>(
      `/api/Conversation/creer/${userId2}`,
    );

    return unwrapConversation(response.data);
  },
};
