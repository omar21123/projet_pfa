import { useState } from "react";
import {
  BarChart3,
  Users,
  Package,
  ShieldCheck,
  Eye,
  Trash2,
  Ban,
  CheckCircle,
  TrendingUp,
  AlertTriangle,
} from "lucide-react";
import { motion } from "framer-motion";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const stats = [
  {
    label: "Total annonces",
    value: "1 284",
    icon: Package,
    trend: "+12%",
    color: "text-primary",
  },
  {
    label: "Utilisateurs",
    value: "3 652",
    icon: Users,
    trend: "+8%",
    color: "text-secondary",
  },
  {
    label: "Vues aujourd'hui",
    value: "12.4K",
    icon: Eye,
    trend: "+23%",
    color: "text-emerald-500",
  },
  {
    label: "Signalements",
    value: "7",
    icon: AlertTriangle,
    trend: "-3",
    color: "text-destructive",
  },
];

const mockAds = [
  {
    id: "1",
    title: "iPhone 15 Pro Max 256GB",
    seller: "Ahmed M.",
    city: "Casablanca",
    date: "Aujourd'hui",
    status: "active",
    reports: 0,
  },
  {
    id: "2",
    title: "Appartement 3 chambres Guéliz",
    seller: "Sara L.",
    city: "Marrakech",
    date: "Hier",
    status: "pending",
    reports: 0,
  },
  {
    id: "3",
    title: "Contenu suspect — arnaque potentielle",
    seller: "Unknown99",
    city: "Tanger",
    date: "Il y a 2 jours",
    status: "reported",
    reports: 3,
  },
  {
    id: "4",
    title: 'MacBook Pro M3 14"',
    seller: "Karim B.",
    city: "Rabat",
    date: "Il y a 3 jours",
    status: "active",
    reports: 0,
  },
];

const mockUsers = [
  {
    id: "1",
    name: "Ahmed Mahdaoui",
    email: "ahmed@email.com",
    ads: 5,
    joined: "Jan 2024",
    status: "active",
  },
  {
    id: "2",
    name: "Sara Lahlou",
    email: "sara@email.com",
    ads: 3,
    joined: "Mar 2024",
    status: "active",
  },
  {
    id: "3",
    name: "Unknown99",
    email: "fake@email.com",
    ads: 1,
    joined: "Avr 2025",
    status: "banned",
  },
  {
    id: "4",
    name: "Fatima Zahra",
    email: "fatima@email.com",
    ads: 8,
    joined: "Fév 2024",
    status: "active",
  },
];

const statusBadge = (status: string) => {
  const map: Record<string, string> = {
    active: "bg-emerald-500/10 text-emerald-600",
    pending: "bg-amber-500/10 text-amber-600",
    reported: "bg-destructive/10 text-destructive",
    banned: "bg-destructive/10 text-destructive",
  };
  const labels: Record<string, string> = {
    active: "Actif",
    pending: "En attente",
    reported: "Signalé",
    banned: "Banni",
  };
  return (
    <span
      className={`text-xs px-2 py-0.5 rounded-full font-medium ${map[status] || ""}`}
    >
      {labels[status] || status}
    </span>
  );
};

const AdminDashboard = () => {
  const [activeTab, setActiveTab] = useState("stats");

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-background flex flex-col"
    >
      <Navbar />
      <main className="flex-1">
        <div className="container py-8 max-w-6xl">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <ShieldCheck className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h1 className="text-xl font-heading font-bold">Administration</h1>
              <p className="text-sm text-muted-foreground">
                Gérez les annonces, utilisateurs et statistiques
              </p>
            </div>
          </div>

          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList className="bg-muted rounded-xl p-1 mb-6">
              <TabsTrigger
                value="stats"
                className="rounded-lg gap-2 data-[state=active]:bg-card data-[state=active]:shadow-sm"
              >
                <BarChart3 className="h-4 w-4" /> Statistiques
              </TabsTrigger>
              <TabsTrigger
                value="ads"
                className="rounded-lg gap-2 data-[state=active]:bg-card data-[state=active]:shadow-sm"
              >
                <Package className="h-4 w-4" /> Annonces
              </TabsTrigger>
              <TabsTrigger
                value="users"
                className="rounded-lg gap-2 data-[state=active]:bg-card data-[state=active]:shadow-sm"
              >
                <Users className="h-4 w-4" /> Utilisateurs
              </TabsTrigger>
            </TabsList>

            {/* Statistics */}
            <TabsContent value="stats">
              <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                {stats.map((s) => (
                  <div
                    key={s.label}
                    className="bg-card rounded-2xl border border-border p-5 shadow-card"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <s.icon className={`h-5 w-5 ${s.color}`} />
                      <span className="flex items-center gap-1 text-xs text-emerald-600 font-medium">
                        <TrendingUp className="h-3 w-3" /> {s.trend}
                      </span>
                    </div>
                    <p className="text-2xl font-heading font-bold">{s.value}</p>
                    <p className="text-sm text-muted-foreground mt-0.5">
                      {s.label}
                    </p>
                  </div>
                ))}
              </div>

              {/* Simple chart placeholder */}
              <div className="bg-card rounded-2xl border border-border p-6 shadow-card">
                <h3 className="font-heading font-semibold mb-4">
                  Activité des 7 derniers jours
                </h3>
                <div className="flex items-end gap-3 h-40">
                  {[65, 40, 80, 55, 90, 70, 85].map((h, i) => (
                    <div
                      key={i}
                      className="flex-1 flex flex-col items-center gap-1"
                    >
                      <div
                        className="w-full bg-primary/20 rounded-t-lg relative"
                        style={{ height: `${h}%` }}
                      >
                        <div
                          className="absolute inset-0 bg-primary rounded-t-lg"
                          style={{ height: `${h}%` }}
                        />
                      </div>
                      <span className="text-xs text-muted-foreground">
                        {["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"][i]}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </TabsContent>

            {/* Ads management */}
            <TabsContent value="ads">
              <div className="bg-card rounded-2xl border border-border shadow-card overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border bg-muted/50">
                        <th className="text-left py-3 px-4 font-semibold">
                          Annonce
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Vendeur
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Ville
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Statut
                        </th>
                        <th className="text-right py-3 px-4 font-semibold">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {mockAds.map((ad) => (
                        <tr
                          key={ad.id}
                          className="border-b border-border/50 hover:bg-muted/30 transition-colors"
                        >
                          <td className="py-3 px-4">
                            <p className="font-medium">{ad.title}</p>
                            <p className="text-xs text-muted-foreground">
                              {ad.date}
                            </p>
                          </td>
                          <td className="py-3 px-4 text-muted-foreground">
                            {ad.seller}
                          </td>
                          <td className="py-3 px-4 text-muted-foreground">
                            {ad.city}
                          </td>
                          <td className="py-3 px-4">
                            {statusBadge(ad.status)}
                          </td>
                          <td className="py-3 px-4">
                            <div className="flex justify-end gap-1">
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-emerald-600 hover:bg-emerald-500/10"
                              >
                                <CheckCircle className="h-4 w-4" />
                              </Button>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-destructive hover:bg-destructive/10"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </TabsContent>

            {/* Users management */}
            <TabsContent value="users">
              <div className="bg-card rounded-2xl border border-border shadow-card overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-border bg-muted/50">
                        <th className="text-left py-3 px-4 font-semibold">
                          Utilisateur
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Email
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Annonces
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Inscrit
                        </th>
                        <th className="text-left py-3 px-4 font-semibold">
                          Statut
                        </th>
                        <th className="text-right py-3 px-4 font-semibold">
                          Actions
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {mockUsers.map((user) => (
                        <tr
                          key={user.id}
                          className="border-b border-border/50 hover:bg-muted/30 transition-colors"
                        >
                          <td className="py-3 px-4 font-medium">{user.name}</td>
                          <td className="py-3 px-4 text-muted-foreground">
                            {user.email}
                          </td>
                          <td className="py-3 px-4 text-muted-foreground">
                            {user.ads}
                          </td>
                          <td className="py-3 px-4 text-muted-foreground">
                            {user.joined}
                          </td>
                          <td className="py-3 px-4">
                            {statusBadge(user.status)}
                          </td>
                          <td className="py-3 px-4">
                            <div className="flex justify-end gap-1">
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-destructive hover:bg-destructive/10"
                              >
                                <Ban className="h-4 w-4" />
                              </Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </main>
      <Footer />
    </motion.div>
  );
};

export default AdminDashboard;
