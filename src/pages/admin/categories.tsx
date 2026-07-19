import React, { useState } from "react";
import { 
  Plus, 
  ChevronRight, 
  ChevronDown, 
  Search, 
  SlidersHorizontal, 
  Edit3, 
  Trash2, 
  X, 
  Upload, 
  Loader2 
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useQueryClient } from "@tanstack/react-query";

// Importations de tes hooks et client API
import { useCategories, CategoryNode, categoriesQueryKeys } from "@/hooks/useCategories";
import { apiClient } from "@/api/client";

export default function Categories() {
  const queryClient = useQueryClient();
  
  // Récupération des catégories racines via React Query
  const { data: rootCategories = [], isLoading, isError, refetch } = useCategories();

  // Stockage local des sous-catégories chargées dynamiquement et état d'ouverture
  const [childrenMap, setChildrenMap] = useState<Record<number, CategoryNode[]>>({});
  const [expandedRows, setExpandedRows] = useState<Record<number, boolean>>({});

  // Filtres de recherche et tri
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState("Name");
  const [sortDir, setSortDir] = useState("asc");

  // Modal de création
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newCatName, setNewCatName] = useState("");
  const [selectedParent, setSelectedParent] = useState<CategoryNode | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  // --- GETTERS SÉCURISÉS ---
  // Modification cruciale : on vérifie d'abord "ID" (majuscule d'après ta BDD)
  const getCatID = (cat: CategoryNode): number => {
    const id = cat.ID ?? cat.id ?? cat.CategoryID ?? 0;
    return Number(id);
  };

  const getCatName = (cat: CategoryNode): string => {
    return cat.Name ?? cat.name ?? cat.nom ?? "Sans nom";
  };

  const getCatSlug = (cat: CategoryNode): string => {
    return cat.Slug ?? cat.slug ?? "";
  };

  // Détection ultra-robuste de l'état d'activation (gère string, number, boolean et toutes les casses)
  const getCatActive = (cat: CategoryNode): boolean => {
    const value = cat.IsActive ?? cat.is_active ?? cat.isActive;

    if (value === undefined || value === null) return false;
    
    // Si c'est un booléen (true/false)
    if (typeof value === "boolean") return value;
    
    // Si c'est un nombre (1 ou 0)
    if (typeof value === "number") return value === 1;
    
    // Si c'est du texte ("1", "0", "true", "false")
    if (typeof value === "string") {
      return value === "1" || value.toLowerCase() === "true";
    }
    
    return false;
  };

  const getInitials = (name: string): string => {
    if (!name || name.length === 0) return "CA";
    const cleanName = name.trim();
    if (cleanName.length === 1) return cleanName.toUpperCase();
    return cleanName.substring(0, 2).toUpperCase();
  };

  // --- LOGIQUE DE DÉROULEMENT DES SOUS-CATÉGORIES ---
  const handleToggleRow = async (category: CategoryNode) => {
    const catId = getCatID(category);
    if (!catId) {
      console.error("Impossible de déplier : ID introuvable pour la catégorie", category);
      return;
    }

    const isExpanded = !!expandedRows[catId];
    setExpandedRows(prev => ({ ...prev, [catId]: !isExpanded }));

    // Si on ouvre et qu'on n'a pas encore chargé ses enfants
    if (!isExpanded && !childrenMap[catId]) {
      try {
        const response = await apiClient.get<{ success: boolean; data: CategoryNode[] }>(
          `/api/categories/${catId}/children`
        );
        if (response.data && response.data.success && Array.isArray(response.data.data)) {
          setChildrenMap(prev => ({ ...prev, [catId]: response.data.data }));
        } else {
          setChildrenMap(prev => ({ ...prev, [catId]: [] }));
        }
      } catch (err) {
        console.error("Erreur lors de la récupération des enfants :", err);
        setChildrenMap(prev => ({ ...prev, [catId]: [] }));
      }
    }
  };

  // --- MISE À JOUR OPTIMISTE DU STATUT ---
  const handleToggleStatus = async (category: CategoryNode) => {
    const catId = getCatID(category);
    const isActive = getCatActive(category);
    
    if (!catId || catId === 0) {
      console.error("Erreur : Impossible de modifier le statut car l'ID extrait est 0 ou indéfini.", category);
      alert("Erreur locale : l'identifiant de cette catégorie n'a pas pu être lu.");
      return;
    }

    console.log(`[Statut] Clic détecté sur ID: ${catId}. Statut actuel dans l'UI: ${isActive ? 'Actif' : 'Inactif'}`);

    // 1. Calculer tous les IDs enfants pour les mettre à jour immédiatement à l'écran (UI réactive)
    const getDescendantIds = (parentId: number): number[] => {
      const ids: number[] = [];
      const queue = [parentId];
      while (queue.length > 0) {
        const currentId = queue.shift()!;
        const children = childrenMap[currentId] || [];
        children.forEach(child => {
          const childId = getCatID(child);
          if (childId) {
            ids.push(childId);
            queue.push(childId);
          }
        });
      }
      return ids;
    };

    const affectedIds = new Set([catId, ...getDescendantIds(catId)]);
    const nextStatus = !isActive;
    const nextStatusValue = nextStatus ? 1 : 0;

    // Sauvegarde de secours en cas d'erreur API (Rollback)
    const previousRootCategories = queryClient.getQueryData<CategoryNode[]>(categoriesQueryKeys.roots()) || [];
    const previousChildrenMap = { ...childrenMap };

    // Fonction de mise à jour instantanée en local
    const updateNodesStatus = (nodes: CategoryNode[]): CategoryNode[] => {
      return nodes.map(node => {
        const id = getCatID(node);
        let updatedNode = { ...node };
        
        if (affectedIds.has(id)) {
          updatedNode = { 
            ...updatedNode, 
            IsActive: nextStatusValue,
            is_active: nextStatusValue,
            isActive: nextStatus
          };
        }
        
        if (updatedNode.children && updatedNode.children.length > 0) {
          updatedNode.children = updateNodesStatus(updatedNode.children);
        }
        return updatedNode;
      });
    };

    // Appliquer le changement immédiatement dans l'UI (Optimistic Update)
    queryClient.setQueryData(categoriesQueryKeys.roots(), (oldData: CategoryNode[] | undefined) => {
      if (!oldData) return [];
      return updateNodesStatus(oldData);
    });

    setChildrenMap(prev => {
      const updated = { ...prev };
      for (const parentId in updated) {
        updated[parentId] = updateNodesStatus(updated[parentId]);
      }
      return updated;
    });

    // 2. Appel de ton API Laravel
    try {
      if (isActive) {
        const url = `/api/categories/${catId}/deactivate-subtree`;
        console.log(`[API Call] PUT ${url}`);
        await apiClient.put(url);
      } else {
        const url = `/api/categories/${catId}/activate`;
        console.log(`[API Call] PUT ${url}`);
        await apiClient.put(url);
      }
      
      console.log(`[API Success] Statut mis à jour avec succès sur le serveur pour l'ID: ${catId}`);
      // Rechargement silencieux pour synchroniser
      refetch();
    } catch (err: any) {
      console.error("[API Error] La requête de changement de statut a échoué :", err);
      
      // Rollback immédiat de l'UI
      queryClient.setQueryData(categoriesQueryKeys.roots(), previousRootCategories);
      setChildrenMap(previousChildrenMap);
      
      // Affichage d'un message d'erreur amical
      const statusText = err.response?.status ? `(Code ${err.response.status})` : "";
      alert(`Impossible d'enregistrer le statut sur le serveur ${statusText}. Vos modifications locales ont été annulées.`);
    }
  };

  // --- LOGIQUE DE CRÉATION DE CATÉGORIE ---
  const handleCreateCategorySubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCatName.trim()) return;

    setIsCreating(true);
    setErrorMsg("");

    try {
      const formData = new FormData();
      formData.append("Name", newCatName);

      if (selectedParent) {
        const parentId = getCatID(selectedParent);
        formData.append("ParentCategoryID", String(parentId));
      }
      if (selectedFile) {
        formData.append("IconURL", selectedFile);
      }

      const response = await apiClient.post<{ success: boolean }>("/api/categories/create", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      });

      if (response.data?.success) {
        setIsModalOpen(false);
        setNewCatName("");
        setSelectedFile(null);
        setPreviewUrl(null);
        setSelectedParent(null);
        
        await queryClient.invalidateQueries({ queryKey: categoriesQueryKeys.all });
        setChildrenMap({});
        setExpandedRows({});
        refetch();
      }
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || "Une erreur est survenue.");
    } finally {
      setIsCreating(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const openCreateModal = (parent: CategoryNode | null = null) => {
    setSelectedParent(parent);
    setIsModalOpen(true);
  };

  // --- RENDU EN ARBORESCENCE RÉCURSIVE ---
  const renderCategoryRow = (cat: CategoryNode, depth = 0) => {
    const catId = getCatID(cat);
    if (!catId) return null;

    const isExpanded = !!expandedRows[catId];
    const children = childrenMap[catId] || [];
    
    const canBeExpanded = (cat.children_count !== undefined && cat.children_count > 0) || 
                          children.length > 0 || 
                          depth === 0;

    const catName = getCatName(cat);
    const isActive = getCatActive(cat);

    return (
      <React.Fragment key={catId}>
        <tr className="hover:bg-slate-50/40 border-b border-slate-100 transition-colors">
          
          {/* NOM & INDENTATION */}
          <td className="py-4 px-6">
            <div 
              className="flex items-center gap-3" 
              style={{ paddingLeft: `${depth * 2}rem` }}
            >
              {depth > 0 && (
                <span className="text-slate-300 font-mono text-xs shrink-0 select-none mr-1">
                  ↳
                </span>
              )}

              {canBeExpanded ? (
                <button 
                  type="button"
                  onClick={() => handleToggleRow(cat)}
                  className="p-1 hover:bg-slate-100 rounded text-slate-500 transition-colors shrink-0"
                >
                  {isExpanded ? (
                    <ChevronDown className="w-4 h-4 text-slate-600" />
                  ) : (
                    <ChevronRight className="w-4 h-4 text-slate-600" />
                  )}
                </button>
              ) : (
                <span className="w-6 h-6 shrink-0" />
              )}

              {cat.IconURL ? (
                <img 
                  src={cat.IconURL} 
                  alt={catName} 
                  className="w-10 h-10 rounded-lg object-cover border border-slate-200/60 bg-white"
                />
              ) : (
                <div className="w-10 h-10 bg-blue-50/50 border border-blue-100/80 text-blue-600 font-bold rounded-lg flex items-center justify-center text-xs uppercase shrink-0">
                  {getInitials(catName)}
                </div>
              )}

              <div className="flex flex-col">
                <span className="font-semibold text-slate-800 text-sm leading-tight">
                  {catName}
                </span>
                <span className="text-xs text-slate-400 font-medium mt-0.5">
                  /{getCatSlug(cat)}
                </span>
              </div>
            </div>
          </td>

          {/* SOUS-CATÉGORIES */}
          <td className="py-4 px-6 text-center text-slate-600 font-medium text-sm">
            {cat.children_count ?? children.length}
          </td>

          {/* PRODUITS */}
          <td className="py-4 px-6 text-center text-slate-600 font-medium text-sm">
            0 / 120
          </td>

          {/* STATUT */}
          <td className="py-4 px-6">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => handleToggleStatus(cat)}
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                  isActive ? 'bg-[#124E54]' : 'bg-slate-200'
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    isActive ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
              <span className={`inline-flex items-center px-3 py-0.5 rounded-full text-[11px] font-bold transition-all duration-150 ${
                isActive 
                  ? "bg-slate-900 text-white" 
                  : "bg-slate-100 text-slate-600"
              }`}>
                {isActive ? "Active" : "Inactive"}
              </span>
            </div>
          </td>

          {/* ACTIONS */}
          <td className="py-4 px-6 text-right">
            <div className="flex items-center justify-end gap-3 text-slate-400">
              <button 
                type="button"
                onClick={() => openCreateModal(cat)}
                className="p-1 hover:text-slate-700 hover:bg-slate-100 rounded transition-colors"
                title="Ajouter une sous-catégorie"
              >
                <Plus className="w-4 h-4 text-slate-600" />
              </button>
              <button 
                type="button"
                className="p-1 hover:text-slate-700 hover:bg-slate-100 rounded transition-colors"
                title="Modifier"
              >
                <Edit3 className="w-4 h-4 text-slate-600" />
              </button>
              <button 
                type="button"
                onClick={() => handleToggleStatus(cat)}
                className="p-1 hover:text-rose-600 hover:bg-rose-50 rounded transition-colors"
                title="Changer statut"
              >
                <Trash2 className="w-4 h-4 text-rose-500" />
              </button>
            </div>
          </td>
        </tr>
        
        {isExpanded && Array.isArray(children) && children.map(child => renderCategoryRow(child, depth + 1))}
      </React.Fragment>
    );
  };

  return (
    <div className="space-y-6">
      
      {/* HEADER */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-800">Catégories du Catalogue</h1>
          <p className="text-slate-500 text-sm">Gérez et organisez l'arborescence des rayons de votre plateforme.</p>
        </div>
        <Button
          onClick={() => openCreateModal(null)}
          className="bg-[#124E54] hover:bg-[#0D3B40] text-[#CCEC53] font-bold rounded-xl h-10 px-4"
        >
          <Plus className="w-4 h-4 mr-2" /> Nouvelle Catégorie
        </Button>
      </div>

      {/* RECHERCHE ET TRIS */}
      <div className="flex flex-col md:flex-row items-center gap-3 justify-between">
        <div className="relative w-full md:flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input
            type="text"
            placeholder="Rechercher par nom ou slug..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 pr-4 py-2 w-full h-10 border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-[#124E54] bg-white text-sm"
          />
        </div>
        
        <div className="flex items-center gap-2 w-full md:w-auto shrink-0">
          <Button variant="outline" className="rounded-xl border-slate-200 gap-2 text-slate-700 h-10 bg-white">
            <SlidersHorizontal className="w-4 h-4 text-slate-500" />
            Filtres
          </Button>

          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="px-3 h-10 border border-slate-200 rounded-xl text-sm text-slate-700 bg-white focus:outline-none focus:ring-1 focus:ring-[#124E54]"
          >
            <option value="Name">Ordre d'affichage</option>
            <option value="CreatedAt">Date de création</option>
          </select>

          <select
            value={sortDir}
            onChange={(e) => setSortDir(e.target.value)}
            className="px-3 h-10 border border-slate-200 rounded-xl text-sm text-slate-700 bg-white focus:outline-none focus:ring-1 focus:ring-[#124E54]"
          >
            <option value="asc">Croissant</option>
            <option value="desc">Décroissant</option>
          </select>
        </div>
      </div>

      {/* TABLE DES CATÉGORIES */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-24 gap-3">
            <Loader2 className="w-8 h-8 text-[#124E54] animate-spin" />
            <p className="text-sm text-slate-400">Chargement de l'arborescence...</p>
          </div>
        ) : isError ? (
          <div className="text-center py-24">
            <p className="text-sm font-semibold text-rose-500">Erreur lors de la récupération des catégories</p>
            <Button onClick={() => refetch()} className="mt-4 bg-slate-800 text-white rounded-xl">Réessayer</Button>
          </div>
        ) : rootCategories.length === 0 ? (
          <div className="text-center py-24">
            <p className="text-sm font-semibold text-slate-500">Aucune catégorie principale configurée</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50/50 border-b border-slate-200 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                  <th className="py-4 px-6 w-2/5">Nom</th>
                  <th className="py-4 px-6 text-center">Sous-catégories</th>
                  <th className="py-4 px-6 text-center">Produits</th>
                  <th className="py-4 px-6">Statut</th>
                  <th className="py-4 px-6 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {rootCategories.map(rootCat => renderCategoryRow(rootCat, 0))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* MODAL DE CRÉATION */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <h3 className="font-bold text-slate-800 text-lg">
                {selectedParent ? "Créer une sous-catégorie" : "Créer une catégorie"}
              </h3>
              <button 
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="p-1 hover:bg-slate-100 rounded-lg text-slate-400"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateCategorySubmit} className="p-6 space-y-4">
              {errorMsg && (
                <div className="p-3 bg-rose-50 text-rose-600 text-xs font-semibold rounded-xl border border-rose-100">
                  {errorMsg}
                </div>
              )}

              {selectedParent && (
                <div className="p-3 bg-emerald-50 border border-emerald-100 rounded-xl text-xs text-emerald-800">
                  Création d'une sous-catégorie dans : <strong>{getCatName(selectedParent)}</strong>
                </div>
              )}

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-slate-600 uppercase">Nom de la catégorie *</label>
                <Input
                  required
                  value={newCatName}
                  onChange={(e) => setNewCatName(e.target.value)}
                  placeholder="Ex: Céramique, Mode, Électroménager..."
                  className="rounded-xl font-medium"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-slate-600 uppercase">Image d'illustration (Icône)</label>
                <div className="flex items-center gap-4">
                  {previewUrl ? (
                    <div className="relative w-16 h-16 shrink-0 rounded-xl overflow-hidden border border-slate-200 bg-slate-50">
                      <img src={previewUrl} alt="Aperçu" className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedFile(null);
                          setPreviewUrl(null);
                        }}
                        className="absolute top-0.5 right-0.5 bg-rose-500 text-white rounded-full p-0.5 hover:bg-rose-600"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  ) : (
                    <label className="w-16 h-16 shrink-0 rounded-xl border-2 border-dashed border-slate-200 hover:border-slate-300 flex flex-col items-center justify-center cursor-pointer text-slate-400 hover:text-[#124E54] hover:bg-slate-50/50 transition-all">
                      <Upload className="w-5 h-5" />
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleFileChange}
                        className="hidden"
                      />
                    </label>
                  )}
                  <div className="text-[11px] text-slate-400 leading-normal">
                    Fichiers PNG, JPG ou WEBP acceptés. Limite : 2 Mo.
                  </div>
                </div>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <Button
                  type="button"
                  variant="ghost"
                  onClick={() => setIsModalOpen(false)}
                  className="rounded-xl font-semibold"
                >
                  Annuler
                </Button>
                <Button
                  type="submit"
                  disabled={isCreating}
                  className="bg-[#124E54] hover:bg-[#0D3B40] text-[#CCEC53] font-bold rounded-xl px-5"
                >
                  {isCreating ? "Création..." : "Créer"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}