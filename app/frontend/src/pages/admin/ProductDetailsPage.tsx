import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ProductDetails, ConfigItem } from '../../types/moderation';
import { moderationApi } from '../../api/moderationApi';
import { StatusBadge } from '../../components/moderation/StatusBadge';
import { ActionModal } from '../../components/moderation/ActionModal';
import { getMediaUrl } from '@/utils/mediaUtils';
import { VideoPlayer } from '@/components/VideoPlayer';

export const ProductDetailsPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [details, setDetails] = useState<ProductDetails | null>(null);
  const [combinations, setCombinations] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  // États Modaux d'Action Produit
  const [modalType, setModalType] = useState<'validate' | 'refuse' | 'block'>('validate');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // États Modal Détails Combinaison
  const [selectedCombo, setSelectedCombo] = useState<any | null>(null);
  const [loadingComboDetail, setLoadingComboDetail] = useState(false);
  const [isComboModalOpen, setIsComboModalOpen] = useState(false);

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return '—';
    try {
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

  const extractMediaField = (item: any): string | null => {
    if (!item) return null;
    if (typeof item === 'string') return item;
    return (
      item.url ??
      item.Url ??
      item.path ??
      item.Path ??
      item.image_path ??
      item.image_url ??
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
      // 1. Récupération des détails du produit[cite: 8]
      const res = await moderationApi.getProductDetails(id);
      const payload = res?.data || res;
      const rawDetails = payload?.details || payload;

      if (rawDetails) {
        setDetails({
          ...rawDetails,
          categories: payload.categories || rawDetails.categories || [],
          configs: payload.configs || rawDetails.configs || [],
          tags: payload.tags || rawDetails.tags || [],
          allowed_payments: payload.allowed_payments || rawDetails.allowed_payments || [],
          images: payload.images || rawDetails.images || [],
          videos: payload.videos || rawDetails.videos || [],
        });
      } else {
        setErrorStatus(404);
        setLoading(false);
        return;
      }

      // 2. Récupération des combinaisons via l'endpoint dédié
      try {
        const comboRes = await moderationApi.getProductCombinations(id);
        const comboList = comboRes?.data || (Array.isArray(comboRes) ? comboRes : []);
        setCombinations(comboList);
      } catch (comboErr) {
        console.warn("⚠️ Impossible de charger les combinaisons :", comboErr);
        setCombinations([]);
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

  // Ouverture et chargement du détail d'une combinaison
  const handleOpenComboDetails = async (combinationId: number) => {
    setIsComboModalOpen(true);
    setLoadingComboDetail(true);
    setSelectedCombo(null);

    try {
      const res = await moderationApi.getCombinationDetails(combinationId);
      setSelectedCombo(res?.data || res);
    } catch (err) {
      console.error("❌ Erreur chargement détail combinaison :", err);
    } finally {
      setLoadingComboDetail(false);
    }
  };

  if (loading) {
    return (
      <div className="p-12 text-center text-slate-500 font-semibold animate-pulse">
        Chargement des informations du produit...
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
              <span className="block text-xs text-slate-400 font-medium">Stock Global</span>
              <strong className="text-slate-700">{details.stock ?? 0} unités</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Date de soumission</span>
              <strong className="text-slate-700">{formatDate(details.created_at)}</strong>
            </div>
            <div>
              <span className="block text-xs text-slate-400 font-medium">Prix de base</span>
              <strong className="text-slate-900">{details.base_price ?? "—"} DH</strong>
            </div>
          </div>

          {/* Section Galerie Médias */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">
              Galerie Médias ({imagesList.length + videosList.length})
            </h4>
            {imagesList.length > 0 || videosList.length > 0 ? (
              <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-5 gap-3">
                {imagesList.map((img: any, i: number) => {
                  const url = getMediaUrl(extractMediaField(img));
                  if (!url) return null;
                  return (
                    <div key={`img-${i}`} className="aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-50">
                      <img src={url} alt={`Photo ${i + 1}`} className="w-full h-full object-cover" />
                    </div>
                  );
                })}
                {videosList.map((vid: any, i: number) => {
                  const url = getMediaUrl(extractMediaField(vid));
                  return (
                    <div key={`vid-${i}`} className="relative aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-900">
                      <video src={url} controls className="w-full h-full object-cover" />
                      <span className="absolute top-1 left-1 bg-black/70 text-white text-[10px] px-1.5 py-0.5 rounded">Vidéo</span>
                    </div>
                  );
                })}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucun média principal fourni pour ce produit.</p>
            )}
          </div>

          {/* Section Vidéo Démo */}
          <div className="mt-6 space-y-2">
            <h3 className="text-sm font-bold text-slate-800">Vidéo de démonstration</h3>
            <VideoPlayer src={details?.video_path || details?.video || extractMediaField(videosList?.[0])} />
          </div>

          {/* TABLEAU DES COMBINAISONS / VARIANTES */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-3">
              Combinaisons & Variantes SKU ({combinations.length})
            </h4>
            {combinations.length > 0 ? (
              <div className="overflow-x-auto border border-slate-200 rounded-xl shadow-sm">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-100 text-slate-600 font-bold border-b border-slate-200 uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="p-3">Visuel</th>
                      <th className="p-3">Options</th>
                      <th className="p-3">SKU</th>
                      <th className="p-3">Prix</th>
                      <th className="p-3">Stock</th>
                      <th className="p-3 text-center">Défaut</th>
                      <th className="p-3 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 bg-white">
                    {combinations.map((combo) => {
                      const imgUrl = getMediaUrl(combo.image_path) || getMediaUrl(extractMediaField(combo));
                      return (
                        <tr key={combo.combination_id} className="hover:bg-slate-50/80 transition-colors">
                          <td className="p-3">
                            <div className="size-10 rounded-lg border border-slate-200 bg-slate-50 overflow-hidden flex items-center justify-center">
                              {imgUrl ? (
                                <img src={imgUrl} alt={combo.sku} className="size-full object-cover" />
                              ) : (
                                <span className="text-[10px] text-slate-400 font-medium">—</span>
                              )}
                            </div>
                          </td>
                          <td className="p-3 font-medium text-slate-800">
                            {Array.isArray(combo.options) && combo.options.length > 0 ? (
                              <div className="flex flex-wrap gap-1">
                                {combo.options.map((opt: any, oIdx: number) => (
                                  <span key={oIdx} className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-semibold text-[11px]">
                                    {opt.config_name}: <span className="text-slate-900">{opt.option_name || opt.option_value}</span>
                                  </span>
                                ))}
                              </div>
                            ) : (
                              <span className="text-slate-400 italic">Variante standard</span>
                            )}
                          </td>
                          <td className="p-3 font-mono text-slate-600">{combo.sku}</td>
                          <td className="p-3 font-bold text-slate-800">{combo.price} DH</td>
                          <td className="p-3 font-semibold text-slate-700">{combo.stock} u.</td>
                          <td className="p-3 text-center">
                            {combo.is_default ? (
                              <span className="inline-block px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                                Oui
                              </span>
                            ) : (
                              <span className="text-slate-400 text-[10px]">Non</span>
                            )}
                          </td>
                          <td className="p-3 text-right">
                            <button
                              onClick={() => handleOpenComboDetails(combo.combination_id)}
                              className="px-2.5 py-1.5 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-200 rounded-lg text-xs font-semibold transition-colors"
                            >
                              Voir détails
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">Aucune combinaison/variante enregistrée pour ce produit.</p>
            )}
          </div>

          {/* Section Catégories */}
          <div>
            <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Catégories assignées</h4>
            {categoriesList.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {categoriesList.map((cat: any, i: number) => (
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

        {/* Panneau Latéral de Décision Modérateur */}
        <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4 lg:sticky lg:top-4">
          <h3 className="text-xs font-bold uppercase text-slate-400 tracking-wider border-b pb-2">
            Panneau d'action modérateur
          </h3>
          {renderModerationPanel()}
        </div>
      </div>

      {/* BOÎTE MODALE DE DÉTAILS COMBINAISON (GET /api/products/combinations/{combination}) */}
      {isComboModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex justify-between items-center border-b pb-3">
              <h3 className="text-lg font-bold text-slate-800">
                Détails de la combinaison #{selectedCombo?.combination_id || ''}
              </h3>
              <button
                onClick={() => setIsComboModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 font-bold text-xl leading-none"
              >
                ×
              </button>
            </div>

            {loadingComboDetail ? (
              <div className="py-12 text-center text-slate-500 font-semibold animate-pulse">
                Chargement des détails de la variante...
              </div>
            ) : selectedCombo ? (
              <div className="space-y-4 text-sm">
                <div className="flex items-center gap-4 bg-slate-50 p-3 rounded-xl border">
                  <div className="size-16 rounded-lg border bg-white overflow-hidden flex-shrink-0 flex items-center justify-center">
                    {getMediaUrl(selectedCombo.image_path) ? (
                      <img
                        src={getMediaUrl(selectedCombo.image_path)!}
                        alt={selectedCombo.sku}
                        className="size-full object-cover"
                      />
                    ) : (
                      <span className="text-xs text-slate-400">Sans image</span>
                    )}
                  </div>
                  <div>
                    <h5 className="font-mono font-bold text-slate-800">{selectedCombo.sku}</h5>
                    <div className="flex items-center gap-2 mt-1">
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${selectedCombo.is_active ? 'bg-green-100 text-green-800' : 'bg-rose-100 text-rose-800'}`}>
                        {selectedCombo.is_active ? 'Active' : 'Inactive'}
                      </span>
                      {selectedCombo.is_default && (
                        <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                          Variante par défaut
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3 rounded-xl border border-slate-100 text-xs">
                  <div>
                    <span className="text-slate-400 block">Prix de vente</span>
                    <strong className="text-slate-800 text-sm">{selectedCombo.price} DH</strong>
                  </div>
                  <div>
                    <span className="text-slate-400 block">Prix barré (compare_at)</span>
                    <strong className="text-slate-500 line-through">
                      {selectedCombo.compare_at_price ? `${selectedCombo.compare_at_price} DH` : '—'}
                    </strong>
                  </div>
                  <div>
                    <span className="text-slate-400 block">Stock disponible</span>
                    <strong className="text-slate-800">{selectedCombo.stock} unités</strong>
                  </div>
                  <div>
                    <span className="text-slate-400 block">ID Produit parent</span>
                    <strong className="font-mono text-slate-800">#{selectedCombo.product_id}</strong>
                  </div>
                </div>

                <div>
                  <h4 className="text-xs font-bold uppercase text-slate-400 tracking-wider mb-2">Options associées</h4>
                  {Array.isArray(selectedCombo.options) && selectedCombo.options.length > 0 ? (
                    <div className="space-y-1.5">
                      {selectedCombo.options.map((opt: any, i: number) => (
                        <div key={i} className="flex justify-between items-center bg-slate-100 p-2 rounded text-xs">
                          <span className="font-semibold text-slate-600">{opt.config_name}</span>
                          <span className="font-bold text-slate-800">{opt.option_name || opt.option_value}</span>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 italic">Aucune option configurée.</p>
                  )}
                </div>

                <div className="text-[11px] text-slate-400 border-t pt-2 flex justify-between">
                  <span>Créé le : {formatDate(selectedCombo.created_at)}</span>
                  <span>Modifié le : {formatDate(selectedCombo.updated_at)}</span>
                </div>
              </div>
            ) : (
              <div className="py-6 text-center text-red-600">
                Impossible de charger les détails de cette combinaison.
              </div>
            )}

            <div className="pt-2">
              <button
                onClick={() => setIsComboModalOpen(false)}
                className="w-full py-2 bg-slate-800 text-white font-semibold rounded-lg text-xs hover:bg-slate-700"
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal d'action modérateur (Valider / Refuser / Bloquer) */}
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