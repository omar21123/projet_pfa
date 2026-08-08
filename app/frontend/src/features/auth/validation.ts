import { z } from "zod";

// Name: min 2 chars, no digits or special chars (only letters, spaces, hyphens, apostrophes)
const nameRegex = /^[A-Za-zÀ-ÖØ-öø-ÿ '-]{2,}$/;

export const firstNameSchema = z
  .string()
  .min(2, { message: "Au moins 2 caractères" })
  .regex(nameRegex, { message: "Nom invalide (pas de chiffres ni caractères spéciaux)" });

export const lastNameSchema = firstNameSchema;

// Moroccan phone: allow local 06/07 or +2126/7, accept typical variants
const phoneLocal = /^(06|07)\d{8}$/;
const phoneIntl = /^(?:\+212|00212)(6|7)\d{8}$/;

export const phoneSchema = z
  .string()
  .min(10, { message: "Numéro trop court" })
  .max(15, { message: "Numéro invalide" })
  .refine((val) => phoneLocal.test(val) || phoneIntl.test(val), {
    message: "Format de téléphone marocain invalide (06/07/+212)",
  });

export const emailSchema = z.string().email({ message: "Email invalide" });

export const passwordSchema = z
  .string()
  .min(8, { message: "Le mot de passe doit contenir au moins 8 caractères" })
  .refine((val) => /[A-Z]/.test(val), { message: "Doit contenir au moins une lettre majuscule" })
  .refine((val) => /[a-z]/.test(val), { message: "Doit contenir au moins une lettre minuscule" })
  .refine((val) => /\d/.test(val), { message: "Doit contenir au moins un chiffre" })
  .refine((val) => /[^A-Za-z0-9]/.test(val), {
    message: "Doit contenir au moins un caractère spécial",
  });

export const signupSchema = z.object({
  firstName: firstNameSchema,
  lastName: lastNameSchema,
  phone: phoneSchema,
  email: emailSchema,
  password: passwordSchema,
});

export type SignupValues = z.infer<typeof signupSchema>;
