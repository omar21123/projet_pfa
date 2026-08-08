import React, { useState } from "react";
import { Search, Users, Shield, UserX, UserCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";

interface User {
  id: string;
  username: string;
  email: string;
  role: "admin" | "customer";
  status: "active" | "banned";
}

export default function UsersList() {
  const [users, setUsers] = useState<User[]>([
    { id: "u-1", username: "Mehdi Alami", email: "mehdi@gmail.com", role: "admin", status: "active" },
    { id: "u-2", username: "Sofia Benjelloun", email: "sofia.benj@outlook.com", role: "customer", status: "active" },
    { id: "u-3", username: "Youssef Tazi", email: "youssef.t@yahoo.fr", role: "customer", status: "banned" }
  ]);
  const [search, setSearch] = useState("");

  const toggleBan = (id: string) => {
    setUsers(prev => prev.map(u => {
      if (u.id === id) {
        return { ...u, status: u.status === "active" ? "banned" : "active" };
      }
      return u;
    }));
  };

  const filtered = users.filter(u => 
    u.username.toLowerCase().includes(search.toLowerCase()) || 
    u.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Utilisateurs inscrits</h1>
        <p className="text-slate-500 text-sm">Contrôlez les comptes membres de la marketplace.</p>
      </div>

      <div className="relative bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <Search className="absolute left-7 top-6.5 h-4 w-4 text-slate-400" />
        <Input 
          placeholder="Rechercher par nom d'utilisateur ou e-mail..." 
          className="pl-9 bg-slate-50 border-slate-200"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 text-xs font-semibold uppercase tracking-wider">
              <th className="py-4 px-6">Nom de l'utilisateur</th>
              <th className="py-4 px-6">Rôle</th>
              <th className="py-4 px-6 text-center">État du compte</th>
              <th className="py-4 px-6 text-right">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
            {filtered.map(u => (
              <tr key={u.id} className="hover:bg-slate-50/50">
                <td className="py-4 px-6">
                  <div className="font-semibold text-slate-900">{u.username}</div>
                  <div className="text-xs text-slate-400">{u.email}</div>
                </td>
                <td className="py-4 px-6">
                  <Badge variant="secondary" className="gap-1 px-2.5 py-0.5">
                    {u.role === "admin" ? <Shield className="w-3.5 h-3.5 text-indigo-500" /> : <Users className="w-3.5 h-3.5 text-slate-400" />}
                    {u.role === "admin" ? "Administrateur" : "Client"}
                  </Badge>
                </td>
                <td className="py-4 px-6 text-center">
                  <Badge className={`px-2.5 py-0.5 border ${
                    u.status === "active" ? "bg-emerald-50 text-emerald-700 border-emerald-200" : "bg-rose-50 text-rose-700 border-rose-200"
                  }`}>
                    {u.status === "active" ? "Actif" : "Banni"}
                  </Badge>
                </td>
                <td className="py-4 px-6 text-right">
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className={u.status === "active" ? "text-rose-600 hover:bg-rose-50" : "text-emerald-600 hover:bg-emerald-50"}
                    onClick={() => toggleBan(u.id)}
                  >
                    {u.status === "active" ? <UserX className="w-4 h-4 mr-1.5" /> : <UserCheck className="w-4 h-4 mr-1.5" />}
                    {u.status === "active" ? "Bannir" : "Réactiver"}
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