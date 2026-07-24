// src/components/auth/RegisterClientForm.tsx
import { useState } from "react";
import { Link } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { ChevronLeft, User, Mail, Phone, Lock, Calendar, ArrowRight } from "lucide-react";
import { useAuthForm } from "@/features/auth/useAuthForm";
import type { RegisterRequestClient } from "@/types/user.types";

interface RegisterClientFormProps {
  onBack: () => void;
}

interface ClientFormState {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  confirmPassword: string;
  phone_number: string;
  birth_date: string;
  gender: number | null;
}

const emptyState: ClientFormState = {
  first_name: "",
  last_name: "",
  email: "",
  password: "",
  confirmPassword: "",
  phone_number: "",
  birth_date: "",
  gender: null,
};

const RegisterClientForm = ({ onBack }: RegisterClientFormProps) => {
  const [data, setData] = useState<ClientFormState>(emptyState);
  
  // Intégration du hook d'authentification Laravel
  const { submitRegisterClient, isLoading, error, setError } = useAuthForm();

  const update = (patch: Partial<ClientFormState>) => {
    setData((prev) => ({ ...prev, ...patch }));
  };

  const validateEmail = (value: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (!data.first_name || !data.last_name || !data.email || !data.password) {
      setError("Veuillez remplir les champs obligatoires (nom, prénom, email, mot de passe).");
      return;
    }
    if (!validateEmail(data.email)) {
      setError("Adresse email invalide.");
      return;
    }
    if (data.password.length < 6) {
      setError("Le mot de passe doit contenir au moins 6 caractères.");
      return;
    }
    if (data.password !== data.confirmPassword) {
      setError("Les mots de passe ne correspondent pas.");
      return;
    }

    // Construction du payload attendu par CustomerRegisterRequest de Laravel
    const payload: RegisterRequestClient = {
      first_name: data.first_name,
      last_name: data.last_name,
      email: data.email,
      password: data.password,
      ...(data.phone_number ? { phone_number: data.phone_number } : {}),
      ...(data.birth_date ? { birth_date: data.birth_date } : {}),
      ...(data.gender ? { gender: data.gender } : {}),
    };

    try {
      await submitRegisterClient(payload);
      // Optionnel : Rediriger l'utilisateur ici après succès (ex: navigate("/dashboard"))
    } catch {
      // L'erreur globale est déjà interceptée et stockée dans 'error' par le hook useAuthForm
    }
  };

  return (
    <div>
      <button
        type="button"
        onClick={onBack}
        className="mb-6 inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
      >
        <ChevronLeft size={14} />
        Changer de rôle
      </button>

      <div className="mb-8">
        <h2 className="text-3xl font-black tracking-tight text-slate-900">Compte client</h2>
        <p className="mt-2 text-sm text-slate-500 leading-relaxed">
          Créez votre compte pour commencer à acheter.
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

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              Nom
            </label>
            <div className="mt-1.5 relative">
              <User className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
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
            <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
            <input
              type="email"
              value={data.email}
              onChange={(e) => update({ email: e.target.value })}
              placeholder="vous@marche.ma"
              className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
              Mot de passe
            </label>
            <div className="mt-1.5 relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
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
              Confirmer
            </label>
            <div className="mt-1.5 relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
              <input
                type="password"
                value={data.confirmPassword}
                onChange={(e) => update({ confirmPassword: e.target.value })}
                placeholder="••••••••"
                className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
              />
            </div>
          </div>
        </div>

        <div>
          <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
            Téléphone <span className="normal-case text-slate-300">(optionnel)</span>
          </label>
          <div className="mt-1.5 relative">
            <Phone className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
            <input
              type="tel"
              value={data.phone_number}
              onChange={(e) => update({ phone_number: e.target.value })}
              placeholder="+212612345678"
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
              <Calendar className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
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
              onChange={(e) => update({ gender: e.target.value === "" ? null : Number(e.target.value) })}
              className="mt-1.5 w-full h-12 px-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 focus:ring-1 focus:ring-slate-900 outline-none text-sm font-medium transition"
            >
              <option value="">—</option>
              <option value={1}>Homme</option>
              <option value={2}>Femme</option>
            </select>
          </div>
        </div>

        <Button
          type="submit"
          disabled={isLoading}
          className="w-full h-12 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] hover:from-[#1d2a36] hover:to-[#111921] text-white font-bold rounded-xl transition-all shadow-md active:scale-[0.99] gap-2 flex items-center justify-center disabled:opacity-50"
        >
          {isLoading ? (
            <div className="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <>
              Créer mon compte
              <ArrowRight className="size-4" />
            </>
          )}
        </Button>

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

export default RegisterClientForm;