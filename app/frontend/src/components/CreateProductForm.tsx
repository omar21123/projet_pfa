// src/components/CreateProductForm.tsx
import React, { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import axiosInstance from "../api/axiosInstances";
import { useConfigAttributes } from "../hooks/useConfigAttributes";
import { productService, type ProductSubmitPayload } from "../api/product_service";

export default function CreateProductForm() {
  const { usePublicAttributes, useOptionsByAttribute } = useConfigAttributes();

  // --- ÉTATS DU FORMULAIRE ---
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState<number>(0);
  const [stock, setStock] = useState<number>(0);
  
  // Relations catalog_id
  const [selectedCategory, setSelectedCategory] = useState<number | null>(null);
  const [selectedBrand, setSelectedBrand] = useState<number | null>(null);
  const [selectedModel, setSelectedModel] = useState<number | null>(null);
  const [selectedTags, setSelectedTags] = useState<number[]>([]);

  // États pour les attributs de configuration dynamiques
  const [currentAttributeId, setCurrentAttributeId] = useState<number | null>(null);
  const [currentOptionId, setCurrentOptionId] = useState<number | null>(null);
  const [chosenConfigurations, setChosenConfigurations] = useState<{ attributeId: number; attributeName: string; optionId: number; optionLabel: string }[]>([]);

  // --- REQUÊTES DES DONNÉES DE SÉLECTION (ROUTES PUBLIQUES UNIQUEMENT) ---
  
  // 1. Catégories (Route Navbar publique)
  const { data: categoriesRes } = useQuery({
    queryKey: ["categories-navbar"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/categories/navbar");
      return res.data;
    }
  });

  // 2. Marques (Route publique sans /admin)
  const { data: brandsRes } = useQuery({
    queryKey: ["brands-public"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/brands");
      return res.data;
    }
  });

  // 3. Modèles (Route publique sans /admin)
  const { data: modelsRes } = useQuery({
    queryKey: ["models-public"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/models");
      return res.data;
    }
  });

  // 4. Tags (Route publique)
  const { data: tagsRes } = useQuery({
    queryKey: ["tags-public"],
    queryFn: async () => {
      const res = await axiosInstance.get("/api/tags");
      return res.data;
    }
  });

  // 5. Attributs système (ex: Couleur, Pointure)
  const { data: attributesRes } = usePublicAttributes({ perPage: 100 });

  // 6. Options liées à l'attribut actuellement sélectionné
  const { data: optionsRes, isLoading: isLoadingOptions } = useOptionsByAttribute(currentAttributeId);

  // --- MUTATION POUR ENVOYER LE PRODUIT ---
  const createProductMutation = useMutation({
    mutationFn: productService.create,
    onSuccess: (response) => {
      alert("Produit créé avec succès !");
      // Réinitialisation du formulaire
      setName("");
      setDescription("");
      setPrice(0);
      setStock(0);
      setChosenConfigurations([]);
    },
    onError: (error: any) => {
      console.error(error);
      alert(error.response?.data?.message || "Une erreur est survenue lors de la création.");
    }
  });

  // --- GESTION DES ATTRIBUTS DYNAMIQUES ---
  const handleAddConfiguration = () => {
    if (!currentAttributeId || !currentOptionId) return;

    const attrObj = attributesRes?.data.find(a => a.id === currentAttributeId);
    const optObj = optionsRes?.data.find(o => o.id === currentOptionId);

    if (attrObj && optObj) {
      // Éviter les doublons d'un même attribut
      if (chosenConfigurations.some(c => c.attributeId === currentAttributeId)) {
        alert("Cet attribut a déjà été configuré pour ce produit.");
        return;
      }

      setChosenConfigurations([
        ...chosenConfigurations,
        {
          attributeId: currentAttributeId,
          attributeName: attrObj.Name,
          optionId: currentOptionId,
          optionLabel: optObj.OptionLabel
        }
      ]);
      
      // Reset la sélection temporaire
      setCurrentOptionId(null);
    }
  };

  const handleRemoveConfiguration = (attrId: number) => {
    setChosenConfigurations(chosenConfigurations.filter(c => c.attributeId !== attrId));
  };

  // --- SOUMISSION GLOBALE ---
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedCategory || !selectedBrand || !selectedModel) {
      alert("Veuillez renseigner la catégorie, la marque et le modèle.");
      return;
    }

    const payload: ProductSubmitPayload = {
      name,
      description,
      price,
      stock,
      category_id: selectedCategory,
      brand_id: selectedBrand,
      product_model_id: selectedModel,
      tag_ids: selectedTags,
      attributes: chosenConfigurations.map(c => ({
        attribute_id: c.attributeId,
        option_id: c.optionId
      }))
    };

    createProductMutation.mutate(payload);
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-4xl mx-auto p-6 bg-white shadow-md rounded-lg space-y-6">
      <h2 className="text-2xl font-bold border-b pb-3 text-gray-800">Ajouter un nouveau produit (Espace Vendeur)</h2>

      {/* Informations de base */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Nom du produit</label>
          <input type="text" required value={name} onChange={(e) => setName(e.target.value)} className="mt-1 w-full p-2 border rounded-md" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Prix (€ / $)</label>
          <input type="number" required min="0" step="0.01" value={price} onChange={(e) => setPrice(Number(e.target.value))} className="mt-1 w-full p-2 border rounded-md" />
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Description</label>
        <textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} className="mt-1 w-full p-2 border rounded-md" />
      </div>

      {/* Relations : Catégories, Marques, Modèles */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Catégorie</label>
          <select required onChange={(e) => setSelectedCategory(Number(e.target.value) || null)} className="mt-1 w-full p-2 border rounded-md">
            <option value="">-- Sélectionner --</option>
            {categoriesRes?.data?.map((cat: any) => (
              <option key={cat.id} value={cat.id}>{cat.Name || cat.name}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Marque</label>
          <select required onChange={(e) => setSelectedBrand(Number(e.target.value) || null)} className="mt-1 w-full p-2 border rounded-md">
            <option value="">-- Sélectionner --</option>
            {brandsRes?.data?.map((brand: any) => (
              <option key={brand.id} value={brand.id}>{brand.Name || brand.name}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Modèle</label>
          <select required onChange={(e) => setSelectedModel(Number(e.target.value) || null)} className="mt-1 w-full p-2 border rounded-md">
            <option value="">-- Sélectionner --</option>
            {modelsRes?.data?.map((model: any) => (
              <option key={model.id} value={model.id}>{model.Name || model.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Section des Caractéristiques / Attributs de Configuration Dynamiques */}
      <div className="p-4 bg-gray-50 border rounded-md space-y-4">
        <h3 className="text-lg font-medium text-gray-800">Configurations & Variantes du Produit</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
          <div>
            <label className="block text-sm font-medium text-gray-700">1. Type d'attribut</label>
            <select 
              value={currentAttributeId || ""} 
              onChange={(e) => {
                setCurrentAttributeId(Number(e.target.value) || null);
                setCurrentOptionId(null);
              }} 
              className="mt-1 w-full p-2 border rounded-md bg-white"
            >
              <option value="">-- Choisir (ex: Couleur) --</option>
              {attributesRes?.data?.map((attr) => (
                <option key={attr.id} value={attr.id}>{attr.Name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">2. Valeur / Option</label>
            <select 
              disabled={!currentAttributeId || isLoadingOptions}
              value={currentOptionId || ""} 
              onChange={(e) => setCurrentOptionId(Number(e.target.value) || null)} 
              className="mt-1 w-full p-2 border rounded-md bg-white disabled:bg-gray-200"
            >
              <option value="">{isLoadingOptions ? "Chargement..." : "-- Choisir (ex: Rouge) --"}</option>
              {optionsRes?.data?.map((opt) => (
                <option key={opt.id} value={opt.id}>{opt.OptionLabel}</option>
              ))}
            </select>
          </div>

          <button 
            type="button" 
            onClick={handleAddConfiguration}
            disabled={!currentAttributeId || !currentOptionId}
            className="w-full p-2 bg-blue-600 text-white rounded-md font-medium hover:bg-blue-700 disabled:bg-gray-300"
          >
            Lier la caractéristique
          </button>
        </div>

        {/* Table des caractéristiques ajoutées au produit en cours */}
        {chosenConfigurations.length > 0 && (
          <div className="mt-4 border rounded-md overflow-hidden bg-white">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-100 text-sm font-medium text-gray-700 border-b">
                  <th className="p-2 pl-4">Attribut</th>
                  <th className="p-2">Valeur retenue</th>
                  <th className="p-2 text-right pr-4">Action</th>
                </tr>
              </thead>
              <tbody className="text-sm divide-y">
                {chosenConfigurations.map((config) => (
                  <tr key={config.attributeId}>
                    <td className="p-2 pl-4 font-medium text-gray-900">{config.attributeName}</td>
                    <td className="p-2 text-gray-600">{config.optionLabel}</td>
                    <td className="p-2 text-right pr-4">
                      <button type="button" onClick={() => handleRemoveConfiguration(config.attributeId)} className="text-red-600 hover:underline">
                        Supprimer
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Bouton final de soumission */}
      <div className="pt-4 border-t flex justify-end">
        <button
          type="submit"
          disabled={createProductMutation.isPending}
          className="px-6 py-3 bg-green-600 text-white font-bold rounded-md shadow hover:bg-green-700 disabled:bg-gray-400 transition-colors"
        >
          {createProductMutation.isPending ? "Création en cours..." : "Enregistrer et Publier le Produit"}
        </button>
      </div>
    </form>
  );
}