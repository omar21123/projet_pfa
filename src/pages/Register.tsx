import { useState } from "react";
import type { ReactNode } from "react";
import AuthLayout from "./Authlayout";
import RegisterRoleSelect, { type UserRole } from "./Registerroleselect";
import RegisterClientForm from "./Registerclientform";
import RegisterVendorForm from "./Registervendorform";

interface PanelContent {
  eyebrow: string;
  title: ReactNode;
  description: string;
  stats: { k: string; v: string }[];
}

// Le panneau gauche s'adapte selon le rôle choisi (ou reste générique avant le choix)
const PANEL_CONTENT: Record<"default" | UserRole, PanelContent> = {
  default: {
    eyebrow: "Rejoindre Marché",
    title: (
      <>
        Créez votre
        <br />
        <span className="text-[#d09a3f]">compte.</span>
      </>
    ),
    description:
      "Que vous achetiez ou que vous vendiez, Marché vous connecte à la marketplace marocaine de confiance.",
    stats: [
      { k: "12k+", v: "produits actifs" },
      { k: "480+", v: "vendeurs vérifiés" },
      { k: "24 / 7", v: "modération" },
    ],
  },
  client: {
    eyebrow: "Espace client",
    title: (
      <>
        Achetez en
        <br />
        <span className="text-[#d09a3f]">toute confiance.</span>
      </>
    ),
    description: "Accédez à des milliers de produits vérifiés, livrés partout au Maroc.",
    stats: [
      { k: "12k+", v: "produits actifs" },
      { k: "48h", v: "livraison moyenne" },
      { k: "4.8/5", v: "satisfaction" },
    ],
  },
  vendor: {
    eyebrow: "Espace fournisseur",
    title: (
      <>
        Vendez sur
        <br />
        <span className="text-[#d09a3f]">Marché.</span>
      </>
    ),
    description:
      "Rejoignez plus de 480 vendeurs vérifiés et développez votre activité sur la marketplace marocaine.",
    stats: [
      { k: "0 Dh", v: "frais d'inscription" },
      { k: "480+", v: "vendeurs actifs" },
      { k: "7j/7", v: "support vendeur" },
    ],
  },
};

/**
 * Page /register.
 * Étape 1 : sélection du rôle (client / fournisseur).
 * Étape 2 : formulaire adapté — léger pour le client, multi-étapes pour le fournisseur
 * (voir RegisterVendorForm pour le détail des sous-étapes).
 *
 * NB: reste en state local plutôt que sous-routes (/register/client, /register/vendor)
 * pour l'instant — à séparer en routes plus tard si besoin de liens profonds/partage d'URL.
 */
const Register = () => {
  const [role, setRole] = useState<UserRole | null>(null);

  const panel = PANEL_CONTENT[role ?? "default"];

  return (
    <AuthLayout
      eyebrow={panel.eyebrow}
      title={panel.title}
      description={panel.description}
      stats={panel.stats}
    >
      {role === null && <RegisterRoleSelect onSelect={setRole} />}
      {role === "client" && <RegisterClientForm onBack={() => setRole(null)} />}
      {role === "vendor" && <RegisterVendorForm onBack={() => setRole(null)} />}
    </AuthLayout>
  );
};

export default Register;
