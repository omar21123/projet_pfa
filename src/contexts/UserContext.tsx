import { createContext, useCallback, useContext, useEffect, useState, ReactNode } from "react";
import { STORAGE_KEYS } from "@/config/constants";
import type { AuthResponse, User } from "@/types/user.types";

interface UserContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (authResponse: AuthResponse) => void;
  logout: () => void;
  updateUser: (name: string) => void;
}

export type { User, UserContextType };

const UserContext = createContext<UserContextType | undefined>(undefined);

export { UserContext };

const parseJwtPayload = (token: string): Record<string, unknown> | null => {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) {
      return null;
    }

    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split("")
        .map((char) => `%${`00${char.charCodeAt(0).toString(16)}`.slice(-2)}`)
        .join(""),
    );

    return JSON.parse(jsonPayload) as Record<string, unknown>;
  } catch {
    return null;
  }
};

const toStringClaim = (payload: Record<string, unknown> | null, keys: string[]): string => {
  if (!payload) {
    return "";
  }

  for (const key of keys) {
    const value = payload[key];
    if (typeof value === "string" && value.trim()) {
      return value;
    }
  }

  return "";
};

const buildUserFromToken = (token: string): User => {
  const payload = parseJwtPayload(token);
  const email = toStringClaim(payload, ["email", "upn", "unique_name"]);
  const name = toStringClaim(payload, ["name", "given_name"]) || email.split("@")[0] || "User";
  const id =
    toStringClaim(payload, [
      "sub",
      "nameid",
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
    ]) ||
    email ||
    `${Date.now()}`;
  const verifiedClaim = payload?.email_verified;

  return {
    id,
    email,
    name,
    verified: typeof verifiedClaim === "boolean" ? verifiedClaim : true,
  };
};

const isUser = (value: unknown): value is User => {
  if (!value || typeof value !== "object") {
    return false;
  }

  const candidate = value as User;
  return (
    typeof candidate.id === "string" &&
    typeof candidate.email === "string" &&
    typeof candidate.name === "string"
  );
};

const extractUser = (data: unknown): User | null => {
  if (isUser(data)) {
    return data;
  }

  if (
    data &&
    typeof data === "object" &&
    "user" in data &&
    isUser((data as { user?: unknown }).user)
  ) {
    return (data as { user: User }).user;
  }

  return null;
};

const readStoredUser = (): User | null => {
  const storedUser = localStorage.getItem(STORAGE_KEYS.USER);

  if (!storedUser) {
    return null;
  }

  try {
    const parsedUser = JSON.parse(storedUser) as unknown;
    return isUser(parsedUser) ? parsedUser : null;
  } catch {
    localStorage.removeItem(STORAGE_KEYS.USER);
    return null;
  }
};

export const UserProvider = ({ children }: { children: ReactNode }) => {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem(STORAGE_KEYS.TOKEN));
  const [user, setUser] = useState<User | null>(() => {
    const storedUser = readStoredUser();

    if (storedUser) {
      return storedUser;
    }

    const storedToken = localStorage.getItem(STORAGE_KEYS.TOKEN);
    return storedToken ? buildUserFromToken(storedToken) : null;
  });
  const [isLoading, setIsLoading] = useState(true);

  const login = useCallback((authResponse: AuthResponse) => {
    const nextToken = authResponse.token;
    const nextUser = authResponse.user ?? buildUserFromToken(nextToken);

    setToken(nextToken);
    setUser(nextUser);

    localStorage.setItem(STORAGE_KEYS.TOKEN, nextToken);
    localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(nextUser));
  }, []);

  const logout = useCallback(() => {
    setUser(null);
    setToken(null);
    localStorage.removeItem(STORAGE_KEYS.USER);
    localStorage.removeItem(STORAGE_KEYS.TOKEN);
  }, []);

  const updateUser = useCallback(
    (name: string) => {
      if (user) {
        const updatedUser = { ...user, name };
        setUser(updatedUser);
        localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(updatedUser));
      }
    },
    [user],
  );

  useEffect(() => {
    const storedToken = localStorage.getItem(STORAGE_KEYS.TOKEN);
    const storedUser = readStoredUser();

    if (storedToken) {
      setToken(storedToken);
      if (storedUser) {
        setUser(storedUser);
      } else {
        setUser(buildUserFromToken(storedToken));
      }
    } else {
      setUser(null);
      setToken(null);
    }

    setIsLoading(false);
  }, []);

  useEffect(() => {
    const handleUnauthorized = () => {
      logout();
    };

    window.addEventListener("unauthorized", handleUnauthorized);

    return () => {
      window.removeEventListener("unauthorized", handleUnauthorized);
    };
  }, [logout]);

  useEffect(() => {
    const handleAuthLogin = (e: Event) => {
      try {
        const detail = (e as CustomEvent)?.detail ?? {};
        const nextToken = detail.token ?? detail.accessToken ?? null;
        const nextUser = detail.user ?? undefined;

        if (!nextToken) return;

        // Use the existing login function to set state + localStorage
        login({ token: nextToken, user: nextUser });
      } catch {
        // ignore malformed events
      }
    };

    window.addEventListener("auth:login", handleAuthLogin as EventListener);

    return () => {
      window.removeEventListener("auth:login", handleAuthLogin as EventListener);
    };
  }, [login]);

  const value = {
    user,
    token,
    isLoading,
    login,
    logout,
    updateUser,
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
};
