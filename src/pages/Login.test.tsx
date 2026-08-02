import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";

import Login from "./Login";

const loginMock = vi.fn();
const navigateMock = vi.fn();

vi.mock("@/contexts", () => ({
  useAuth: () => ({
    login: loginMock,
    loginWithGoogle: vi.fn(),
  }),
}));

vi.mock("@react-oauth/google", () => ({
  GoogleLogin: () => null,
}));

vi.mock("@/contexts/LanguageContext", () => ({
  useLanguage: () => ({
    t: (key: string) => key,
  }),
}));

vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual<typeof import("react-router-dom")>("react-router-dom");
  return {
    ...actual,
    useNavigate: () => navigateMock,
  };
});

describe("Login page", () => {
  beforeEach(() => {
    loginMock.mockReset();
    navigateMock.mockReset();
    loginMock.mockResolvedValue({ access_token: "jwt-token", role: "CUSTOMER" });
  });

  it("does not submit an empty form", () => {
    render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>,
    );

    fireEvent.click(screen.getByRole("button", { name: "Se connecter" }));

    expect(loginMock).not.toHaveBeenCalled();
  });

  it("submits login when form is valid", async () => {
    render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>,
    );

    fireEvent.change(screen.getByPlaceholderText("exemple@domaine.com"), {
      target: { value: "john@example.com" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "secret123" },
    });

    fireEvent.click(screen.getByRole("button", { name: "Se connecter" }));

    await waitFor(() => {
      expect(loginMock).toHaveBeenCalledWith("john@example.com", "secret123");
       expect(navigateMock).toHaveBeenCalledWith("/", { replace: true });
     });
   });

  it.each([
    ["ADMIN", "/admin"],
    ["VENDOR", "/vendor/dashboard"],
  ])("redirects a %s to its workspace", async (role, destination) => {
    loginMock.mockResolvedValue({ access_token: "jwt-token", role });
    render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>,
    );

    fireEvent.change(screen.getByPlaceholderText("exemple@domaine.com"), {
      target: { value: "user@example.com" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "secret123" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Se connecter" }));

    await waitFor(() => {
      expect(navigateMock).toHaveBeenCalledWith(destination, { replace: true });
    });
  });
});
