import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ProductDetails, ConfigItem } from '../../types/moderation';
import { moderationApi } from '../../api/moderationApi';
import { StatusBadge } from '../../components/moderation/StatusBadge';
import { ActionModal } from '../../components/moderation/ActionModal';

export const ProductDetailsPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [details, setDetails] = useState<ProductDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  // États Modaux
  const [modalType, setModalType] = useState<'validate' | 'refuse' | 'block'>('validate');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Utilitaire pour formater la date sans risque d'erreur "Invalid Date"
  const formatDate = (dateString?: string | null) => {
    if (!dateString) return '—';
    try {
      // Remplace l'espace par 'T' pour la compatibilité Safari / ISO
      const isoDate = dateString.replace(' ', 'T');
      return new Date(isoDate).toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return dateString;
    }
  };

  // 🎯 Extraction défensive de l'URL d'un média, quel que soit le nom de champ renvoyé par l'API
  // (accepte aussi une simple chaîne si l'API renvoie un tableau de strings)
  const getMediaUrl = (item: any): string | null => {
    if (!item) return null;
    if (typeof item === 'string') return item;
    return (
      item.url ??
      item.Url ??
      item.URL ??
      item.path ??
      item.Path ??
      item.image_url ??
      item.ImageURL ??
      item.video_url ??
      item.VideoURL ??
      item.file_path ??
      item.FilePath ??
      item.src ??
      null
    );
  };

  const fetchDetailData = async () => {
    if (!id || id === 'undefined') {
      setErrorStatus(404);
      setLoading(false);
      return;
    }

    setLoading(true);
    setErrorStatus(null);

    try {
      const res = await moderationApi.getProductDetails(id);
      
      // Adaptation selon la structure exacte du Swagger JSON
      const payload = res?.data || res;
      const rawDetails = payload?.details;

      if (rawDetails) {
        // Fusion de `details` avec `categories`, `configs`, `tags` et `allowed_payments`
        const fullProductData: ProductDetails = {
          ...rawDetails,
          categories: payload.categories || [],
          configs: payload.configs || [],
          tags: payload.tags || [],
          allowed_payments: payload.allowed_payments || [],
          images: payload.images || rawDetails.images || [],
          videos: payload.videos || rawDetails.videos || [],
        };

        setDetails(fullProductData);
      } else {
        setErrorStatus(404);
      }
    } catch (err: any) {
      console.error("❌ Erreur chargement produit :", err);
      setErrorStatus(err.response?.status || 500);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDetailData();
  }, [id]);

  if (loading) {
    return (
      <div className="p-12 text-center text-slate-500 font-semibold animate-pulse">
        Chargement des fiches techniques...
      </div>
    );
  }

  if (errorStatus === 404 || !details) {
    return (
      <div className="p-12 text-center max-w-md mx-auto space-y-4">
        <div className="p-4 bg-red-50 text-red-700 font-bold rounded-xl border border-red-200">
          Produit introuvable (ID: #{id})
        </div>
        <button
          onClick={() => navigate(-1)}
          className="px-4 py-2 bg-[#375260] text-white text-xs font-semibold rounded-lg hover:bg-[#2c424e]"
        >
          ← Revenir au catalogue
        </button>
      </div>
    );
  }

  if (errorStatus) {
    return (
      <div className="p-12 text-center text-rose-600 space-y-3">
        <div>Erreur serveur (#{errorStatus}).</div>
        <button onClick={fetchDetailData} className="underline text-sm font-semibold">
          Réessayer
        </button>
      </div>
    );
  }

  // Regroupement sécurisé des configurations par attribut
  const configsList = details.configs || [];
  const groupedConfigs = configsList.reduce((acc: Record<string, ConfigItem[]>, item) => {
    if (item && item.attribute) {
      if (!acc[item.attribute]) acc[item.attribute] = [];
      acc[item.attribute].push(item);
    }
    return acc;
  }, {});

  const categoriesList = details.categories || [];
  const tagsList = details.tags || [];
  const paymentsList = details.allowed_payments || [];
  const imagesList = (details as any).images || [];
  const videosList = (details as any).videos || [];

  const handleOpenAction = (type: 'validate' | 'refuse' | 'block') => {
    setModalType(type);
    setIsModalOpen(true);
  };

  const handleConfirmAction = async (notes: string) => {
    if (!id) return;
    const numId = parseInt(id, 10);
    if (modalType === 'validate') await moderationApi.validateProduct(numId, notes);
    else if (modalType === 'refuse') await moderationApi.refuseProduct(numId, notes);
    else if (modalType === 'block') await moderationApi.blockProduct(numId, notes);
    fetchDetailData();
  };

  const renderModerationPanel = () => {
    if (details.deleted_at) {
      return (
        <div className="p-4 bg-stone-100 border rounded-xl text-stone-600 text-sm font-medium text-center">
          Ce produit a été définitivement supprimé par le marchand.
        </div>
      );
    }

    switch (details.status) {
      case 'Brouillon':
        return (
          <div className="space-y-3">
            <button
              onClick={() => handleOpenAction('validate')}
              className="w-full py-2.5 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-bold shadow-sm"
            >
              Valider et publier le produit
            </button>
            <button
              onClick={() => handleOpenAction('refuse')}
              className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 text-white rounded-lg text-sm font-bold shadow-sm"
            >
              Refuser la soumission
            </button>
            {(details.refuse_attempt || 0) > 0 && (
              <div className="p-3 bg-amber-50 border rounded-lg text-xs text-amber-800">
                <strong>Historique :</strong> Déjà refusé {details.refuse_attempt} fois précédemment.
              </div>
            )}
          </div>
        );
      case 'Validé':
        return (
          <div className="space-y-4">
            <div className="bg-green-50 border border-green-100 p-3.5 rounded-xl text-xs text-green-800 space-y-1">
              <div><strong>Validateur :</strong> {details.validator_by || '—'}</div>
              <div><strong>Date :</strong> {formatDate(details.validation_date)}</div>
              <div className="italic">"{details.validation_notes || 'Aucune note'}"</div>
            </div>
            <button
              onClick={() => handleOpenAction('block')}
              className="w-full py-2 bg-rose-50 border border-rose-200 hover:bg-rose-100 text-rose-600 rounded-lg text-sm font-bold"
            >
              Bloquer l'annonce publique
            </button>
          </div>
        );
      case 'Refusé':
        return (
          <div className="bg-amber-50 border p-4 rounded-xl text-xs text-amber-800 space-y-1">
            <h4 className="font-bold uppercase text-[10px] tracking-wider mb-1">Détails du dernier refus</h4>
            <div><strong>Par :</strong> {details.refused_by || '—'}</div>
            <div><strong>Le :</strong> {formatDate(details.refuse_at)}</div>
            <div className="p-2 bg-white rounded border mt-1 font-mono">"{details.refuse_notes || '—'}"</div>
          </div>
        );
      case 'Bloqué':
        return (
          <div className="bg-red-50 border border-red-100 p-4 rounded-xl text-xs text-red-800 space-y-2">
            <h4 className="font-bold uppercase text-[10px] tracking-wider">🔒 Blocage Administratif Actif</h4>
            <div><strong>Le :</strong> {formatDate(details.blocked_date)}</div>
            <div className="p-2 bg-white rounded border font-mono">"{details.blocked_notes || '—'}"</div>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-4">
      <button
        onClick={() => navigate(-1)}
        className="text-sm font-semibold text-indigo-600 hover:text-indigo-800 flex items-center gap-1"
      >
        ← Revenir au catalogue de modération
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Colonne Principale */}
        <div className="lg:col-span-2 bg-white border border-slate-200 rounded-xl p-6 shadow-sm space-y-6">
          {/* Entête Produit */}
          <div className="flex flex-wrap justify-between items-start gap-4 pb-4 border-b border-slate-100">
            <div>
              <h2 className="text-2xl font-bold text-slate-800">{details.product_name || 'Produit sans nom'}</h2>
              <p className="text-xs text-slate-400 font-mono mt-0.5">ID produit : #{details.product_id}</p>
            </div>
            <StatusBadge
              status={details.status}
              isActive={details.is_active}
              isBlocked={details.is_blocked}
              deletedAt={details.deleted_at}
            />
          </div>

          {/* Grille d'Informations Clés */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 text-sm bg-slate-50/80 p-4 rounded-xl border border-slate-100">
            <div>
              <span className="block text-xs text-slate-400 font-medium">Vendeur</span>
              <strong className="text-slate-700">{details.full_name || '—'}</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Marque / Modèle</span>
              <strong className="text-slate-700">
                {details.brand_name || '—'} {details.model_name ? `/ ${details.model_name}` : ''}
              </strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Code-barres</span>
              <strong className="font-mono text-xs">{details.barcode || '—'}</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Stock disponible</span>
              <strong className="text-slate-700">{details.stock ?? 0} unités</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Date de soumission</span>
              <strong className="text-slate-700">{formatDate(details.created_at)}</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Tentatives de refus</span>
              <strong className="text-amber-700">{details.refuse_attempt || 0} / 4</strong>
            </div>
          </div>

          {/* 🎯 Section Médias (Photos / Vidéos) — c'est ce qui manquait dans le rendu */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">
              Médias ({imagesList.length + videosList.length})
            </h4>
            {imagesList.length > 0 || videosList.length > 0 ? (
              <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-5 gap-3">
                {imagesList.map((img: any, i: number) => {
                  const url = getMediaUrl(img);
                  if (!url) return null;
                  return (
                    <div
                      key={`img-${i}`}
                      className="aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-50"
                    >
                      <img src={url} alt={`Photo ${i + 1}`} className="w-full h-full object-cover" />
                    </div>
                  );
                })}
                {videosList.map((vid: any, i: number) => {
                  const url = getMediaUrl(vid);
                  if (!url) return null;
                  return (
                    <div
                      key={`vid-${i}`}
                      className="relative aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-900"
                    >
                      <video src={url} controls className="w-full h-full object-cover" />
                      <span className="absolute top-1 left-1 bg-black/70 text-white text-[10px] px-1.5 py-0.5 rounded">
                        Vidéo
                      </span>
                    </div>
                  );
                })}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucun média fourni pour ce produit.</p>
            )}
          </div>

          {/* Section Catégories */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Catégories assignées</h4>
            {categoriesList.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {categoriesList.map((cat, i) => (
                  <span
                    key={i}
                    className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-medium border ${
                      cat.is_primary
                        ? 'bg-indigo-50 border-indigo-200 text-indigo-700 font-semibold'
                        : 'bg-slate-50 border-slate-200 text-slate-600'
                    }`}
                  >
                    {cat.is_primary && '⭐ Primordial :'} {cat.name}
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucune catégorie rattachée à ce produit.</p>
            )}
          </div>

          {/* Spécifications Techniques (Configs) */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-3">Spécifications techniques</h4>
            {Object.keys(groupedConfigs).length > 0 ? (
              <div className="space-y-3 bg-slate-50/50 p-4 rounded-xl border">
                {Object.entries(groupedConfigs).map(([attr, options]) => (
                  <div key={attr} className="flex flex-col sm:flex-row sm:items-center gap-2 border-b border-slate-200/60 pb-2 last:border-none last:pb-0">
                    <span className="w-36 text-xs font-bold text-slate-600">{attr} :</span>
                    <div className="flex flex-wrap gap-1.5">
                      {options.map((opt, i) => (
                        <span
                          key={i}
                          className={`px-2.5 py-1 rounded-md text-xs border ${
                            opt.is_default
                              ? 'bg-slate-800 text-white font-bold border-slate-800'
                              : 'bg-white text-slate-600 border-slate-200'
                          }`}
                        >
                          {opt.option} {opt.is_default && '📌 (Par défaut)'}
                        </span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucune spécification technique configurée pour le moment.</p>
            )}
          </div>

          {/* Tags et Moyens de Paiement */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 border-t pt-4">
            <div>
              <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Tags / Étiquettes</h4>
              {tagsList.length > 0 ? (
                <div className="flex flex-wrap gap-1">
                  {tagsList.map((tag: any, i: number) => (
                    <span key={i} className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded text-xs">
                      #{tag.name || tag}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">Aucun tag.</p>
              )}
            </div>

            <div>
              <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Moyens de paiement autorisés</h4>
              {paymentsList.length > 0 ? (
                <div className="flex flex-wrap gap-1">
                  {paymentsList.map((pm: any, i: number) => (
                    <span key={i} className="px-2 py-0.5 bg-green-50 text-green-700 border border-green-200 rounded text-xs font-medium">
                      💳 {pm.name || pm}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">Configuration par défaut du site.</p>
              )}
            </div>
          </div>
        </div>

        {/* Panneau Latéral de Décision */}
        <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4 lg:sticky lg:top-4">
          <h3 className="text-xs font-bold uppercase text-slate-400 tracking-wider border-b pb-2">
            Panneau d'action modérateur
          </h3>
          {renderModerationPanel()}
        </div>
      </div>

      <ActionModal
        isOpen={isModalOpen}
        type={modalType}
        product={details}
        onClose={() => setIsModalOpen(false)}
        onConfirm={handleConfirmAction}
      />
    </div>
  );
};

export default ProductDetailsPage;