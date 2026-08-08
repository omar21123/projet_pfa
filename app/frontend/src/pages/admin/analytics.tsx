import React from "react";
import { BarChart3, TrendingUp, Users, ShoppingBag, DollarSign } from "lucide-react";

export default function Analytics() {
  const stats = [
    { label: "Chiffre d'Affaires", value: "124,500 DH", change: "+12.5%", icon: DollarSign, color: "text-emerald-600 bg-emerald-50" },
    { label: "Vendeurs Actifs", value: "32", change: "+8%", icon: Users, color: "text-indigo-600 bg-indigo-50" },
    { label: "Ventes Totales", value: "1,420", change: "+24%", icon: ShoppingBag, color: "text-violet-600 bg-violet-50" },
    { label: "Taux de Conversion", value: "3.2%", change: "+0.4%", icon: TrendingUp, color: "text-amber-600 bg-amber-50" },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Analyses & Statistiques</h1>
        <p className="text-slate-500 text-sm">Suivez en temps réel la croissance de votre marketplace.</p>
      </div>

      {/* Cartes statistiques */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => {
          const Icon = stat.icon;
          return (
            <div key={i} className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
              <div className="space-y-2">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{stat.label}</span>
                <div className="text-2xl font-bold text-slate-900">{stat.value}</div>
                <span className="text-xs font-medium text-emerald-600">{stat.change} ce mois</span>
              </div>
              <div className={`p-3 rounded-lg ${stat.color}`}>
                <Icon className="w-6 h-6" />
              </div>
            </div>
          );
        })}
      </div>

      {/* Graphique simulé */}
      <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
        <h2 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
          <BarChart3 className="w-5 h-5 text-indigo-600" /> Activité Mensuelle
        </h2>
        <div className="h-64 flex items-end justify-between gap-2 pt-4">
          {[40, 55, 45, 60, 75, 90, 85, 100, 110, 95, 120, 140].map((val, i) => (
            <div key={i} className="flex-1 flex flex-col items-center gap-2 h-full justify-end">
              <div 
                className="w-full bg-indigo-500 hover:bg-indigo-600 rounded-t-md transition-all cursor-pointer" 
                style={{ height: `${(val / 140) * 80}%` }}
              />
              <span className="text-xs text-slate-400">{['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][i]}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}