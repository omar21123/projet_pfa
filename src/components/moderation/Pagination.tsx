import React from 'react';

interface PaginationProps {
  currentPage: number;
  lastPage: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
}

export const Pagination: React.FC<PaginationProps> = ({ currentPage, lastPage, totalItems, pageSize, onPageChange }) => {
  if (lastPage <= 1) return null;

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-4 px-2 py-1 text-sm text-slate-500">
      <div>
        Affichage de <span className="font-semibold text-slate-700">{startItem}</span> à{' '}
        <span className="font-semibold text-slate-700">{endItem}</span> sur{' '}
        <span className="font-semibold text-slate-700">{totalItems}</span> produits
      </div>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
          className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 font-medium text-slate-600"
        >
          Précédent
        </button>
        {[...Array(lastPage)].map((_, idx) => {
          const pageNum = idx + 1;
          return (
            <button
              key={pageNum}
              onClick={() => onPageChange(pageNum)}
              className={`px-3 py-1.5 rounded-lg font-semibold border ${
                currentPage === pageNum
                  ? 'bg-indigo-600 border-indigo-600 text-white'
                  : 'border-slate-300 text-slate-600 hover:bg-slate-50'
              }`}
            >
              {pageNum}
            </button>
          );
        })}
        <button
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === lastPage}
          className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 font-medium text-slate-600"
        >
          Suivant
        </button>
      </div>
    </div>
  );
};