import React from 'react';
import { VendorProductFilters } from '@/types/prodcut';

interface Props {
  filters: VendorProductFilters;
  onFilterChange: (filters: Partial<VendorProductFilters>) => void;
}

export const MyAdsFilterBar: React.FC<Props> = ({ filters, onFilterChange }) => {
  return (
    <div className="flex flex-wrap gap-4 mb-6 items-center justify-between bg-white p-4 rounded-lg shadow-sm">
      {/* Recherche par Nom ou Code-barres */}
      <div className="flex-1 min-w-[240px]">
        <input
          type="text"
          placeholder="Rechercher par nom ou code-barres..."
          value={filters.search || ''}
          onChange={(e) => onFilterChange({ search: e.target.value })}
          className="w-full px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Filtre par Statut */}
      <div>
        <select
          value={filters.status ?? ''}
          onChange={(e) =>
            onFilterChange({
              status: e.target.value !== '' ? Number(e.target.value) : undefined,
            })
          }
          className="px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Tous les statuts</option>
          <option value="1">En attente</option>
          <option value="2">Validé</option>
          <option value="3">Refusé</option>
        </select>
      </div>

      {/* Filtre par État Actif */}
      <div>
        <select
          value={filters.is_active === undefined ? '' : filters.is_active ? 'true' : 'false'}
          onChange={(e) =>
            onFilterChange({
              is_active: e.target.value === '' ? undefined : e.target.value === 'true',
            })
          }
          className="px-4 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Tous les états</option>
          <option value="true">Actifs</option>
          <option value="false">Inactifs</option>
        </select>
      </div>
    </div>
  );
};