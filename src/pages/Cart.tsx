import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Loader2, 
  Trash2, 
  ShoppingBag, 
  ArrowRight, 
  ChevronLeft, 
  Minus, 
  Plus, 
  ShieldCheck,
  Truck
} from "lucide-react";

// Imports essentiels
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { getMediaUrl } from "@/utils/mediaUtils"; // Import de l'utilitaire

import { useCart } from "@/features/cart/hooks/useCart";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/hooks/use-toast";

export const Cart = () => {
  const { cartItems, totalPrice, loading, removeFromCart, totalItems } = useCart();
  const [removingKey, setRemovingKey] = useState<string | null>(null);
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleRemove = async (item: any) => {
    const key = `${item.id}-${item.compositionId || "default"}`;
    setRemovingKey(key);
    try {
      await removeFromCart({ productID: Number(item.id), CompositionID: item.compositionId });
    } catch (err: any) {
      toast({
        title: "Erreur",
        description: "Impossible de retirer l'article.",
        variant: "destructive",
      });
    } finally {
      setRemovingKey(null);
    }
  };

  return (
    <div className="min-h-screen bg-white dark:bg-slate-950 flex flex-col">
      <Navbar />

      <main className="flex-1 container max-w-7xl mx-auto px-4 py-8">
        {loading ? (
          <div className="flex flex-col justify-center items-center min-h-[60vh] gap-6">
            <Loader2 className="w-12 h-12 animate-spin text-primary" />
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Chargement...</p>
          </div>
        ) : !cartItems || cartItems.length === 0 ? (
          <div className="py-20 text-center">
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-slate-50 dark:bg-slate-900/50 rounded-[3rem] py-20 border-2 border-dashed border-slate-200 dark:border-slate-800"
            >
              <ShoppingBag className="w-16 h-16 text-slate-300 mx-auto mb-6" />
              <h2 className="text-4xl font-black uppercase italic tracking-tighter mb-4">Panier Vide</h2>
              <Button asChild className="rounded-full px-10 h-14 font-black uppercase tracking-widest">
                <Link to="/">Découvrir les produits</Link>
              </Button>
            </motion.div>
          </div>
        ) : (
          <>
            {/* Bouton Retour */}
            <div className="mb-12">
              <button
                onClick={() => navigate(-1)}
                className="group flex items-center gap-2 p-2 hover:bg-slate-100 dark:hover:bg-slate-900 rounded-full transition-all"
              >
                <ChevronLeft className="h-5 w-5 group-hover:-translate-x-1 transition-transform" />
                <span className="text-xs font-black uppercase tracking-widest px-2">Retour</span>
              </button>
            </div>

            <div className="flex items-baseline gap-4 mb-10">
              <h1 className="text-5xl md:text-7xl font-black tracking-tighter italic uppercase">Panier</h1>
              <span className="text-primary font-black text-2xl">({totalItems})</span>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-12 gap-12">
              {/* Liste Produits */}
              <div className="lg:col-span-8">
                <div className="space-y-6">
                  <AnimatePresence mode="popLayout">
                    {cartItems.map((item, index) => (
                      <CartItemCard 
                        key={`${item.id}-${item.compositionId || index}`} 
                        item={item} 
                        isRemoving={removingKey === `${item.id}-${item.compositionId || "default"}`}
                        onRemove={() => handleRemove(item)}
                        index={index}
                      />
                    ))}
                  </AnimatePresence>
                </div>
              </div>

              {/* Sidebar Résumé */}
              <div className="lg:col-span-4">
                <div className="sticky top-28 bg-slate-900 rounded-[2.5rem] p-8 text-white shadow-2xl relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-full blur-[50px] -mr-16 -mt-16" />
                  <h2 className="text-xl font-black uppercase italic tracking-tight mb-8">Résumé</h2>
                  
                  <div className="space-y-4">
                    <div className="flex justify-between text-slate-400">
                      <span className="uppercase text-xs font-bold tracking-widest">Sous-total</span>
                      <span className="text-white font-black">{totalPrice.toLocaleString()} DH</span>
                    </div>
                    <div className="flex justify-between text-slate-400">
                      <span className="uppercase text-xs font-bold tracking-widest">Livraison</span>
                      <span className="text-green-400 font-black uppercase">Gratuit</span>
                    </div>
                    <Separator className="bg-slate-700 my-6" />
                    <div className="flex justify-between items-end mb-10">
                      <span className="text-xs font-black uppercase text-primary">Total</span>
                      <p className="text-4xl font-black tracking-tighter italic">{totalPrice.toLocaleString()} DH</p>
                    </div>
                    <Button
                      onClick={() => navigate("/checkout")}
                      className="w-full h-16 rounded-2xl bg-primary hover:bg-primary/90 text-white font-black text-lg uppercase tracking-widest shadow-xl shadow-primary/20"
                    >
                      Payer <ArrowRight className="ml-2 h-5 w-5" />
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}
      </main>
      <Footer />
    </div>
  );
};

// --- COMPOSANT CARTE AVEC FIX IMAGE ---
const CartItemCard = ({ item, isRemoving, onRemove, index }: any) => {
  /**
   * FIX IMAGE : On vérifie toutes les propriétés possibles
   * car le panier renvoie parfois 'image' et parfois 'productImage'
   */
  const imageSource = item.image || item.productImage || item.thumbnail || "";
  const imageUrl = getMediaUrl(imageSource);

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ delay: index * 0.05 }}
      className="group flex flex-col sm:flex-row gap-6 p-6 bg-white dark:bg-slate-900/50 rounded-[2rem] border border-slate-100 dark:border-slate-800 hover:shadow-xl transition-all"
    >
      {/* Image avec fallback au cas où */}
      <div className="relative h-32 w-32 sm:h-40 sm:w-40 shrink-0 overflow-hidden rounded-2xl bg-slate-100 dark:bg-slate-800">
        {imageSource ? (
          <img
            src={imageUrl}
            alt={item.title}
            className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
          />
        ) : (
          <div className="h-full w-full flex items-center justify-center">
             <ShoppingBag className="h-8 w-8 text-slate-300" />
          </div>
        )}
      </div>

      <div className="flex flex-col justify-between flex-1">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="text-xl font-black uppercase italic tracking-tighter leading-none mb-1">
              {item.title}
            </h3>
            <p className="text-xs font-bold text-primary uppercase tracking-widest">{item.seller}</p>
          </div>
          <button
            onClick={onRemove}
            className="h-10 w-10 flex items-center justify-center rounded-full bg-slate-50 dark:bg-slate-800 text-slate-400 hover:text-red-500 transition-colors"
          >
            {isRemoving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
          </button>
        </div>

        <div className="flex justify-between items-center mt-6">
          <div className="flex items-center gap-4 bg-slate-50 dark:bg-slate-800 rounded-full p-1 border">
            <button className="h-8 w-8 flex items-center justify-center rounded-full hover:bg-white dark:hover:bg-slate-700"><Minus className="h-3 w-3" /></button>
            <span className="text-sm font-black">{item.quantity}</span>
            <button className="h-8 w-8 flex items-center justify-center rounded-full hover:bg-white dark:hover:bg-slate-700"><Plus className="h-3 w-3" /></button>
          </div>
          <div className="text-right">
            <p className="text-2xl font-black tracking-tighter">{(item.price * item.quantity).toLocaleString()} DH</p>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default Cart;