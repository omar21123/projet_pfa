import React, { useState } from "react";
import { useBrandsModels } from "@/hooks/useBrandsModels";
import { Layers, ShieldCheck, CheckCircle2, XCircle, Plus, Edit2, X } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function BrandsModels() {
  const [activeTab, setActiveTab] = useState<"brands" | "models">("brands");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>(""); // "" = Tous, "true" = Actif, "false" = Inactif

  // Gestion des Modales
  const [brandModal, setBrandModal] = useState<{ open: boolean; data: any | null }>({ open: false, data: null });
  const [modelModal, setModelModal] = useState<{ open: boolean; data: any | null }>({ open: false, data: null });

  // Form States Locaux
  const [brandForm, setBrandForm] = useState({ Name: "", Website: "", Description: "" });
  const [brandLogo, setBrandLogo] = useState<File | null>(null);
  const [modelForm, setModelForm] = useState({ BrandID: "", Name: "", Code: "", Description: "", ReleaseYear: "" });

  const { 
    useBrandsList, 
    useModelsList, 
    createBrand, 
    toggleBrandStatus, 
    createModel, 
    updateModel, 
    toggleModelStatus 
  } = useBrandsModels();

  // Préparation des filtres d'API
  const apiFilters = {
    search,
    isActive: statusFilter === "" ? undefined : statusFilter === "true"
  };

  const { data: brandsData, isLoading: loadingBrands } = useBrandsList(apiFilters);
  const { data: modelsData, isLoading: loadingModels } = useModelsList(apiFilters);

  // Soumission Marque (FormData requis pour fichier binaire)
  const handleBrandSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const formData = new FormData();
    formData.append("Name", brandForm.Name);
    formData.append("Website", brandForm.Website);
    formData.append("Description", brandForm.Description);
    if (brandLogo) {
      formData.append("LogoURL", brandLogo);
    }
    await createBrand.mutateAsync(formData);
    setBrandModal({ open: false, data: null });
    setBrandForm({ Name: "", Website: "", Description: "" });
    setBrandLogo(null);
  };

  // Soumission Modèle (Ajout ou Modification)
  const handleModelSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      BrandID: Number(modelForm.BrandID),
      Name: modelForm.Name,
      Code: modelForm.Code || null,
      Description: modelForm.Description || null,
      ReleaseYear: modelForm.ReleaseYear ? Number(modelForm.ReleaseYear) : null,
    };

    if (modelModal.data) {
      await updateModel.mutateAsync({ id: modelModal.data.ModelID, payload });
    } else {
      await createModel.mutateAsync(payload);
    }
    setModelModal({ open: false, data: null });
    setModelForm({ BrandID: "", Name: "", Code: "", Description: "", ReleaseYear: "" });
  };

  return (
    <div className="space-y-6 p-6">
      {/* Top Header Controls */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div className="flex bg-slate-100 p-1 rounded-xl w-fit">
          <button
            onClick={() => { setActiveTab("brands"); setStatusFilter(""); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeTab === "brands" ? "bg-white text-[#124E54] shadow-sm" : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <ShieldCheck className="w-4 h-4" /> Marques
          </button>
          <button
            onClick={() => { setActiveTab("models"); setStatusFilter(""); }}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeTab === "models" ? "bg-white text-[#124E54] shadow-sm" : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <Layers className="w-4 h-4" /> Modèles de Produits
          </button>
        </div>

        {/* Section Filtres et Actions */}
        <div className="flex flex-wrap gap-3 items-center">
          <input
            type="text"
            placeholder={`Rechercher un ${activeTab === "brands" ? "constructeur" : "modèle"}...`}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm w-64 focus:ring-1 focus:ring-[#124E54] outline-none"
          />

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-600 outline-none"
          >
            <option value="">Tous les statuts</option>
            <option value="true">Actifs / En Ligne</option>
            <option value="false">Désactivés</option>
          </select>

          <Button 
            onClick={() => activeTab === "brands" 
              ? setBrandModal({ open: true, data: null }) 
              : setModelModal({ open: true, data: null })
            }
            className="bg-[#CCEC53] text-[#124E54] hover:bg-[#b8d646] font-semibold gap-2 rounded-xl"
          >
            <Plus className="w-4 h-4" /> Ajouter
          </Button>
        </div>
      </div>

      {/* Main Container Tables */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        {activeTab === "brands" ? (
          loadingBrands ? <div className="p-12 text-center text-slate-400">Chargement des marques...</div> : (
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-50 text-slate-500 font-medium text-xs tracking-wider uppercase border-b">
                  <th className="p-4">Logo</th>
                  <th className="p-4">Nom de la Marque</th>
                  <th className="p-4">Site Web</th>
                  <th className="p-4">Visibilité administrative</th>
                </tr>
              </thead>
              <tbody className="divide-y text-sm text-slate-700">
                {brandsData?.data?.map((brand) => (
                  <tr key={brand.BrandID} className="hover:bg-slate-50/50">
                    <td className="p-4">
                      {brand.LogoURL ? (
                        <img src={brand.LogoURL} alt={brand.Name} className="w-10 h-10 rounded-lg object-contain bg-slate-50 border" />
                      ) : (
                        <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center text-slate-400 font-bold text-xs">NO LOGO</div>
                      )}
                    </td>
                    <td className="p-4 font-semibold text-slate-900">{brand.Name}</td>
                    <td className="p-4 text-slate-500">{brand.Website || "-"}</td>
                    <td className="p-4">
                      <button
                        onClick={() => toggleBrandStatus.mutate({ id: brand.BrandID, active: !brand.IsActive })}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition-colors ${
                          brand.IsActive ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-100" : "bg-rose-50 text-rose-700 hover:bg-rose-100"
                        }`}
                      >
                        {brand.IsActive ? <CheckCircle2 className="w-3.5 h-3.5" /> : <XCircle className="w-3.5 h-3.5" />}
                        {brand.IsActive ? "En Ligne" : "Désactivé"}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )
        ) : (
          loadingModels ? <div className="p-12 text-center text-slate-400">Chargement des modèles...</div> : (
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-50 text-slate-500 font-medium text-xs tracking-wider uppercase border-b">
                  <th className="p-4">ID</th>
                  <th className="p-4">Nom du Modèle</th>
                  <th className="p-4">Code / SKU</th>
                  <th className="p-4">Année</th>
                  <th className="p-4">Statut</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y text-sm">
                {modelsData?.data?.map((model) => (
                  <tr key={model.ModelID} className="hover:bg-slate-50/50 text-slate-700">
                    <td className="p-4 text-slate-400 font-mono text-xs">#{model.ModelID}</td>
                    <td className="p-4 font-medium text-slate-900">{model.Name}</td>
                    <td className="p-4 font-mono text-xs text-slate-500">{model.Code || "-"}</td>
                    <td className="p-4 text-slate-600">{model.ReleaseYear || "-"}</td>
                    <td className="p-4">
                      <input
                        type="checkbox"
                        checked={!!model.IsActive}
                        onChange={(e) => toggleModelStatus.mutate({ id: model.ModelID, active: e.target.checked })}
                        className="w-4 h-4 accent-[#124E54] rounded cursor-pointer"
                      />
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => {
                          setModelModal({ open: true, data: model });
                          setModelForm({
                            BrandID: String(model.BrandID),
                            Name: model.Name,
                            Code: model.Code || "",
                            Description: model.Description || "",
                            ReleaseYear: model.ReleaseYear ? String(model.ReleaseYear) : ""
                          });
                        }} 
                        className="text-slate-500 hover:text-[#124E54] p-1.5 hover:bg-slate-100 rounded-lg transition-colors"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )
        )}
      </div>

      {/* MODALE : MARQUES (Ajout uniquement car géré par flux d'images) */}
      {brandModal.open && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl overflow-hidden animate-in fade-in-50 duration-200">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-base font-bold text-slate-900">Ajouter une nouvelle marque</h3>
              <button onClick={() => setBrandModal({ open: false, data: null })} className="text-slate-400 hover:text-slate-600"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={handleBrandSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Nom du constructeur *</label>
                <input type="text" required value={brandForm.Name} onChange={(e) => setBrandForm({...brandForm, Name: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="Ex: Apple, Sony..." />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Site Web</label>
                <input type="url" value={brandForm.Website} onChange={(e) => setBrandForm({...brandForm, Website: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="https://example.com" />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Description</label>
                <textarea value={brandForm.Description} onChange={(e) => setBrandForm({...brandForm, Description: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54] h-20 resize-none" placeholder="Notes sur la marque..." />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Fichier Logo (Optionnel)</label>
                <input type="file" accept="image/*" onChange={(e) => setBrandLogo(e.target.files?.[0] || null)} className="w-full text-xs text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200" />
              </div>
              <div className="flex justify-end gap-2 pt-2 border-t">
                <button type="button" onClick={() => setBrandModal({ open: false, data: null })} className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-xl">Annuler</button>
                <button type="submit" className="px-4 py-2 text-sm font-semibold bg-[#124E54] text-white rounded-xl hover:bg-[#0d3b3f]">Enregistrer</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODALE : MODÈLES (Ajout & Édition) */}
      {modelModal.open && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-base font-bold text-slate-900">{modelModal.data ? "Modifier le modèle" : "Créer un nouveau modèle"}</h3>
              <button onClick={() => setModelModal({ open: false, data: null })} className="text-slate-400 hover:text-slate-600"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={handleModelSubmit} className="p-4 space-y-4">
              {!modelModal.data && (
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">ID de la Marque Rattacée *</label>
                  <input type="number" required value={modelForm.BrandID} onChange={(e) => setModelForm({...modelForm, BrandID: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="ID numérique de la marque" />
                </div>
              )}
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Nom du modèle *</label>
                <input type="text" required value={modelForm.Name} onChange={(e) => setModelForm({...modelForm, Name: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="Ex: Galaxy S24, iPhone 15..." />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Code / SKU</label>
                  <input type="text" value={modelForm.Code} onChange={(e) => setModelForm({...modelForm, Code: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="SM-S921B" />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Année de Sortie</label>
                  <input type="number" value={modelForm.ReleaseYear} onChange={(e) => setModelForm({...modelForm, ReleaseYear: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="2026" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Description courte</label>
                <textarea value={modelForm.Description} onChange={(e) => setModelForm({...modelForm, Description: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54] h-16 resize-none" />
              </div>
              <div className="flex justify-end gap-2 pt-2 border-t">
                <button type="button" onClick={() => setModelModal({ open: false, data: null })} className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-xl">Annuler</button>
                <button type="submit" className="px-4 py-2 text-sm font-semibold bg-[#124E54] text-white rounded-xl hover:bg-[#0d3b3f]">Enregistrer</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}