// src/features/auth/useAuthForm.ts
import axios from "axios";
import { useState } from "react";
import { authApi } from "@/api/auth.api";
import type { LaravelAuthResponse, LoginRequest, RegisterRequestClient } from "@/types/users.types";
import { useToast } from "@/hooks/use-toast";

interface AuthValues {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number: string;
  birth_date: string;
  gender: number | null;
}

interface UseAuthFormReturn {
  values: AuthValues;
  error: string;
  isLoading: boolean;
  setEmail: (value: string) => void;
  setPassword: (value: string) => void;
  setFirstName: (value: string) => void;
  setLastName: (value: string) => void;
  setPhoneNumber: (value: string) => void;
  setBirthDate: (value: string) => void;
  setGender: (value: number | null) => void;
  setError: (value: string) => void;
  reset: () => void;
  submitLogin: (credentials: LoginRequest) => Promise<LaravelAuthResponse>;
  submitRegisterClient: (payload: RegisterRequestClient) => Promise<void>;
  submitRegisterVendor: (formData: FormData) => Promise<void>;
}

/**
 * Extracteur d'erreurs optimisé pour Laravel
 * Gère les messages classiques et décortique le tableau d'erreurs 422 (Validation Requests)
 */
const getErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;

    // Si Laravel renvoie des erreurs de validation spécifiques (ex: FormRequest Validation)
    if (data?.errors && typeof data.errors === "object") {
      const firstErrorArray = Object.values(data.errors)[0];
      if (Array.isArray(firstErrorArray) && firstErrorArray.length > 0) {
        return firstErrorArray[0]; // Renvoie le premier message d'erreur précis (ex: "Cet email existe déjà.")
      }
    }

    return data?.message ?? error.message ?? "Une erreur est survenue";
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Une erreur est survenue";
};

export const useAuthForm = (): UseAuthFormReturn => {
  const [values, setValues] = useState<AuthValues>({
    first_name: "",
    last_name: "",
    email: "",
    password: "",
    phone_number: "",
    birth_date: "",
    gender: null,
  });
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  const setEmail = (email: string) => {
    setValues((prev) => ({ ...prev, email }));
  };

  const setPassword = (password: string) => {
    setValues((prev) => ({ ...prev, password }));
  };

  const setFirstName = (first_name: string) => {
    setValues((prev) => ({ ...prev, first_name }));
  };

  const setLastName = (last_name: string) => {
    setValues((prev) => ({ ...prev, last_name }));
  };

  const setPhoneNumber = (phone_number: string) => {
    setValues((prev) => ({ ...prev, phone_number }));
  };

  const setBirthDate = (birth_date: string) => {
    setValues((prev) => ({ ...prev, birth_date }));
  };

  const setGender = (gender: number | null) => {
    setValues((prev) => ({ ...prev, gender }));
  };

  const reset = () => {
    setValues({
      first_name: "",
      last_name: "",
      email: "",
      password: "",
      phone_number: "",
      birth_date: "",
      gender: null,
    });
    setError("");
  };

  /**
   * Soumission Connexion
   */
  const submitLogin = async (credentials: LoginRequest): Promise<LaravelAuthResponse> => {
    setIsLoading(true);
    setError("");

    try {
      const response = await authApi.login(credentials);
      toast({
        title: "Connexion réussie",
        description: response.message ?? "Bienvenue sur votre espace.",
      });
      return response;
    } catch (err) {
      const message = getErrorMessage(err);
      setError(message);
      toast({
        title: "Erreur de connexion",
        description: message,
        variant: "destructive",
      });
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Soumission Inscription Client (JSON)
   */
  const submitRegisterClient = async (payload: RegisterRequestClient): Promise<void> => {
    setIsLoading(true);
    setError("");

    try {
      const response = await authApi.registerClient(payload);
      toast({
        title: "Compte créé avec succès",
        description: response.message ?? "Votre inscription a bien été enregistrée.",
      });
    } catch (err) {
      const message = getErrorMessage(err);
      setError(message);
      toast({
        title: "Erreur d'inscription",
        description: message,
        variant: "destructive",
      });
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Soumission Inscription Fournisseur (FormData / Multipart)
   */
  const submitRegisterVendor = async (formData: FormData): Promise<void> => {
    setIsLoading(true);
    setError("");

    try {
      const response = await authApi.registerVendor(formData);
      toast({
        title: "Demande partenaire envoyée",
        description: response.message ?? "Votre compte fournisseur a été créé.",
      });
    } catch (err) {
      const message = getErrorMessage(err);
      setError(message);
      toast({
        title: "Erreur d'inscription partenaire",
        description: message,
        variant: "destructive",
      });
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  return {
    values,
    error,
    isLoading,
    setEmail,
    setPassword,
    setFirstName,
    setLastName,
    setPhoneNumber,
    setBirthDate,
    setGender,
    setError,
    reset,
    submitLogin,
    submitRegisterClient,
    submitRegisterVendor,
  };
};
