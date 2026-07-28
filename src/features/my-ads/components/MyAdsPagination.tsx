import React from 'react';
import { PaginatedMeta } from '@/types/prodcut';

interface Props {
  meta: PaginatedMeta;
  onPageChange: (page: number) => void;
}

export const MyAdsPagination: React.FC<Props> = ({ meta, onPageChange }) => {
  if (meta.last_page <= 1 || meta.total === 0) return null;

  const from = ((meta.page - 1) * meta.page_size) + 1;

  return (
    <div className="flex items-center justify-between bg-white px-4 py-3 rounded-lg shadow-sm mt-4">
      <div className="text-sm text-gray-700">
        Affichage de <span className="font-medium">{from}</span> à{' '}
        <span className="font-medium">{Math.min(meta.page * meta.page_size, meta.total)}</span> sur{' '}
        <span className="font-medium">{meta.total}</span> annonces
      </div>

      <div className="flex gap-2">
        <button
          disabled={meta.page === 1}
          onClick={() => onPageChange(meta.page - 1)}
          className="px-3 py-1 border rounded text-sm disabled:opacity-50 hover:bg-gray-50"
        >
          Précédent
        </button>
        <span className="px-3 py-1 text-sm font-medium">
          {meta.page} / {meta.last_page}
        </span>
        <button
          disabled={meta.page === meta.last_page}
          onClick={() => onPageChange(meta.page + 1)}
          className="px-3 py-1 border rounded text-sm disabled:opacity-50 hover:bg-gray-50"
        >
          Suivant
        </button>
      </div>
    </div>
  );
};