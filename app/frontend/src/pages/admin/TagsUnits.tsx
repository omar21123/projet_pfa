import React, { useState } from "react";
import { useTagsUnits } from "@/hooks/useTagsUnits";
import { Plus, Tag as TagIcon, Scale, EyeOff, X, Edit2 } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function TagsUnits() {
  const [activeTab, setActiveTab] = useState<"tags" | "units">("tags");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");

  // Modales
  const [tagModal, setTagModal] = useState(false);
  const [unitModal, setUnitModal] = useState<{ open: boolean; data: any | null }>({ open: false, data: null });

  // Form States
  const [tagForm, setTagForm] = useState({ Name: "", Color: "#124E54", Description: "" });
  const [unitForm, setUnitForm] = useState({ Name: "", Symbol: "", DisplayOrder: "" });

  const { useTagsList, useUnitsList, createTag, disableTag, createUnit, updateUnit, toggleUnitStatus } = useTagsUnits();

  const apiFilters = {
    search,
    isActive: statusFilter === "" ? undefined : statusFilter === "true"
  };

  const { data: tagsData, isLoading: loadingTags } = useTagsList(apiFilters);
  const { data: unitsData, isLoading: loadingUnits } = useUnitsList(apiFilters);

  // Submit Tag
  const handleTagSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await createTag.mutateAsync({
      Name: tagForm.Name,
      Color: tagForm.Color,
      Description: tagForm.Description || undefined
    });
    setTagModal(false);
    setTagForm({ Name: "", Color: "#124E54", Description: "" });
  };

  // Submit Unité (Créer ou Mettre à jour)
  const handleUnitSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      Name: unitForm.Name,
      Symbol: unitForm.Symbol,
      DisplayOrder: unitForm.DisplayOrder ? Number(unitForm.DisplayOrder) : null
    };

    if (unitModal.data) {
      await updateUnit.mutateAsync({ id: unitModal.data.UnitID, payload });
    } else {
      await createUnit.mutateAsync(payload);
    }
    setUnitModal({ open: false, data: null });
    setUnitForm({ Name: "", Symbol: "", DisplayOrder: "" });
  };

  return (
    <div className="space-y-6 p-6">
      {/* Header & Sélecteurs */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-4 rounded-2xl shadow-sm border border-slate-100">
        <div className="flex bg-slate-100 p-1 rounded-xl w-fit">
          <button
            onClick={() => { setActiveTab("tags"); setStatusFilter(""); }}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium text-sm transition-all ${
              activeTab === "tags" ? "bg-white text-[#124E54] shadow-sm" : "text-slate-600"
            }`}
          >
            <TagIcon className="w-4 h-4" /> Tags
          </button>
          <button
            onClick={() => { setActiveTab("units"); setStatusFilter(""); }}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium text-sm transition-all ${
              activeTab === "units" ? "bg-white text-[#124E54] shadow-sm" : "text-slate-600"
            }`}
          >
            <Scale className="w-4 h-4" /> Unités de Mesure
          </button>
        </div>

        <div className="flex flex-wrap gap-3 items-center">
          <input
            type="text"
            placeholder="Filtrer par nom..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:border-[#124E54] w-52"
          />

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-600 outline-none"
          >
            <option value="">Tous les états</option>
            <option value="true">Actifs</option>
            <option value="false">Désactivés</option>
          </select>

          <Button 
            onClick={() => activeTab === "tags" ? setTagModal(true) : setUnitModal({ open: true, data: null })}
            className="bg-[#CCEC53] text-[#124E54] hover:bg-[#b8d646] font-semibold gap-2 rounded-xl"
          >
            <Plus className="w-4 h-4" /> Ajouter
          </Button>
        </div>
      </div>

      {/* Tables d'affichage */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
        {activeTab === "tags" ? (
          loadingTags ? <div className="p-8 text-center text-slate-400">Chargement des tags...</div> : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-medium text-sm">
                  <th className="p-4">Nom du Tag</th>
                  <th className="p-4">Couleur</th>
                  <th className="p-4">Statut</th>
                  <th className="p-4 text-right">Actions administratif</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {tagsData?.data?.map((tag) => (
                  <tr key={tag.TagID} className="hover:bg-slate-50/50">
                    <td className="p-4 font-semibold text-slate-700">{tag.Name}</td>
                    <td className="p-4">
                      <div className="flex items-center gap-2">
                        <span className="inline-block w-5 h-5 rounded-md border shadow-sm" style={{ backgroundColor: tag.Color || '#ccc' }} />
                        <span className="font-mono text-xs text-slate-400">{tag.Color || "#-"}</span>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${tag.IsActive ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-600"}`}>
                        {tag.IsActive ? "Actif" : "Désactivé"}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      {!!tag.IsActive && (
                        <button onClick={() => disableTag.mutate(tag.TagID)} className="text-rose-600 hover:bg-rose-50 p-2 rounded-lg transition-colors" title="Désactiver définitivement">
                          <EyeOff className="w-4 h-4" />
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )
        ) : (
          loadingUnits ? <div className="p-8 text-center text-slate-400">Chargement des unités...</div> : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-slate-600 font-medium text-sm">
                  <th className="p-4">Unité</th>
                  <th className="p-4">Symbole</th>
                  <th className="p-4">Ordre de tri</th>
                  <th className="p-4">État Réactif</th>
                  <th className="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm">
                {unitsData?.data?.map((unit) => (
                  <tr key={unit.UnitID} className="hover:bg-slate-50/50">
                    <td className="p-4 font-medium text-slate-800">{unit.Name}</td>
                    <td className="p-4 font-mono text-xs text-slate-600"><span className="bg-slate-100 px-2 py-1 rounded">{unit.Symbol}</span></td>
                    <td className="p-4 text-slate-500">{unit.DisplayOrder ?? "Non défini"}</td>
                    <td className="p-4">
                      <input
                        type="checkbox"
                        checked={!!unit.IsActive}
                        onChange={(e) => toggleUnitStatus.mutate({ id: unit.UnitID, active: e.target.checked })}
                        className="w-4 h-4 accent-[#124E54] cursor-pointer"
                      />
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => {
                          setUnitModal({ open: true, data: unit });
                          setUnitForm({ Name: unit.Name, Symbol: unit.Symbol, DisplayOrder: String(unit.DisplayOrder || "") });
                        }} 
                        className="text-slate-500 hover:text-[#124E54] p-1.5 hover:bg-slate-100 rounded-lg"
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

      {/* MODALE : CREER TAG */}
      {tagModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-base font-bold text-slate-900">Créer un nouveau Tag</h3>
              <button onClick={() => setTagModal(false)} className="text-slate-400 hover:text-slate-600"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={handleTagSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Intitulé du Tag *</label>
                <input type="text" required value={tagForm.Name} onChange={(e) => setTagForm({...tagForm, Name: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="Promotion, Exclusif..." />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Couleur Hexadécimale</label>
                <div className="flex gap-2">
                  <input type="color" value={tagForm.Color} onChange={(e) => setTagForm({...tagForm, Color: e.target.value})} className="w-10 h-9 p-0 border rounded-lg cursor-pointer" />
                  <input type="text" value={tagForm.Color} onChange={(e) => setTagForm({...tagForm, Color: e.target.value})} className="flex-1 px-3 py-2 border rounded-xl text-sm font-mono" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Description explicative</label>
                <textarea value={tagForm.Description} onChange={(e) => setTagForm({...tagForm, Description: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm h-16 resize-none" />
              </div>
              <div className="flex justify-end gap-2 pt-2 border-t">
                <button type="button" onClick={() => setTagModal(false)} className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-xl">Annuler</button>
                <button type="submit" className="px-4 py-2 text-sm font-semibold bg-[#124E54] text-white rounded-xl">Enregistrer</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODALE : UNITE (Créer / Éditer) */}
      {unitModal.open && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl w-full max-w-md shadow-xl overflow-hidden">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-base font-bold text-slate-900">{unitModal.data ? "Modifier l'unité" : "Ajouter une unité"}</h3>
              <button onClick={() => setUnitModal({ open: false, data: null })} className="text-slate-400 hover:text-slate-600"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={handleUnitSubmit} className="p-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-600 mb-1">Nom Complet *</label>
                <input type="text" required value={unitForm.Name} onChange={(e) => setUnitForm({...unitForm, Name: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="Kilogramme, Centimètre..." />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Symbole *</label>
                  <input type="text" required value={unitForm.Symbol} onChange={(e) => setUnitForm({...unitForm, Symbol: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm font-mono outline-none focus:border-[#124E54]" placeholder="kg, cm, pcs..." />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-600 mb-1">Ordre d'affichage</label>
                  <input type="number" value={unitForm.DisplayOrder} onChange={(e) => setUnitForm({...unitForm, DisplayOrder: e.target.value})} className="w-full px-3 py-2 border rounded-xl text-sm outline-none focus:border-[#124E54]" placeholder="1, 2, 3..." />
                </div>
              </div>
              <div className="flex justify-end gap-2 pt-2 border-t">
                <button type="button" onClick={() => setUnitModal({ open: false, data: null })} className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-xl">Annuler</button>
                <button type="submit" className="px-4 py-2 text-sm font-semibold bg-[#124E54] text-white rounded-xl">Enregistrer</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}