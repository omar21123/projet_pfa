import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";

import Login from "./Login";
import { authApi } from "@/api/auth.api";

const loginMock = vi.fn();
const navigateMock = vi.fn();

vi.mock("@/api/auth.api", () => ({
  authApi: {
    login: vi.fn(),
    register: vi.fn(),
    verifyEmail: vi.fn(),
  },
}));

vi.mock("@/hooks/useUser", () => ({
  useUser: () => ({
    login: loginMock,
  }),
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
    vi.mocked(authApi.login).mockReset();
    vi.mocked(authApi.login).mockResolvedValue({
      token: "jwt-token",
      user: {
        id: "u-1",
        email: "john@example.com",
        name: "john",
      },
    });
  });

  it("shows validation error when login form is empty", () => {
    render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>,
    );

    fireEvent.click(screen.getByRole("button", { name: "sign_in" }));

    expect(screen.getByRole("alert")).toHaveTextContent("fill_all_fields");
    expect(loginMock).not.toHaveBeenCalled();
  });

  it("submits login when form is valid", async () => {
    render(
      <MemoryRouter>
        <Login />
      </MemoryRouter>,
    );

    fireEvent.change(screen.getByPlaceholderText("votre@email.com"), {
      target: { value: "john@example.com" },
    });
    fireEvent.change(screen.getByPlaceholderText("••••••••"), {
      target: { value: "secret123" },
    });

    fireEvent.click(screen.getByRole("button", { name: "sign_in" }));

    await waitFor(() => {
      expect(authApi.login).toHaveBeenCalledWith({
        email: "john@example.com",
        password: "secret123",
      });
      expect(loginMock).toHaveBeenCalledWith({
        token: "jwt-token",
        user: {
          id: "u-1",
          email: "john@example.com",
          name: "john",
        },
      });
      expect(navigateMock).toHaveBeenCalledWith("/");
    });
  });
});
