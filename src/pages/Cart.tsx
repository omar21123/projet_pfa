import { motion } from "framer-motion";
import { Trash2, Plus, Minus, ShoppingCart } from "lucide-react";
import { useCart } from "@/hooks/useCart";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { useLanguage } from "@/contexts/LanguageContext";

export default function Cart() {
  const { t } = useLanguage();
  const { cartItems, totalPrice, removeFromCart, updateQuantity, checkout } = useCart();

  if (cartItems.length === 0) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 pt-20 px-4"
      >
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col items-center justify-center min-h-[60vh]">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2 }}
              className="bg-white rounded-xl shadow-lg p-12 text-center"
            >
              <ShoppingCart className="w-16 h-16 mx-auto text-slate-300 mb-4" />
              <h1 className="text-3xl font-bold text-slate-900 mb-2">{t("your_cart_empty")}</h1>
              <p className="text-slate-600 mb-6">{t("explore_ads")}</p>
              <Link to="/">
                <Button className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600">
                  {t("continue_shopping")}
                </Button>
              </Link>
            </motion.div>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 pt-20 px-4 pb-12"
    >
      <div className="max-w-6xl mx-auto">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="mb-8"
        >
          <h1 className="text-4xl font-bold text-slate-900 mb-2">{t("my_cart")}</h1>
          <p className="text-slate-600">
            {cartItems.length} {t("items_in_cart")}
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <motion.div
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.2 }}
              className="space-y-4"
            >
              {cartItems.map((item, index) => (
                <motion.div
                  key={item.id}
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.1 * (index + 1) }}
                  className="bg-white rounded-lg shadow p-4 hover:shadow-md transition-shadow"
                >
                  <div className="flex gap-4">
                    <div className="flex-shrink-0 w-20 h-20 bg-slate-200 rounded-lg overflow-hidden">
                      {item.image ? (
                        <img
                          src={item.image}
                          alt={item.title}
                          loading="lazy"
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full bg-gradient-to-br from-slate-300 to-slate-400 flex items-center justify-center">
                          <ShoppingCart className="w-8 h-8 text-slate-600" />
                        </div>
                      )}
                    </div>
                    <div className="flex-grow">
                      <h3 className="font-semibold text-slate-900">{item.title}</h3>
                      <p className="text-sm text-slate-600">
                        {t("seller")}: {item.seller}
                      </p>
                      <p className="text-lg font-bold text-orange-600 mt-1">
                        {item.price.toFixed(2)}€
                      </p>
                    </div>
                    <div className="flex items-center gap-2 border border-slate-300 rounded-lg p-2">
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity - 1)}
                        className="p-1 hover:bg-slate-100 rounded transition-colors"
                      >
                        <Minus className="w-4 h-4 text-slate-600" />
                      </button>
                      <span className="w-8 text-center font-semibold text-slate-900">
                        {item.quantity}
                      </span>
                      <button
                        onClick={() => updateQuantity(item.id, item.quantity + 1)}
                        className="p-1 hover:bg-slate-100 rounded transition-colors"
                      >
                        <Plus className="w-4 h-4 text-slate-600" />
                      </button>
                    </div>
                    <div className="flex flex-col items-end justify-center min-w-24">
                      <p className="text-sm text-slate-600">{t("subtotal")}</p>
                      <p className="text-lg font-bold text-slate-900">
                        {(item.price * item.quantity).toFixed(2)}€
                      </p>
                    </div>
                    <button
                      onClick={() => removeFromCart(item.id)}
                      className="flex items-center justify-center w-10 h-10 rounded-lg hover:bg-red-50 transition-colors"
                    >
                      <Trash2 className="w-5 h-5 text-red-600" />
                    </button>
                  </div>
                </motion.div>
              ))}
            </motion.div>
          </div>

          <motion.div
            initial={{ x: 20, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="lg:col-span-1"
          >
            <div className="bg-white rounded-lg shadow-lg p-6 sticky top-24">
              <h2 className="text-xl font-bold text-slate-900 mb-4">{t("summary")}</h2>
              <div className="space-y-3 mb-6 pb-6 border-b border-slate-200">
                <div className="flex justify-between text-slate-600">
                  <span>{t("subtotal")}:</span>
                  <span>{totalPrice.toFixed(2)}€</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>{t("delivery")}:</span>
                  <span className="text-green-600 font-semibold">{t("free")}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>{t("taxes")}:</span>
                  <span>{(totalPrice * 0.2).toFixed(2)}€</span>
                </div>
              </div>
              <div className="flex justify-between mb-6">
                <span className="text-lg font-bold text-slate-900">{t("total")}:</span>
                <span className="text-2xl font-bold text-orange-600">
                  {(totalPrice * 1.2).toFixed(2)}€
                </span>
              </div>
              <Button
                onClick={checkout}
                className="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-lg py-6 rounded-lg"
              >
                {t("proceed_payment")}
              </Button>
              <Link to="/" className="block mt-4">
                <Button variant="outline" className="w-full">
                  {t("continue_shopping")}
                </Button>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>
    </motion.div>
  );
}
