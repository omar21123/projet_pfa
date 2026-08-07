import { useState } from "react";
import { ShoppingCart, Loader2, Check } from "lucide-react";
import { useCart } from "@/features/cart/hooks/useCart";
import { useNotification } from "@/features/notifications/hooks/useNotification";
import { useLanguage } from "@/contexts/LanguageContext";
import { cn } from "@/lib/utils";

interface ShoppingCartButtonProps {
  productID: number;
  unitPrice?: number;
  compositionID?: number;
  fromSearch?: boolean;
  searchTerm?: string;
  className?: string;
  fullWidth?: boolean;
}

export const ShoppingCartButton = ({
  productID,
  unitPrice,
  compositionID,
  fromSearch = false,
  searchTerm,
  className,
  fullWidth = true,
}: ShoppingCartButtonProps) => {
  const { t } = useLanguage();
  const { addToCart } = useCart();
  const { addNotification } = useNotification();

  const [isLoading, setIsLoading] = useState(false);
  const [isAdded, setIsAdded] = useState(false);

  const handleClick = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    if (isLoading) return;

    setIsLoading(true);
    try {
      await addToCart({
        productID,
        UnitPrice: unitPrice,
        CompositionID: compositionID,
        FromSearch: fromSearch,
        SearchTerm: searchTerm,
      });

      setIsAdded(true);
      addNotification(
        t("added_to_cart_title") || "Panier",
        t("added_to_cart_msg") || "Produit ajouté au panier avec succès.",
        "success"
      );

      setTimeout(() => setIsAdded(false), 1500);
    } catch (error) {
      addNotification("Erreur", "Impossible d'ajouter le produit au panier.", "error");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className={cn(
        "relative inline-flex items-center justify-center gap-2.5 px-4 py-2.5 rounded-xl text-sm font-semibold text-white",
        "bg-[#324b56] hover:bg-[#253942] active:scale-[0.98]",
        "shadow-sm hover:shadow-md transition-all duration-200 ease-in-out cursor-pointer select-none overflow-hidden",
        "disabled:opacity-75 disabled:cursor-not-allowed",
        fullWidth && "w-full",
        className
      )}
    >
      {isLoading ? (
        <Loader2 className="w-4 h-4 animate-spin text-white" />
      ) : isAdded ? (
        <>
          <Check className="w-4 h-4 text-emerald-400" />
          <span>{t("added") || "Ajouté !"}</span>
        </>
      ) : (
        <>
          <ShoppingCart className="w-4 h-4 stroke-[2]" />
          <span>{t("add_to_cart") || "Ajouter au panier"}</span>
        </>
      )}
    </button>
  );
};