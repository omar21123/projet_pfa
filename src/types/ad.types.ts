import type { UserProfile } from "@/types/user.types";

export interface Ad {
  id: string;
  title: string;
  description: string;
  price: number;
  category: string;
  images: string[];
  userId: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateAdDto {
  title: string;
  description: string;
  price: number;
  category: string;
  images: File[];
}

export enum AdStatus {
  DRAFT = "draft",
  PENDING_VALIDATION = "pending_validation",
  PUBLISHED = "published",
  SUSPENDED = "suspended",
  SOLD = "sold",
  ARCHIVED = "archived",
  tous = "all",
}

export interface AnnonceDto {
  id: number;
  idutilisateur: number;
  titre: string;
  prix: number;
  description: string;
  categorie: string;
  sousCategorie?: string;
  ville: string;
  etat?: string;
  statut: AdStatus;

  photosUrls: string[];

  brand?: string;
  size?: string;
  color?: string;

  // JSON sérialise les dates en string — toujours typer en string côté client
  datepublication: string;
  isFollowed?: boolean; // Indique si l'annonce est suivie par l'utilisateur connecté
  numberoffavorites?: number; // Nombre de fois que l'annonce a été ajoutée aux favoris
  vendeur?: UserProfile | null;
}
