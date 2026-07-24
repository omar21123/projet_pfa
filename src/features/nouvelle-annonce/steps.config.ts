// src/features/nouvelle-annonce/steps.config.ts
import { Check, ImagePlus, Info, Layers, Star, Tag as TagIcon } from "lucide-react";

export const STEPS = [
  { id: 1, label: "Informations", icon: Info },
  { id: 2, label: "Médias", icon: ImagePlus },
  { id: 3, label: "Catégories", icon: Layers },
  { id: 4, label: "Attributs", icon: Star },
  { id: 5, label: "Tags & Paiement", icon: TagIcon },
  { id: 6, label: "Récapitulatif", icon: Check },
] as const;
