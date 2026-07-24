import React, { useState, useEffect } from 'react';
import { FilterParams } from '../../types/moderation';

interface FilterBarProps {
  filters: FilterParams;
  onFilterChange: (newFilters: Partial<FilterParams>) => void;
  onClearFilters: () => void;
}

export const ProductsFilterBar: React.FC<FilterBarProps> = ({ filters, onFilterChange, onClearFilters }) => {
  const [searchTerm, setSearchTerm] = useState(filters.search);

  useEffect(() => {
    const delayDebounce = setTimeout(() => {
      if (searchTerm !== filters.search) {
        onFilterChange({ search: searchTerm });
      }
    }, 400);
    return () => clearTimeout(delayDebounce);
  }, [searchTerm]);

  useEffect(() => {
    setSearchTerm(filters.search);
  }, [filters.search]);

  const hasActiveFilters = Object.entries(filters).some(([key, val]) => {
    if (key === 'page' || key === 'per_page') return false;
    return val !== '' && val !== 'any' && val !== 0;
  });

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-5 mb-6">
      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {/* Recherche */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Rechercher</label>
          <input
            type="text"
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            placeholder="Nom du produit..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        {/* Statut */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Statut</label>
          <select
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={filters.status}
            onChange={(e) => onFilterChange({ status: e.target.value })}
          >
            <option value="any">Tous les statuts</option>
            <option value="1">Brouillon</option>
            <option value="2">Validé</option>
            <option value="3">Refusé</option>
            <option value="4">Bloqué</option>
          </select>
        </div>

        {/* Activité */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Visibilité</label>
          <select
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={filters.is_active}
            onChange={(e) => onFilterChange({ is_active: e.target.value })}
          >
            <option value="any">Tous</option>
            <option value="true">Actifs uniquement</option>
            <option value="false">Inactifs uniquement</option>
          </select>
        </div>

        {/* Blocage Étranger */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Blocage Administratif</label>
          <select
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={filters.is_blocked}
            onChange={(e) => onFilterChange({ is_blocked: e.target.value })}
          >
            <option value="any">Tous</option>
            <option value="true">Bloqués</option>
            <option value="false">Non bloqués</option>
          </select>
        </div>

        {/* Date de début */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Soumis depuis le</label>
          <input
            type="date"
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={filters.date_from}
            onChange={(e) => onFilterChange({ date_from: e.target.value })}
          />
        </div>

        {/* Date de fin */}
        <div>
          <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">Jusqu'au</label>
          <input
            type="date"
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={filters.date_to}
            min={filters.date_from}
            onChange={(e) => onFilterChange({ date_to: e.target.value })}
          />
        </div>

        {/* Bouton d'effacement */}
        <div className="flex items-end">
          {hasActiveFilters && (
            <button
              onClick={onClearFilters}
              className="w-full px-4 py-2 border border-rose-200 text-rose-600 bg-rose-50 hover:bg-rose-100 rounded-lg text-sm font-medium transition duration-150"
            >
              Réinitialiser les filtres
            </button>
          )}
        </div>
      </div>

      {/* Ligne d'étiquettes de puces d'annulation actives */}
      {hasActiveFilters && (
        <div className="flex flex-wrap gap-2 mt-4 pt-3 border-t border-slate-100 text-sm">
          <span className="text-slate-500 self-center text-xs font-medium">Filtres actifs :</span>
          {filters.search && (
            <span className="inline-flex items-center gap-1 bg-slate-100 px-2.5 py-1 rounded-md text-xs text-slate-700">
              Texte: "{filters.search}"
              <button onClick={() => { setSearchTerm(''); onFilterChange({ search: '' }); }} className="font-bold hover:text-rose-600 ml-1">✕</button>
            </span>
          )}
          {filters.status !== 'any' && (
            <span className="inline-flex items-center gap-1 bg-slate-100 px-2.5 py-1 rounded-md text-xs text-slate-700">
              Statut actif
              <button onClick={() => onFilterChange({ status: 'any' })} className="font-bold hover:text-rose-600 ml-1">✕</button>
            </span>
          )}
        </div>
      )}
    </div>
  );
};