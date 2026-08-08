import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { useEffect, useState } from "react";
import { useUser } from "@/hooks/useUser";
import { useProfile } from "@/hooks/useProfile";
import { useLanguage } from "@/contexts/LanguageContext";

const Settings = () => {
  const navigate = useNavigate();
  const { user, updateUser } = useUser();
  const { t } = useLanguage();
  const [name, setName] = useState("");
  const { data: profile } = useProfile();

  useEffect(() => {
    if (!user) {
      navigate("/login");
      return;
    }
    setName(user.name);
  }, [user, navigate]);

  const handleSave = () => {
    if (name) {
      updateUser(name);
      alert(t("settings_saved"));
    }
  };

  if (!user) return null;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-background"
    >
      <div className="container py-8">
        <Link
          to="/profile"
          className="inline-flex items-center gap-2 text-primary hover:text-primary/80 mb-8"
        >
          <ArrowLeft className="h-4 w-4" />
          {t("back_to_profile")}
        </Link>
        <div className="max-w-2xl">
          <div className="bg-card rounded-2xl border border-border p-8 shadow-card">
            <h1 className="text-3xl font-heading font-extrabold mb-8">{t("settings_title")}</h1>
            <div className="space-y-6">
              <div>
                <label className="text-sm font-medium mb-2 block">{t("full_name")}</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full h-11 px-4 rounded-xl bg-muted/50 border border-border text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-2 block">{t("email")}</label>
                <input
                  type="email"
                  value={profile?.email}
                  disabled
                  className="w-full h-11 px-4 rounded-xl bg-muted/50 border border-border text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 opacity-60 cursor-not-allowed"
                />
                <p className="text-xs text-muted-foreground mt-1">{t("email_no_edit")}</p>
              </div>
              <div className="pt-6 border-t border-border flex gap-2">
                <Button
                  onClick={handleSave}
                  className="bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl font-semibold flex-1"
                >
                  {t("save_changes")}
                </Button>
                <Link to="/profile" className="flex-1">
                  <Button variant="outline" className="w-full rounded-xl">
                    {t("cancel")}
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default Settings;
