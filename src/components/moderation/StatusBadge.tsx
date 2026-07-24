import React from 'react';
import { ProductStatusLabel } from '../../types/moderation';

interface StatusBadgeProps {
  status: ProductStatusLabel | string;
  isActive: boolean;
  isBlocked: boolean;
  deletedAt: string | null;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, isActive, isBlocked, deletedAt }) => {
  const getBadgeConfig = (label: string) => {
    switch (label) {
      case 'Brouillon':
        return { bg: 'bg-gray-100', text: 'text-gray-800', border: 'border-gray-200' };
      case 'Validé':
        return { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' };
      case 'Refusé':
        return { bg: 'bg-amber-100', text: 'text-amber-800', border: 'border-amber-200' };
      case 'Bloqué':
        return { bg: 'bg-red-100', text: 'text-red-800', border: 'border-red-200' };
      default:
        return { bg: 'bg-slate-100', text: 'text-slate-800', border: 'border-slate-200' };
    }
  };

  const config = getBadgeConfig(status);

  return (
    <div className="flex flex-wrap gap-1.5 items-center">
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${config.bg} ${config.text} ${config.border}`}>
        {status}
      </span>
      
      {!isActive && (
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-zinc-100 text-zinc-500 border border-zinc-200">
          Inactif
        </span>
      )}
      
      {isBlocked && (
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-rose-100 text-rose-700 border border-rose-200 animate-pulse">
          Bloqué
        </span>
      )}
      
      {deletedAt && (
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-stone-200 text-stone-600 border border-stone-300">
          Supprimé
        </span>
      )}
    </div>
  );
};