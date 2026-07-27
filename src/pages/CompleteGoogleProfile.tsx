import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { authApi } from "@/api/auth.api";
import AuthLayout from "@/pages/Authlayout";
import {
  ShoppingBag,
  Store,
  ArrowRight,
  ChevronLeft,
  Phone,
  Calendar,
} from "lucide-react";

type Role = "CUSTOMER" | "VENDOR";

export const CompleteGoogleProfile: React.FC = () => {
  const navigate = useNavigate();
  const [role, setRole] = useState<Role | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  // Champs additionnels
  const [phoneNumber, setPhoneNumber] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [gender, setGender] = useState<number | null>(null);
  const [storeName, setStoreName] = useState("");
  const [description, setDescription] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!role) return;

    if (role === "VENDOR" && !storeName.trim()) {
      setError("Le nom de la boutique est obligatoire pour les vendeurs.");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      const response = await authApi.completeGoogleProfile({
        role,
        phone_number: phoneNumber || undefined,
        birth_date: birthDate || undefined,
        gender: gender || undefined,
        store_name: role === "VENDOR" ? storeName : undefined,
        description: role === "VENDOR" ? description : undefined,
      });

      // 🟢 FIX : Sécurisation de la récupération du rôle pour la redirection
      const finalRole = response.role || (response as any).user?.role || role;

      // Redirection selon le rôle finalisé
      if (finalRole === "VENDOR") {
        navigate("/vendor/dashboard");
      } else {
        navigate("/");
      }
    } catch (err: any) {
      console.error("Erreur completeGoogleProfile :", err);
      setError(
        err.response?.data?.message ||
          "Une erreur est survenue lors de la finalisation du profil."
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthLayout
      eyebrow="Bienvenue"
      title={
        <>
          Finalisez votre <br />
          <span className="text-[#d09a3f]">inscription.</span>
        </>
      }
      description="Choisissez comment vous souhaitez utiliser Marché pour continuer."
      stats={[
        { k: "100%", v: "Sécurisé" },
        { k: "Rapide", v: "< 1 minute" },
      ]}
    >
      <div>
        {/* ÉTAPE 1 : Choix du rôle */}
        {role === null && (
          <div>
            <div className="mb-8">
              <h2 className="text-3xl font-black tracking-tight text-slate-900">
                Choisissez votre rôle
              </h2>
              <p className="mt-2 text-sm text-slate-500 leading-relaxed">
                Comment souhaitez-vous utiliser votre compte ?
              </p>
            </div>

            <div className="space-y-4">
              <button
                type="button"
                onClick={() => {
                  setRole("CUSTOMER");
                  setError("");
                }}
                className="w-full text-left p-5 rounded-2xl border border-slate-200 bg-white hover:border-slate-900 hover:shadow-md transition-all group flex items-center gap-4"
              >
                <div className="size-12 rounded-xl bg-slate-100 group-hover:bg-[#2c3e50] flex items-center justify-center transition-colors shrink-0">
                  <ShoppingBag className="text-slate-500 group-hover:text-white transition-colors" size={20} />
                </div>
                <div className="flex-1">
                  <div className="font-bold text-slate-900">Je suis client</div>
                  <div className="text-xs text-slate-500 mt-0.5">Je veux acheter des produits</div>
                </div>
                <ArrowRight className="text-slate-300 group-hover:text-slate-900 transition-all" size={18} />
              </button>

              <button
                type="button"
                onClick={() => {
                  setRole("VENDOR");
                  setError("");
                }}
                className="w-full text-left p-5 rounded-2xl border border-slate-200 bg-white hover:border-slate-900 hover:shadow-md transition-all group flex items-center gap-4"
              >
                <div className="size-12 rounded-xl bg-slate-100 group-hover:bg-[#2c3e50] flex items-center justify-center transition-colors shrink-0">
                  <Store className="text-slate-500 group-hover:text-white transition-colors" size={20} />
                </div>
                <div className="flex-1">
                  <div className="font-bold text-slate-900">Je suis vendeur</div>
                  <div className="text-xs text-slate-500 mt-0.5">Je veux ouvrir une boutique et vendre</div>
                </div>
                <ArrowRight className="text-slate-300 group-hover:text-slate-900 transition-all" size={18} />
              </button>
            </div>
          </div>
        )}

        {/* ÉTAPE 2 : Formulaire selon le rôle */}
        {role !== null && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <button
              type="button"
              onClick={() => {
                setRole(null);
                setError(""); // 🟢 FIX : Reinitialise les erreurs lors du retour
              }}
              className="mb-6 inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
            >
              <ChevronLeft size={14} />
              Changer de rôle
            </button>

            <div className="mb-6">
              <h2 className="text-2xl font-black tracking-tight text-slate-900">
                {role === "VENDOR" ? "Informations Boutique" : "Informations Client"}
              </h2>
              <p className="text-xs text-slate-500 mt-1">
                Complétez votre profil pour finaliser l'accès.
              </p>
            </div>

            <AnimatePresence mode="wait">
              {error && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-3 font-medium flex items-center gap-2 border border-red-100"
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
                  {error}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Champs Vendeur Spécifiques */}
            {role === "VENDOR" && (
              <>
                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Nom de la boutique *
                  </label>
                  <div className="mt-1.5 relative">
                    <Store className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
                    <input
                      type="text"
                      required
                      value={storeName}
                      onChange={(e) => setStoreName(e.target.value)}
                      placeholder="Ma Super Boutique"
                      className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
                    />
                  </div>
                </div>

                <div>
                  <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                    Description <span className="normal-case text-slate-300">(optionnel)</span>
                  </label>
                  <textarea
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Décrivez brièvement votre boutique..."
                    rows={3}
                    className="mt-1.5 w-full p-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition resize-none"
                  />
                </div>
              </>
            )}

            {/* Champs Généraux Optionnels */}
            <div>
              <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                Téléphone <span className="normal-case text-slate-300">(optionnel)</span>
              </label>
              <div className="mt-1.5 relative">
                <Phone className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="+212600000000"
                  className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
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
                    value={birthDate}
                    onChange={(e) => setBirthDate(e.target.value)}
                    className="w-full h-12 pl-10 pr-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
                  />
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold uppercase tracking-widest text-slate-400">
                  Genre <span className="normal-case text-slate-300">(opt.)</span>
                </label>
                <select
                  value={gender ?? ""}
                  onChange={(e) => setGender(e.target.value ? Number(e.target.value) : null)}
                  className="mt-1.5 w-full h-12 px-3.5 rounded-xl bg-white border border-slate-200 focus:border-slate-900 outline-none text-sm font-medium transition"
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
              className="w-full h-12 mt-4 bg-gradient-to-r from-[#2c3e50] to-[#1d2a36] text-white font-bold rounded-xl transition-all shadow-md gap-2 flex items-center justify-center disabled:opacity-50"
            >
              {isLoading ? (
                <div className="h-5 w-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  Finaliser mon inscription
                  <ArrowRight className="size-4" />
                </>
              )}
            </Button>
          </form>
        )}
      </div>
    </AuthLayout>
  );
};

export default CompleteGoogleProfile;