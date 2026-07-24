import axios from "axios";
import { useCallback, useMemo, useState } from "react";
import { apiClient } from "../api/client";
import { authApi } from "../api/auth.api";
import {
  signupSchema,
  SignupValues,
  emailSchema,
  firstNameSchema,
  lastNameSchema,
  phoneSchema,
  passwordSchema,
} from "../features/auth/validation";
import type { RegisterRequest } from "../types/user.types";
import { z } from "zod";

type Errors = Partial<Record<keyof SignupValues, string>>;

export function useFormValidation(initial?: Partial<SignupValues>) {
  const [values, setValues] = useState<SignupValues>({
    firstName: initial?.firstName || "",
    lastName: initial?.lastName || "",
    phone: initial?.phone || "",
    email: initial?.email || "",
    password: initial?.password || "",
  });

  const [errors, setErrors] = useState<Errors>({});
  const [touched, setTouched] = useState<Partial<Record<keyof SignupValues, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [serverError, setServerError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Map field -> schema for single-field validation
  const fieldSchemas: Record<keyof SignupValues, z.ZodType<string>> = useMemo(
    () => ({
      firstName: firstNameSchema,
      lastName: lastNameSchema,
      phone: phoneSchema,
      email: emailSchema,
      password: passwordSchema,
    }),
    [],
  );

  const validateField = useCallback(
    (name: keyof SignupValues, value: string) => {
      const schema = fieldSchemas[name];
      try {
        schema.parse(value);
        return null;
      } catch (error: unknown) {
        if (error instanceof z.ZodError) {
          return error.issues[0]?.message || "Champ invalide";
        }

        return "Champ invalide";
      }
    },
    [fieldSchemas],
  );

  const validateAll = useCallback((): Errors => {
    const result = signupSchema.safeParse(values);
    if (result.success) return {};
    const out: Errors = {};
    for (const err of result.error.errors) {
      const key = err.path?.[0] as keyof SignupValues;
      out[key] = err.message;
    }
    return out;
  }, [values]);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const { name, value } = e.target;
      setValues((v) => ({ ...v, [name]: value }));
      // validate on change
      const fieldError = validateField(name as keyof SignupValues, value);
      setErrors((prev) => ({ ...prev, [name]: fieldError }));
    },
    [validateField],
  );

  const handleBlur = useCallback(
    (e: React.FocusEvent<HTMLInputElement>) => {
      const { name } = e.target;
      setTouched((t) => ({ ...t, [name]: true }));
      // ensure validation on blur too
      const fieldError = validateField(
        name as keyof SignupValues,
        values[name as keyof SignupValues],
      );
      setErrors((prev) => ({ ...prev, [name]: fieldError }));
    },
    [validateField, values],
  );

  const checkEmailExists = useCallback(async (email: string) => {
    try {
      const res = await apiClient.get("/api/Auth/check-email", { params: { email } });
      // backend should return { exists: boolean }
      return Boolean(res?.data?.exists);
    } catch {
      // if endpoint not available, fallback to false (we'll catch on register)
      return false;
    }
  }, []);

  const handleSubmit = useCallback(
    async (cb?: (data: SignupValues) => void) => {
      setServerError(null);
      setSuccessMessage(null);
      const allErrors = validateAll();
      if (Object.keys(allErrors).length > 0) {
        // mark empty fields as touched
        const emptyTouched: Partial<Record<keyof SignupValues, boolean>> = {};
        (Object.keys(values) as Array<keyof SignupValues>).forEach((k) => {
          if (!values[k]) emptyTouched[k] = true;
        });
        setTouched((t) => ({ ...t, ...emptyTouched }));
        setErrors(allErrors);
        return;
      }

      setIsSubmitting(true);
      try {
        const exists = await checkEmailExists(values.email);
        if (exists) {
          setServerError("Cet email est déjà utilisé. Voulez-vous vous connecter ?");
          setIsSubmitting(false);
          return;
        }

        const payload: RegisterRequest = {
          nom: values.lastName,
          prenom: values.firstName,
          email: values.email,
          password: values.password,
          telephone: values.phone,
        };

        const resp = await authApi.register(payload);
        setSuccessMessage(
          resp?.message || "Compte créé ! Un code de vérification a été envoyé à votre email.",
        );
        if (cb) cb(values as SignupValues);
      } catch (error: unknown) {
        if (axios.isAxiosError<{ message?: string }>(error) && error.response) {
          if (error.response.status === 409) {
            setServerError("Cet email est déjà utilisé. Voulez-vous vous connecter ?");
          } else {
            setServerError(error.response.data?.message || "Une erreur est survenue");
          }
        } else {
          setServerError("Vérifiez votre connexion Internet");
        }
      } finally {
        setIsSubmitting(false);
      }
    },
    [checkEmailExists, validateAll, values],
  );

  const isValid = useMemo(
    () => Object.values(errors).every((e) => !e) && Object.values(values).every((v) => Boolean(v)),
    [errors, values],
  );

  return {
    values,
    setValues,
    errors,
    touched,
    isSubmitting,
    serverError,
    successMessage,
    isValid,
    handleChange,
    handleBlur,
    handleSubmit,
    validateField,
  };
}

export default useFormValidation;
