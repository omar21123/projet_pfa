import { Link } from "react-router-dom";
import { ShoppingBag, Store, ArrowRight } from "lucide-react";

export type UserRole = "client" | "vendor";

interface RegisterRoleSelectProps {
  onSelect: (role: UserRole) => void;
}

/**
 * Étape 1 de l'inscription : choix du rôle.
 * Détermine ensuite quel endpoint / quelle table sera renseignée côté back
 * (CustomerProfiles vs VendorProfiles).
 */
const RegisterRoleSelect = ({ onSelect }: RegisterRoleSelectProps) => {
  return (
    <div>
      <div className="mb-8">
        <h2 className="text-3xl font-black tracking-tight text-slate-900">Créer un compte</h2>
        <p className="mt-2 text-sm text-slate-500 leading-relaxed">
          Dites-nous ce que vous souhaitez faire sur Marché.
        </p>
      </div>

      <div className="space-y-4">
        <button
          type="button"
          onClick={() => onSelect("client")}
          className="w-full text-left p-5 rounded-2xl border border-slate-200 bg-white hover:border-slate-900 hover:shadow-[0_8px_24px_rgba(0,0,0,0.06)] transition-all group flex items-center gap-4"
        >
          <div className="size-12 rounded-xl bg-slate-100 group-hover:bg-[#2c3e50] flex items-center justify-center transition-colors shrink-0">
            <ShoppingBag className="text-slate-500 group-hover:text-white transition-colors" size={20} />
          </div>
          <div className="flex-1">
            <div className="font-bold text-slate-900">Je suis client</div>
            <div className="text-xs text-slate-500 mt-0.5">Je veux acheter des produits</div>
          </div>
          <ArrowRight
            className="text-slate-300 group-hover:text-slate-900 group-hover:translate-x-1 transition-all shrink-0"
            size={18}
          />
        </button>

        <button
          type="button"
          onClick={() => onSelect("vendor")}
          className="w-full text-left p-5 rounded-2xl border border-slate-200 bg-white hover:border-slate-900 hover:shadow-[0_8px_24px_rgba(0,0,0,0.06)] transition-all group flex items-center gap-4"
        >
          <div className="size-12 rounded-xl bg-slate-100 group-hover:bg-[#2c3e50] flex items-center justify-center transition-colors shrink-0">
            <Store className="text-slate-500 group-hover:text-white transition-colors" size={20} />
          </div>
          <div className="flex-1">
            <div className="font-bold text-slate-900">Je suis fournisseur</div>
            <div className="text-xs text-slate-500 mt-0.5">Je veux vendre mes produits</div>
          </div>
          <ArrowRight
            className="text-slate-300 group-hover:text-slate-900 group-hover:translate-x-1 transition-all shrink-0"
            size={18}
          />
        </button>
      </div>

      <p className="text-xs text-slate-500 text-center pt-8 font-medium">
        Déjà un compte ?{" "}
        <Link to="/login" className="text-slate-900 font-bold hover:underline ml-1">
          Se connecter
        </Link>
      </p>
    </div>
  );
};

export default RegisterRoleSelect;