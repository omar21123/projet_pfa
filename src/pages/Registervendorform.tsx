import React, { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { GoogleLogin } from "@react-oauth/google";
import { useAuth } from "@/contexts/AuthContext";

// Décodage simple du JWT Google pour afficher le Nom / Prénom / Email
const decodeJwt = (token: string) => {
  try {
    const base64Url = token.split(".")[1];
    const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split("")
        .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
        .join(""),
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
};

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
// Numéro international souple : + optionnel, 8 à 15 chiffres
const PHONE_REGEX = /^\+?[0-9]{8,15}$/;
const MAX_AVATAR_SIZE_MB = 4;
const ALLOWED_AVATAR_TYPES = ["image/jpeg", "image/png", "image/webp"];

export const RegisterVendorForm: React.FC = () => {
  const navigate = useNavigate();
  const { registerVendor, loginWithGoogle } = useAuth();
  const avatarInputRef = useRef<HTMLInputElement>(null);

  // Champs du formulaire — alignés sur le schéma exact de /api/auth/web/vendor/register
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [gender, setGender] = useState<number | null>(null);
  const [avatar, setAvatar] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [storeName, setStoreName] = useState("");
  const [description, setDescription] = useState("");

  // Erreurs de validation par champ (affichage inline, en plus du message global)
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  // Jeton Google temporaire
  const [googleIdToken, setGoogleIdToken] = useState<string | null>(null);

  // États UI
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [infoMessage, setInfoMessage] = useState<string | null>(null);

  // 1. Étape d'authentification Google (Bouton Google)
  const handleGoogleSuccess = (credentialResponse: any) => {
    const idToken = credentialResponse.credential;
    if (!idToken) {
      setErrorMessage("Échec du traitement du compte Google.");
      return;
    }

    const decoded = decodeJwt(idToken);
    if (decoded) {
      setFirstName(decoded.given_name || decoded.name || "");
      setLastName(decoded.family_name || "");
      setEmail(decoded.email || "");
    }

    setGoogleIdToken(idToken);
    setErrorMessage(null);
    setFieldErrors({});
    setInfoMessage(
      "Compte Google associé ! Prénom, Nom et Email ont été verrouillés. Veuillez saisir le Nom de votre boutique pour finaliser.",
    );
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] ?? null;

    if (!file) {
      setAvatar(null);
      setAvatarPreview(null);
      return;
    }

    if (!ALLOWED_AVATAR_TYPES.includes(file.type)) {
      setFieldErrors((prev) => ({
        ...prev,
        avatar: "Format non supporté. Utilisez une image JPEG, PNG ou WebP.",
      }));
      if (avatarInputRef.current) avatarInputRef.current.value = "";
      setAvatar(null);
      setAvatarPreview(null);
      return;
    }

    if (file.size > MAX_AVATAR_SIZE_MB * 1024 * 1024) {
      setFieldErrors((prev) => ({
        ...prev,
        avatar: `L'image est trop volumineuse (max ${MAX_AVATAR_SIZE_MB} Mo).`,
      }));
      if (avatarInputRef.current) avatarInputRef.current.value = "";
      setAvatar(null);
      setAvatarPreview(null);
      return;
    }

    setFieldErrors((prev) => {
      const { avatar: _omit, ...rest } = prev;
      return rest;
    });
    setAvatar(file);
    setAvatarPreview(URL.createObjectURL(file));
  };

  const removeAvatar = () => {
    setAvatar(null);
    setAvatarPreview(null);
    if (avatarInputRef.current) avatarInputRef.current.value = "";
  };

  /**
   * Validation frontend complète, alignée sur les contraintes attendues par
   * /api/auth/web/vendor/register (multipart/form-data) :
   * first_name*, last_name*, email*, password*, phone_number, birth_date,
   * gender, avatar, store_name*, description
   */
  const validate = (): boolean => {
    const errors: Record<string, string> = {};

    // Champs verrouillés par Google : déjà garantis non vides (extraits du token)
    if (!googleIdToken) {
      if (!firstName.trim()) errors.firstName = "Le prénom est obligatoire.";
      if (!lastName.trim()) errors.lastName = "Le nom est obligatoire.";

      if (!email.trim()) {
        errors.email = "L'adresse email est obligatoire.";
      } else if (!EMAIL_REGEX.test(email.trim())) {
        errors.email = "Adresse email invalide.";
      }

      if (!password) {
        errors.password = "Le mot de passe est obligatoire.";
      } else if (password.length < 8) {
        errors.password = "Le mot de passe doit contenir au moins 8 caractères.";
      }

      if (!confirmPassword) {
        errors.confirmPassword = "Veuillez confirmer le mot de passe.";
      } else if (password !== confirmPassword) {
        errors.confirmPassword = "Les mots de passe ne correspondent pas.";
      }
    }

    if (!storeName.trim()) {
      errors.storeName = "Le nom de la boutique est obligatoire.";
    } else if (storeName.trim().length < 2) {
      errors.storeName = "Le nom de la boutique doit contenir au moins 2 caractères.";
    }

    if (description && description.length > 1000) {
      errors.description = "La description ne peut pas dépasser 1000 caractères.";
    }

    // Champs optionnels : validés seulement si renseignés
    if (phoneNumber.trim() && !PHONE_REGEX.test(phoneNumber.trim())) {
      errors.phoneNumber = "Numéro de téléphone invalide (8 à 15 chiffres, + optionnel).";
    }

    if (birthDate) {
      const date = new Date(birthDate);
      const today = new Date();
      if (Number.isNaN(date.getTime())) {
        errors.birthDate = "Date de naissance invalide.";
      } else if (date > today) {
        errors.birthDate = "La date de naissance ne peut pas être dans le futur.";
      } else {
        const age = today.getFullYear() - date.getFullYear();
        if (age < 18) errors.birthDate = "Vous devez avoir au moins 18 ans.";
      }
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // 2. Soumission finale du formulaire
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!validate()) {
      setErrorMessage("Veuillez corriger les champs indiqués ci-dessous.");
      return;
    }

    setLoading(true);

    try {
      if (googleIdToken) {
        // Inscription Google en 1 seul appel : rôle + infos boutique envoyés directement
        await loginWithGoogle({
          id_token: googleIdToken,
          role: "VENDOR",
          store_name: storeName.trim(),
          description: description.trim() || undefined,
          phone_number: phoneNumber.trim() || undefined,
          birth_date: birthDate || undefined,
          gender: gender ?? undefined,
        });

        navigate("/vendor/dashboard");
      } else {
        // Inscription classique par email / mot de passe — multipart/form-data
        const formData = new FormData();
        formData.append("first_name", firstName.trim());
        formData.append("last_name", lastName.trim());
        formData.append("email", email.trim());
        formData.append("password", password);
        formData.append("store_name", storeName.trim());

        if (phoneNumber.trim()) formData.append("phone_number", phoneNumber.trim());
        if (birthDate) formData.append("birth_date", birthDate);
        if (gender !== null) formData.append("gender", String(gender));
        if (description.trim()) formData.append("description", description.trim());
        if (avatar) formData.append("avatar", avatar);

        await registerVendor(formData);
        navigate("/login");
      }
    } catch (error: any) {
      console.error("Erreur d'inscription :", error);

      // Remonte les erreurs de validation renvoyées par le backend (422) sur les bons champs
      const backendErrors = error?.response?.data?.errors;
      if (backendErrors && typeof backendErrors === "object") {
        const mapped: Record<string, string> = {};
        Object.entries(backendErrors).forEach(([key, messages]) => {
          const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
          mapped[camelKey] = Array.isArray(messages) ? String(messages[0]) : String(messages);
        });
        setFieldErrors((prev) => ({ ...prev, ...mapped }));
      }

      setErrorMessage(
        error.response?.data?.message ||
          error.message ||
          "Une erreur est survenue lors de l'inscription.",
      );
    } finally {
      setLoading(false);
    }
  };

  const fieldClass = (hasError: boolean, disabled = false) =>
    `w-full p-3.5 border rounded-xl text-sm transition-colors ${
      disabled
        ? "bg-gray-100 border-gray-200 text-gray-500 cursor-not-allowed font-medium"
        : hasError
          ? "bg-white border-red-400 focus:outline-none focus:border-red-500"
          : "bg-white border-gray-200 focus:outline-none focus:border-slate-800"
    }`;

  return (
    <div className="w-full max-w-lg mx-auto p-8 bg-white rounded-3xl shadow-sm border border-gray-100">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Créer un compte Vendeur</h2>

      {infoMessage && (
        <div className="p-3.5 mb-5 bg-blue-50 border border-blue-200 text-blue-700 rounded-xl text-xs font-medium flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-blue-500 shrink-0" />
          {infoMessage}
        </div>
      )}

      {errorMessage && (
        <div className="p-3.5 mb-5 bg-red-50 border border-red-200 text-red-600 rounded-xl text-xs font-medium flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-red-500 shrink-0" />
          {errorMessage}
        </div>
      )}

      <form onSubmit={handleSubmit} noValidate className="space-y-4">
        {/* Prénom & Nom */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
              Prénom <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              disabled={!!googleIdToken}
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              className={fieldClass(!!fieldErrors.firstName, !!googleIdToken)}
              placeholder="Jean"
            />
            {fieldErrors.firstName && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.firstName}</p>
            )}
          </div>

          <div>
            <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
              Nom <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              disabled={!!googleIdToken}
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              className={fieldClass(!!fieldErrors.lastName, !!googleIdToken)}
              placeholder="Dupont"
            />
            {fieldErrors.lastName && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.lastName}</p>
            )}
          </div>
        </div>

        {/* Email */}
        <div>
          <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
            Adresse Email <span className="text-red-500">*</span>
          </label>
          <input
            type="email"
            disabled={!!googleIdToken}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={fieldClass(!!fieldErrors.email, !!googleIdToken)}
            placeholder="vendeur@exemple.com"
          />
          {fieldErrors.email && (
            <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.email}</p>
          )}
        </div>

        {/* Mot de passe + confirmation : masqués si Google est utilisé */}
        {!googleIdToken && (
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
                Mot de passe <span className="text-red-500">*</span>
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={fieldClass(!!fieldErrors.password)}
                placeholder="••••••••"
              />
              {fieldErrors.password && (
                <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.password}</p>
              )}
            </div>
            <div>
              <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
                Confirmer <span className="text-red-500">*</span>
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className={fieldClass(!!fieldErrors.confirmPassword)}
                placeholder="••••••••"
              />
              {fieldErrors.confirmPassword && (
                <p className="mt-1 text-[11px] text-red-600 font-medium">
                  {fieldErrors.confirmPassword}
                </p>
              )}
            </div>
          </div>
        )}

        {/* Téléphone & Date de naissance */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
              Téléphone <span className="text-gray-400 font-normal lowercase">(opt.)</span>
            </label>
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              className={fieldClass(!!fieldErrors.phoneNumber)}
              placeholder="+212612345678"
            />
            {fieldErrors.phoneNumber && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.phoneNumber}</p>
            )}
          </div>
          <div>
            <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
              Naissance <span className="text-gray-400 font-normal lowercase">(opt.)</span>
            </label>
            <input
              type="date"
              value={birthDate}
              onChange={(e) => setBirthDate(e.target.value)}
              className={fieldClass(!!fieldErrors.birthDate)}
            />
            {fieldErrors.birthDate && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.birthDate}</p>
            )}
          </div>
        </div>

        {/* Genre */}
        <div>
          <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
            Genre <span className="text-gray-400 font-normal lowercase">(optionnel)</span>
          </label>
          <select
            value={gender ?? ""}
            onChange={(e) => setGender(e.target.value === "" ? null : Number(e.target.value))}
            className="w-full p-3.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-slate-800 transition-colors"
          >
            <option value="">—</option>
            <option value={1}>Homme</option>
            <option value={2}>Femme</option>
          </select>
        </div>

        {/* Avatar (uniquement pour l'inscription classique — Google fournit déjà une photo) */}
        {!googleIdToken && (
          <div>
            <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
              Photo de profil <span className="text-gray-400 font-normal lowercase">(optionnel)</span>
            </label>
            <div className="flex items-center gap-4">
              {avatarPreview ? (
                <img
                  src={avatarPreview}
                  alt="Aperçu avatar"
                  className="w-14 h-14 rounded-full object-cover border border-gray-200"
                />
              ) : (
                <div className="w-14 h-14 rounded-full bg-gray-100 border border-gray-200 flex items-center justify-center text-gray-400 text-[10px] font-semibold uppercase">
                  Photo
                </div>
              )}
              <div className="flex-1 flex items-center gap-2">
                <input
                  ref={avatarInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleAvatarChange}
                  className="text-xs text-gray-500 file:mr-3 file:py-2 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200"
                />
                {avatar && (
                  <button
                    type="button"
                    onClick={removeAvatar}
                    className="text-[11px] font-bold text-red-500 hover:underline shrink-0"
                  >
                    Retirer
                  </button>
                )}
              </div>
            </div>
            {fieldErrors.avatar && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.avatar}</p>
            )}
          </div>
        )}

        {/* Nom de la boutique */}
        <div>
          <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
            Nom de la boutique <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            value={storeName}
            onChange={(e) => setStoreName(e.target.value)}
            className={`w-full p-3.5 bg-white border-2 rounded-xl text-sm focus:outline-none transition-colors font-medium ${
              fieldErrors.storeName
                ? "border-red-400 focus:border-red-500"
                : "border-slate-800 focus:border-black"
            }`}
            placeholder="Nom de votre boutique"
          />
          {fieldErrors.storeName && (
            <p className="mt-1 text-[11px] text-red-600 font-medium">{fieldErrors.storeName}</p>
          )}
        </div>

        {/* Description */}
        <div>
          <label className="block text-[11px] font-bold text-gray-500 uppercase mb-2 tracking-wider">
            Description <span className="text-gray-400 font-normal lowercase">(optionnel)</span>
          </label>
          <textarea
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            maxLength={1000}
            className={fieldClass(!!fieldErrors.description) + " resize-none"}
            placeholder="Décrivez vos produits..."
          />
          <div className="mt-1 flex items-center justify-between">
            {fieldErrors.description ? (
              <p className="text-[11px] text-red-600 font-medium">{fieldErrors.description}</p>
            ) : (
              <span />
            )}
            <span className="text-[10px] text-gray-400">{description.length}/1000</span>
          </div>
        </div>

        {/* Bouton de soumission */}
        <button
          type="submit"
          disabled={loading}
          className="w-full py-4 bg-[#1e293b] hover:bg-[#0f172a] text-white font-semibold text-sm rounded-2xl shadow-md transition-all disabled:opacity-50 flex items-center justify-center"
        >
          {loading
            ? "Traitement..."
            : googleIdToken
              ? "Finaliser mon inscription Vendeur"
              : "Créer mon compte Vendeur"}
        </button>
      </form>

      {/* Bouton Google SSO (Masqué dès que Google est connecté) */}
      {!googleIdToken && (
        <>
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-white px-3 font-semibold text-gray-400">Ou continuer avec</span>
            </div>
          </div>

          <div className="flex justify-center w-full">
            <GoogleLogin
              onSuccess={handleGoogleSuccess}
              onError={() => setErrorMessage("Erreur lors de l'authentification Google.")}
              theme="outline"
              shape="rectangular"
              width="100%"
            />
          </div>
        </>
      )}
    </div>
  );
};

export default RegisterVendorForm;