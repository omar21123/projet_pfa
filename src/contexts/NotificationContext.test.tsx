import { useEffect } from "react";
import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, afterEach } from "vitest";
import { NotificationProvider } from "./NotificationContext";
import { useNotification } from "@/features/notifications/hooks/useNotification";

vi.mock("@/contexts/AuthContext", () => ({
  useAuth: () => ({ accessToken: "test-token" }),
}));

vi.mock("@/services/notificationService", () => ({
  buildNotificationConnection: () => ({
    on: vi.fn(),
    start: vi.fn(async () => undefined),
    stop: vi.fn(async () => undefined),
  }),
  getNotifications: async () => [],
  getCountNonLues: async () => 0,
  marquerLue: async () => undefined,
  marquerToutesLues: async () => undefined,
}));

describe("NotificationContext", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it("counts local notifications as unread", async () => {
    const TestComponent = () => {
      const { nonLues, addNotification } = useNotification();

      useEffect(() => {
        addNotification("Test", "Contenu", "info");
      }, [addNotification]);

      return <div data-testid="unread-count">{nonLues}</div>;
    };

    render(
      <NotificationProvider>
        <TestComponent />
      </NotificationProvider>,
    );

    await waitFor(() => expect(screen.getByTestId("unread-count")).toHaveTextContent("1"));
  });
});
