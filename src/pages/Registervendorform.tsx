// src/components/auth/RegisterVendorForm.tsx
import { useState } from "react";
import { Link } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { useAuthForm } from "@/features/auth/useAuthForm";
import {
  ChevronLeft,
  ChevronRight,
  Check,
  User,
  Store,
  Mail,
  Phone,
  Lock,
  Calendar,
  Upload,
} from "lucide-react";

interface RegisterVendorFormProps {
  onBack: () => void;
}

// Correction du mapping : Modification de store_name en company_name pour correspondre à Laravel
interface VendorRegisterPayload {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number: string;
  birth_date: string;
  gender: number | null;
  avatar: File | null;
  store_name: string;
  description: string;
}

const STEPS = [
  { key: "account", label: "Compte", icon: User },
  { key: "store", label: "Boutique", icon: Store },
] as const;

const emptyPayload: VendorRegisterPayload = {
  first_name: "",
  last_name: "",
  email: "",
  password: "",
  phone_number: "",
  birth_date: "",
  gender: null,
  avatar: null,
  store_name: "",
  description: "",
};

const RegisterVendorForm = ({ onBack }: RegisterVendorFormProps) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [data, setData] = useState<VendorRegisterPayload>(emptyPayload);

  // Branchement du Hook personnalisé de l'API Laravel
  const { submitRegisterVendor, isLoading, error, setError } = useAuthForm();

  const isLastStep = currentStep === STEPS.length - 1;

  const update = (patch: Partial<VendorRegisterPayload>) => {
    setData((prev) => ({ ...prev, ...patch }));
  };

  const validateEmail = (value: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

  const validateCurrentStep = () => {
    if (currentStep === 0) {
      const { first_name, last_name, email, password } = data;
      if (!first_name || !last_name || !email || !password) {
        return "Veuillez remplir les champs obligatoires (nom, prénom, email, mot de passe).";
      }
      if (!validateEmail(email)) return "Adresse email invalide.";
      if (password.length < 6) return "Le mot de passe doit contenir au moins 6 caractères.";
    }
    if (currentStep === 1) {
      if (!data.store_name) return "Le nom de la boutique/entreprise est requis.";
    }
    return "";
  };

  const goNext = () => {
    const validationError = validateCurrentStep();
    if (validationError) {
      setError(validationError);
      return;
    }
    setError("");
    setCurrentStep((s) => Math.min(s + 1, STEPS.length - 1));
  };

  const goPrev = () => {
    setError("");
    if (currentStep === 0) {
      onBack();
      return;
    }
    setCurrentStep((s) => Math.max(s - 1, 0));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const validationError = validateCurrentStep();
    if (validationError) {
      setError(validationError);
      return;
    }

    // Création du FormData obligatoire pour le téléversement de l'avatar (Multipart file upload)
    const formData = new FormData();
    formData.append("first_name", data.first_name);
    formData.append("last_name", data.last_name);
    formData.append("email", data.email);
    formData.append("password", data.password);
    formData.append("store_name", data.store_name); // Envoyé à Laravel

    if (data.phone_number) formData.append("phone_number", data.phone_number);
    if (data.birth_date) formData.append("birth_date", data.birth_date);
    if (data.gender !== null) formData.append("gender", String(data.gender));
    if (data.description) formData.append("description", data.description);
    if (data.avatar) formData.append("avatar", data.avatar); // Fichier binaire

    try {
      await submitRegisterVendor(formData);
    } catch {
      // Erreur interceptée automatiquement par useAuthForm
    }
  };

  return (
    <div>
      {/* Indicateur d'étapes */}
      <div className="flex items-center gap-1.5 mb-8">
        {STEPS.map((step, index) => {
          const isDone = index < currentStep;
          const isActive = index === currentStep;
          return (
            <div key={step.key} className="flex items-center flex-1 last:flex-none">
              <div
                className={`size-7 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 transition-colors ${
                  isDone
                    ? "bg-[#2c3e50] text-white"
                    : isActive
                      ? "bg-slate-900 text-white"
                      : "bg-slate-100 text-slate-400"
                }`}
              >
                {isDone ? <Check size={12} /> : index + 1}
              </div>
              {index < STEPS.length - 1 && (
                <div
                  className={`h-px flex-1 mx-1.5 transition-colors ${
                    isDone ? "bg-[#2c3e50]" : "bg-slate-200"
                  }`}
                />
              )}
            </div>
          );
        })}
      </div>

      <button
        type="button"
        onClick={goPrev}
        className="mb-6 inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
      >
        <ChevronLeft size={14} />
        {currentStep === 0 ? "Changer de rôle" : "Étape précédente"}
      </button>

      <div className="mb-8">
        <h2 className="text-3xl font-black tracking-tight text-slate-900">Compte fournisseur</h2>
        <p className="mt-2 text-sm text-slate-500 leading-relaxed">
          Étape {currentStep + 1} sur {STEPS.length} — {STEPS[currentStep].label}
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <AnimatePresence mode="wait">
          {error && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              role="alert"
              className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-3 font-medium flex items-center gap-2 border border-red-100"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
              {error}
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence mode="wait">
          {currentStep === 0 && (
            <motion.div
              key="account"
              initial={{ opacity: 0, x: 12 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -12 }}
              className="space-y-4"
            >
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Nom
                  </label>
                  <div className="mt-1.5 relative">
                    <User
                      className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                      size={15}
                    />
                    <input
                      type="text"
                      value={data.last_name}
                      onChange={(e) => update({ last_name: e.target.value })}
                      placeholder="Bourass"
                      className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                    />
                  </div>
                </div>
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Prénom
                  </label>
                  <div className="mt-1.5 relative">
                    <input
                      type="text"
                      value={data.first_name}
                      onChange={(e) => update({ first_name: e.target.value })}
                      placeholder="Mohammed"
                      className="w-full h-12 px-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Email
                </label>
                <div className="mt-1.5 relative">
                  <Mail
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                    size={15}
                  />
                  <input
                    type="email"
                    value={data.email}
                    onChange={(e) => update({ email: e.target.value })}
                    placeholder="vendor@example.com"
                    className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                  />
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Mot de passe
                </label>
                <div className="mt-1.5 relative">
                  <Lock
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                    size={15}
                  />
                  <input
                    type="password"
                    value={data.password}
                    onChange={(e) => update({ password: e.target.value })}
                    placeholder="••••••••"
                    className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                  />
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Téléphone <span className="normal-case text-slate-300">(optionnel)</span>
                </label>
                <div className="mt-1.5 relative">
                  <Phone
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                    size={15}
                  />
                  <input
                    type="tel"
                    value={data.phone_number}
                    onChange={(e) => update({ phone_number: e.target.value })}
                    placeholder="+212612345078"
                    className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Date de naissance <span className="normal-case text-slate-300">(opt.)</span>
                  </label>
                  <div className="mt-1.5 relative">
                    <Calendar
                      className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                      size={15}
                    />
                    <input
                      type="date"
                      value={data.birth_date}
                      onChange={(e) => update({ birth_date: e.target.value })}
                      className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                    />
                  </div>
                </div>
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Genre <span className="normal-case text-slate-300">(opt.)</span>
                  </label>
                  <select
                    value={data.gender ?? ""}
                    onChange={(e) =>
                      update({ gender: e.target.value === "" ? null : Number(e.target.value) })
                    }
                    className="mt-1.5 w-full h-12 px-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                  >
                    <option value="">—</option>
                    <option value={1}>Homme</option>
                    <option value={2}>Femme</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Avatar <span className="normal-case text-slate-300">(optionnel)</span>
                </label>
                <label className="mt-1.5 flex items-center gap-3 h-12 px-3.5 rounded-xl bg-white border border-dashed border-slate-300 hover:border-slate-900 cursor-pointer transition text-sm font-medium text-slate-500">
                  <Upload size={15} className="text-slate-400 shrink-0" />
                  <span className="truncate">
                    {data.avatar ? data.avatar.name : "Choisir une image"}
                  </span>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => update({ avatar: e.target.files?.[0] ?? null })}
                    className="hidden"
                  />
                </label>
              </div>
            </motion.div>
          )}

          {currentStep === 1 && (
            <motion.div
              key="store"
              initial={{ opacity: 0, x: 12 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -12 }}
              className="space-y-4"
            >
              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Nom de la boutique
                </label>
                <div className="mt-1.5 relative">
                  <Store
                    className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
                    size={15}
                  />
                  <input
                    type="text"
                    value={data.store_name}
                    onChange={(e) => update({ store_name: e.target.value })}
                    placeholder="eByte Store"
                    className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
                  />
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Description <span className="normal-case text-slate-300">(optionnel)</span>
                </label>
                <textarea
                  value={data.description}
                  onChange={(e) => update({ description: e.target.value })}
                  placeholder="Décrivez votre activité en quelques mots..."
                  rows={4}
                  className="mt-1.5 w-full px-3.5 py-3 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition resize-none"
                />
              </div>

              <p className="text-xs text-slate-400 leading-relaxed">
                Vous pourrez compléter votre profil (logo, bannière, documents de vérification)
                depuis votre tableau de bord après l'inscription.
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="flex gap-3 pt-2">
          {!isLastStep ? (
            <Button
              type="button"
              onClick={goNext}
              className="w-full h-12 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md active:scale-[0.99] gap-2 flex items-center justify-center"
            >
              Continuer
              <ChevronRight className="size-4" />
            </Button>
          ) : (
            <Button
              type="submit"
              disabled={isLoading}
              className="w-full h-12 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md active:scale-[0.99] gap-2 flex items-center justify-center disabled:opacity-50"
            >
              {isLoading ? (
                <div className="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                "Créer mon compte fournisseur"
              )}
            </Button>
          )}
        </div>

        <p className="text-xs text-slate-500 text-center pt-4 font-medium">
          Déjà un compte ?{" "}
          <Link to="/login" className="text-slate-900 font-bold hover:underline ml-1">
            Se connecter
          </Link>
        </p>
      </form>
    </div>
  );
};

export default RegisterVendorForm;
