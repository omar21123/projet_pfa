import React, { useState, useEffect } from 'react';
import { ProductListItem } from '../../types/moderation';

interface ActionModalProps {
  isOpen: boolean;
  type: 'validate' | 'refuse' | 'block';
  product: ProductListItem | null;
  onClose: () => void;
  onConfirm: (notes: string) => Promise<void>;
}

export const ActionModal: React.FC<ActionModalProps> = ({ isOpen, type, product, onClose, onConfirm }) => {
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorBanner, setErrorBanner] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setNotes('');
      setErrorBanner(null);
      setLoading(false);
    }
  }, [isOpen]);

  if (!isOpen || !product) return null;

  const isRequired = type === 'refuse' || type === 'block';
  const maxChars = 1000;

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (isRequired && !notes.trim()) return;
    
    setLoading(true);
    setErrorBanner(null);
    try {
      await onConfirm(notes);
      onClose();
    } catch (err: any) {
      setErrorBanner(err.response?.data?.message || 'Une erreur système est survenue. Veuillez réessayer.');
    } finally {
      setLoading(false);
    }
  };

  const getConfig = () => {
    switch (type) {
      case 'validate':
        return { title: 'Validation du produit', label: 'Notes de validation (optionnel)', btnClass: 'bg-green-600 hover:bg-green-700', textBtn: 'Valider le produit' };
      case 'refuse':
        return { title: 'Refus du produit', label: 'Motif du refus (requis)', btnClass: 'bg-amber-500 hover:bg-amber-600', textBtn: 'Refuser le produit' };
      case 'block':
        return { title: '❗ Blocage Définitif de l\'Annonce', label: 'Motif du blocage (requis)', btnClass: 'bg-red-600 hover:bg-red-700 ring-2 ring-red-300', textBtn: 'Confirmer le blocage immédiat' };
    }
  };

  const ui = getConfig();
  const priorAttempts = product.refuse_attempt || 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
      <div className="bg-white rounded-xl shadow-xl border w-full max-w-lg overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
          <h3 className="text-lg font-bold text-slate-800">{ui.title}</h3>
          <button onClick={onClose} disabled={loading} className="text-slate-400 hover:text-slate-600 font-bold">✕</button>
        </div>

        <form onSubmit={handleFormSubmit} className="p-6 space-y-4">
          {errorBanner && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-lg text-rose-700 text-sm font-medium">
              {errorBanner}
            </div>
          )}

          <p className="text-sm text-slate-600">
            Vous vous apprêtez à modifier le statut de <span className="font-semibold text-slate-800">{product.product_name}</span> (#{product.product_id}).
          </p>

          {/* Alertes contextuelles préventives */}
          {type === 'refuse' && priorAttempts >= 3 && (
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-amber-800 text-xs font-semibold flex gap-2">
              ⚠️ Attention : Ce produit a déjà été refusé {priorAttempts} fois. Ce nouveau refus le basculera en blocage automatique.
            </div>
          )}

          {type === 'block' && (
            <div className="p-3 bg-red-50 border border-red-100 rounded-lg text-red-700 text-xs font-medium">
              CETTE ACTION EST STRICTEMENT FINALE : Le produit sera immédiatement retiré de la vente publique.
            </div>
          )}

          <div>
            <label className="block text-xs font-bold text-slate-600 uppercase mb-1">{ui.label}</label>
            <textarea
              className="w-full h-32 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              maxLength={maxChars}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Saisissez vos observations ici..."
              disabled={loading}
            />
            <div className="text-right text-xs text-slate-400 mt-1 font-mono">
              {notes.length} / {maxChars} caractères
            </div>
          </div>

          <div className="flex justify-end gap-2.5 pt-2 border-t border-slate-100">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm font-medium hover:bg-slate-50 disabled:opacity-50"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={loading || (isRequired && !notes.trim())}
              className={`px-4 py-2 text-white rounded-lg text-sm font-semibold shadow-sm transition disabled:opacity-40 ${ui.btnClass}`}
            >
              {loading ? 'Traitement en cours...' : ui.textBtn}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};