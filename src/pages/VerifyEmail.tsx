import { Link, useNavigate, useLocation } from "react-router-dom";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { Mail, ArrowLeft } from "lucide-react";
import { useLanguage } from "@/contexts/LanguageContext";
import { useAuthForm } from "@/features/auth";

const VerifyEmail = () => {
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();
  const location = useLocation();
  const { isLoading, submitVerifyEmail } = useAuthForm();
  const { t } = useLanguage();
  const queryParams = new URLSearchParams(location.search);

  const email =
    location.state?.email ||
    queryParams.get("email") ||
    sessionStorage.getItem("pendingVerifyEmail");

  const handleVerify = async () => {
    setError("");
    const codeValue = code.trim();

    if (!codeValue) {
      setError(t("fill_all_fields"));
      return;
    }
    if (!email) {
      setError(t("invalid_email"));
      return;
    }

    try {
      await submitVerifyEmail({
        email,
        code: codeValue,
      });
      sessionStorage.removeItem("pendingVerifyEmail");
      navigate("/login");
    } catch {
      setError(t("invalid_email"));
      setCode("");
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3 }}
      className="min-h-screen bg-background flex items-center justify-center px-4"
    >
      <div className="w-full max-w-sm">
        <div className="text-center mb-8">
          <Link to="/">
            <span className="text-3xl font-heading font-extrabold text-primary">LBAL</span>
          </Link>
          <p className="text-muted-foreground text-sm mt-2">{t("verify_email_title")}</p>
        </div>

        <div className="bg-card rounded-2xl border border-border p-6 shadow-card space-y-6">
          <div className="flex justify-center">
            <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
              <Mail className="h-8 w-8 text-primary" />
            </div>
          </div>
          <div className="text-center space-y-2">
            <p className="text-sm text-muted-foreground">{t("verify_email_title")}</p>
            <p className="font-semibold text-sm">{email}</p>
          </div>

          {error && (
            <div className="bg-destructive/10 border border-destructive/30 rounded-lg p-3 text-sm text-destructive">
              {error}
            </div>
          )}

          <div>
            <label className="text-sm font-medium mb-2 block">{t("verification_note")}</label>
            <input
              type="text"
              placeholder="000000"
              value={code}
              onChange={(e) => {
                const value = e.target.value.replace(/[^\d]/g, "").slice(0, 6);
                setCode(value);
              }}
              maxLength={6}
              className="w-full h-11 px-4 rounded-xl bg-muted/50 border border-border text-sm text-center text-2xl tracking-widest focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
          </div>

          <Button
            disabled={isLoading}
            onClick={handleVerify}
            className="w-full h-11 bg-primary hover:bg-primary-hover text-primary-foreground rounded-xl font-semibold"
          >
            {isLoading ? "..." : t("sign_in")}
          </Button>
        </div>

        <Link
          to="/login"
          className="inline-flex items-center gap-2 text-primary hover:text-primary/80 mt-6 text-sm font-medium"
        >
          <ArrowLeft className="h-4 w-4" />
          {t("back")}
        </Link>
      </div>
    </motion.div>
  );
};

export default VerifyEmail;
