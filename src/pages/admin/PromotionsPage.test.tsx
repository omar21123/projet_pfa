import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import PromotionsPage from "./PromotionsPage";
import type { Promotion } from "@/types/promotion";

const promotion33: Promotion = {
  promotion_id: 33,
  vendor_id: 18,
  name: "Promo Lampe Max 231",
  description: "Promotion générée automatiquement.",
  promo_code: "PROMO-259-102012230890948951",
  discount_type: { code: "FIXED_AMOUNT", label: "Montant fixe" },
  discount_value: 41.15,
  max_discount_amount: 269.38,
  min_order_amount: 22.37,
  scope_type: { code: "PRODUCT", label: "Produit specifique" },
  target_product_id: 259,
  target_category_id: null,
  usage_limit_total: 446,
  usage_limit_per_user: 1,
  usage_count: 0,
  start_date: "2026-07-02 16:56:09",
  end_date: "2026-09-20 16:56:09",
  status: { code: "VALIDATED", label: "Validée" },
  is_active: true,
  created_at: "2026-07-02 16:56:09",
  updated_at: "2026-07-02 16:56:09",
};

vi.mock("@/hooks/usePromotions", () => ({
  usePromotionLookups: () => ({ data: { statuses: [], scope_types: [] } }),
  usePromotionList: () => ({
    data: { data: [promotion33], meta: { page: 1, page_size: 20, has_more: false } },
    isPending: false,
    isFetching: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
  }),
  usePromotion: () => ({ data: { success: true, data: promotion33 }, isPending: false, isError: false, error: null }),
}));

describe("PromotionsPage", () => {
  it("affiche le détail d'une promotion à montant fixe renvoyée par l'API", () => {
    render(<PromotionsPage />);

    fireEvent.click(screen.getByRole("button", { name: /détails/i }));

    expect(screen.getAllByText("Promo Lampe Max 231")).toHaveLength(2);
    expect(screen.getAllByText(/41\.15 DH/)).toHaveLength(2);
    expect(screen.getByText(/Montant fixe/)).toBeInTheDocument();
    expect(screen.getByText(/269\.38 DH/)).toBeInTheDocument();
    expect(screen.getByText(/22\.37 DH/)).toBeInTheDocument();
  });
});
