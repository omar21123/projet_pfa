import React from 'react';
import { ProductListItem } from '../../types/moderation';
import { StatusBadge } from './StatusBadge';

interface ProductsTableProps {
  products: ProductListItem[];
  loading: boolean;
  onViewDetails: (id: number) => void;
  onActionClick: (type: 'validate' | 'refuse', product: ProductListItem) => void;
}

export const ProductsTable: React.FC<ProductsTableProps> = ({ products, loading, onViewDetails, onActionClick }) => {
  if (loading) {
    return (
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm animate-pulse">
        <div className="h-12 bg-slate-100 border-b border-slate-200" />
        {[...Array(5)].map((_, i) => (
          <div key={i} className="p-4 border-b border-slate-100 flex justify-between space-x-4">
            <div className="flex-1 space-y-2 py-1"><div className="h-4 bg-slate-200 rounded w-1/4" /><div className="h-3 bg-slate-200 rounded w-1/6" /></div>
            <div className="h-8 bg-slate-200 rounded w-24 self-center" />
          </div>
        ))}
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
        <p className="text-slate-500 font-medium">Aucun produit ne correspond à ces critères de recherche.</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      {/* Version Ordinateur */}
      <div className="hidden md:block overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50/70 border-b border-slate-200 text-xs font-bold text-slate-500 uppercase tracking-wider">
              <th className="px-6 py-3.5">Produit</th>
              <th className="px-6 py-3.5">Vendeur</th>
              <th className="px-6 py-3.5">Marque / Modèle</th>
              <th className="px-6 py-3.5">Statut</th>
              <th className="px-6 py-3.5">Soumis le</th>
              <th className="px-6 py-3.5 text-center">Tentatives</th>
              <th className="px-6 py-3.5 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm">
            {products.map((product) => {
              const isSoftDeleted = product.deleted_at !== null;
              return (
                <tr
                  key={product.product_id}
                  className={`hover:bg-slate-50/50 transition ${isSoftDeleted ? 'bg-stone-50/70 opacity-60' : ''}`}
                >
                  <td className="px-6 py-4 cursor-pointer" onClick={() => onViewDetails(product.product_id)}>
                    <div className="font-semibold text-slate-800">{product.product_name}</div>
                    <div className="text-xs text-slate-400 mt-0.5">#{product.product_id}</div>
                  </td>
                  <td className="px-6 py-4 text-slate-600">{product.full_name}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {product.brand_logo ? (
                        <img src={product.brand_logo} alt={product.brand_name || ''} className="w-6 h-6 rounded-full object-cover border" />
                      ) : (
                        <div className="w-6 h-6 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold text-slate-400">
                          {product.brand_name?.charAt(0) || '—'}
                        </div>
                      )}
                      <span className="text-slate-700 font-medium">{product.brand_name || '—'}</span>
                      <span className="text-slate-400 text-xs">/ {product.model_name || '—'}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <StatusBadge status={product.status} isActive={product.is_active} isBlocked={product.is_blocked} deletedAt={product.deleted_at} />
                  </td>
                  <td className="px-6 py-4 text-slate-500 text-xs" title={new Date(product.created_at).toLocaleString()}>
                    {new Date(product.created_at).toLocaleDateString('fr-FR')}
                  </td>
                  <td className="px-6 py-4 text-center">
                    {(product.refuse_attempt || 0) > 0 ? (
                      <span className="inline-flex px-2 py-0.5 text-xs font-bold rounded bg-amber-50 border border-amber-200 text-amber-700">
                        {product.refuse_attempt}/4
                      </span>
                    ) : '—'}
                  </td>
                  <td className="px-6 py-4 text-right space-x-1.5 whitespace-nowrap">
                    <button
                      onClick={() => onViewDetails(product.product_id)}
                      className="inline-flex p-1.5 bg-slate-50 hover:bg-slate-100 text-slate-600 rounded-lg transition border"
                      title="Voir les détails"
                    >
                      👁️
                    </button>
                    {!isSoftDeleted && product.status === 'Brouillon' && (
                      <>
                        <button
                          onClick={() => onActionClick('validate', product)}
                          className="inline-flex p-1.5 bg-green-50 hover:bg-green-100 text-green-600 rounded-lg transition border border-green-200"
                          title="Valider"
                        >
                          ✔️
                        </button>
                        <button
                          onClick={() => onActionClick('refuse', product)}
                          className="inline-flex p-1.5 bg-amber-50 hover:bg-amber-100 text-amber-600 rounded-lg transition border border-amber-200"
                          title="Refuser"
                        >
                          ❌
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Version Mobile (Cartes Empilées) */}
      <div className="md:hidden divide-y divide-slate-100">
        {products.map((product) => (
          <div key={product.product_id} className={`p-4 ${product.deleted_at ? 'bg-stone-50 opacity-60' : ''}`}>
            <div className="flex justify-between items-start mb-2">
              <div onClick={() => onViewDetails(product.product_id)}>
                <h4 className="font-bold text-slate-800">{product.product_name}</h4>
                <p className="text-xs text-slate-400">ID: #{product.product_id} • Vendeur: {product.full_name}</p>
              </div>
              <StatusBadge status={product.status} isActive={product.is_active} isBlocked={product.is_blocked} deletedAt={product.deleted_at} />
            </div>
            <div className="text-xs text-slate-500 space-y-1 mb-3">
              <div>Marque: <span className="font-medium text-slate-700">{product.brand_name || '—'}</span></div>
              <div>Soumis le: {new Date(product.created_at).toLocaleDateString('fr-FR')}</div>
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => onViewDetails(product.product_id)} className="px-3 py-1.5 bg-slate-100 text-slate-700 text-xs font-semibold rounded-lg">
                Détails
              </button>
              {product.status === 'Brouillon' && !product.deleted_at && (
                <>
                  <button onClick={() => onActionClick('validate', product)} className="px-3 py-1.5 bg-green-600 text-white text-xs font-semibold rounded-lg">
                    Valider
                  </button>
                  <button onClick={() => onActionClick('refuse', product)} className="px-3 py-1.5 bg-amber-500 text-white text-xs font-semibold rounded-lg">
                    Refuser
                  </button>
                </>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};