import { apiClient } from "@/api/client";
import type { CreateMessageRequest, MessageDto } from "@/types/message.types";

const unwrapMessages = (payload: MessageDto[] | { data?: MessageDto[] }): MessageDto[] => {
  if (Array.isArray(payload)) {
    return payload;
  }

  return payload.data ?? [];
};

export const messageApi = {
  getConversationMessages: async (conversationId: number): Promise<MessageDto[]> => {
    const response = await apiClient.get<MessageDto[] | { data?: MessageDto[] }>(
      `/api/Message/Messages/${conversationId}`,
    );

    return unwrapMessages(response.data);
  },

  sendMessage: async (payload: CreateMessageRequest): Promise<void> => {
    await apiClient.post("/api/Message", payload);
  },

  markAsRead: async (messageId: number): Promise<void> => {
    await apiClient.patch(`/api/Message/mark-as-read/${messageId}`);
  },
};
