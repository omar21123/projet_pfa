import React, { useState } from "react";
import { Search, ShoppingBag, Eye, Trash2, CheckCircle, Ban, Tag, MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";

interface Product {
  id: string;
  title: string;
  vendor: string;
  price: number;
  category: string;
  status: "active" | "review" | "rejected";
  sales: number;
}

const mockProducts: Product[] = [
  { id: "p-1", title: "Tapis Berbère en Laine Pure", vendor: "Tapis Atlas Tradition", price: 3400, category: "Tapis & Tissage", status: "active", sales: 12 },
  { id: "p-2", title: "Huile d'Argan Bio 100ml", vendor: "Coopérative Argania", price: 150, category: "Cosmétique & Beauté", status: "active", sales: 85 },
  { id: "p-3", title: "Tajine en terre cuite émaillée", vendor: "Artisanat du Sud", price: 180, category: "Décoration & Maison", status: "review", sales: 0 },
  { id: "p-4", title: "Pouf en cuir marocain brodé", vendor: "Artisanat du Sud", price: 450, category: "Décoration & Maison", status: "rejected", sales: 3 }
];

export default function Listings() {
  const [products, setProducts] = useState<Product[]>(mockProducts);
  const [searchTerm, setSearchTerm] = useState("");

  const updateStatus = (id: string, newStatus: "active" | "review" | "rejected") => {
    setProducts(prev => prev.map(p => p.id === id ? { ...p, status: newStatus } : p));
  };

  const deleteProduct = (id: string) => {
    setProducts(prev => prev.filter(p => p.id !== id));
  };

  const filtered = products.filter(p => 
    p.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.vendor.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Gestion des Annonces (Produits)</h1>
        <p className="text-slate-500 text-sm">Modérez et analysez les annonces déposées par vos vendeurs.</p>
      </div>

      <div className="flex items-center gap-3 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Rechercher par titre de produit, vendeur..."
            className="pl-9 bg-slate-50 border-slate-200"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 text-xs font-semibold uppercase tracking-wider">
              <th className="py-4 px-6">Produit</th>
              <th className="py-4 px-6">Vendeur</th>
              <th className="py-4 px-6">Catégorie</th>
              <th className="py-4 px-6 text-right">Prix</th>
              <th className="py-4 px-6 text-center">Ventes</th>
              <th className="py-4 px-6 text-center">Statut</th>
              <th className="py-4 px-6 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
            {filtered.map(p => (
              <tr key={p.id} className="hover:bg-slate-50/50">
                <td className="py-4 px-6 font-semibold text-slate-900">{p.title}</td>
                <td className="py-4 px-6 text-slate-600">{p.vendor}</td>
                <td className="py-4 px-6">
                  <Badge variant="secondary" className="flex w-fit items-center gap-1">
                    <Tag className="w-3 h-3" /> {p.category}
                  </Badge>
                </td>
                <td className="py-4 px-6 text-right font-mono font-semibold">{p.price} DH</td>
                <td className="py-4 px-6 text-center font-medium">{p.sales}</td>
                <td className="py-4 px-6 text-center">
                  <Badge className={`px-2.5 py-0.5 border ${
                    p.status === "active" ? "bg-emerald-50 text-emerald-700 border-emerald-100" :
                    p.status === "review" ? "bg-amber-50 text-amber-700 border-amber-100" :
                    "bg-rose-50 text-rose-700 border-rose-100"
                  }`}>
                    {p.status === "active" ? "En ligne" : p.status === "review" ? "En relecture" : "Désactivé"}
                  </Badge>
                </td>
                <td className="py-4 px-6 text-right space-x-1.5 whitespace-nowrap">
                  {p.status !== "active" && (
                    <Button variant="ghost" size="icon" className="text-emerald-600 hover:bg-emerald-50" onClick={() => updateStatus(p.id, "active")} title="Valider">
                      <CheckCircle className="w-4 h-4" />
                    </Button>
                  )}
                  {p.status === "active" && (
                    <Button variant="ghost" size="icon" className="text-amber-600 hover:bg-amber-50" onClick={() => updateStatus(p.id, "review")} title="Mettre en relecture">
                      <Ban className="w-4 h-4" />
                    </Button>
                  )}
                  <Button variant="ghost" size="icon" className="text-rose-600 hover:bg-rose-50" onClick={() => deleteProduct(p.id)} title="Supprimer">
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}