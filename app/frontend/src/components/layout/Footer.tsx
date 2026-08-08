import {
  Heart,
  Facebook,
  Twitter,
  Instagram,
  Linkedin,
  Mail,
  Phone,
  MapPin,
  Shield,
  Lock,
  Zap,
} from "lucide-react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { useLanguage } from "@/contexts/LanguageContext";

const Footer = () => {
  const { t } = useLanguage();
  const currentYear = new Date().getFullYear();

  const footerLinks = {
    [t("company")]: [
      { label: t("about"), href: "#" },
      { label: t("careers"), href: "#" },
      { label: t("blog"), href: "#" },
      { label: t("press"), href: "#" },
    ],
    [t("support")]: [
      { label: t("help_center"), href: "#" },
      { label: t("contact"), href: "#" },
      { label: t("faq"), href: "#" },
      { label: t("community"), href: "#" },
    ],
    [t("legal")]: [
      { label: t("terms"), href: "#" },
      { label: t("privacy"), href: "#" },
      { label: t("cookies"), href: "#" },
      { label: t("legal_notices"), href: "#" },
    ],
  };

  const socialLinks = [
    { icon: Facebook, href: "#", label: "Facebook" },
    { icon: Twitter, href: "#", label: "Twitter" },
    { icon: Instagram, href: "#", label: "Instagram" },
    { icon: Linkedin, href: "#", label: "LinkedIn" },
  ];

  const trustBadges = [
    { icon: Shield, label: t("secured") },
    { icon: Lock, label: t("encrypted") },
    { icon: Zap, label: t("fast") },
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.1 } },
  };
  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
  };

  return (
    <footer className="bg-background/50 backdrop-blur border-t border-secondary/20">
      <motion.div
        className="border-b border-secondary/20 py-8"
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        transition={{ duration: 0.5 }}
        viewport={{ once: true }}
      >
        <div className="container">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
            {trustBadges.map((badge, idx) => (
              <motion.div
                key={idx}
                className="flex items-center justify-center gap-3"
                variants={itemVariants}
              >
                <motion.div
                  className="p-2 rounded-full bg-primary/10"
                  whileHover={{ scale: 1.1, rotate: 5 }}
                >
                  <badge.icon className="h-5 w-5 text-primary" />
                </motion.div>
                <span className="font-semibold">{badge.label}</span>
              </motion.div>
            ))}
          </div>
        </div>
      </motion.div>

      <div className="container py-12">
        <motion.div
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-12"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          <motion.div className="lg:col-span-1" variants={itemVariants}>
            <Link to="/" className="flex items-center gap-2 mb-4">
              <span className="text-2xl font-heading font-extrabold tracking-tight text-primary">
                LBAL
              </span>
            </Link>
            <p className="text-sm text-muted-foreground mb-4">{t("footer_desc")}</p>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Phone className="h-4 w-4" />
                <a href="tel:+212XXXXXXXXX">+212 XXX XXX XXX</a>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Mail className="h-4 w-4" />
                <a href="mailto:support@lbal.ma">support@lbal.ma</a>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <MapPin className="h-4 w-4" />
                <span>Casablanca, Maroc</span>
              </div>
            </div>
          </motion.div>

          {Object.entries(footerLinks).map(([category, links]) => (
            <motion.div key={category} variants={itemVariants}>
              <h4 className="font-bold mb-4">{category}</h4>
              <ul className="space-y-2">
                {links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm text-muted-foreground hover:text-primary transition-colors"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </motion.div>
          ))}
        </motion.div>

        <motion.div
          className="bg-secondary/5 rounded-2xl p-6 mb-8 border border-secondary/20"
          variants={itemVariants}
          whileHover={{ borderColor: "var(--primary)" }}
        >
          <h3 className="font-bold mb-2">{t("newsletter")}</h3>
          <p className="text-sm text-muted-foreground mb-4">{t("newsletter_desc")}</p>
          <div className="flex gap-2">
            <input
              type="email"
              placeholder={t("your_email")}
              className="flex-1 px-4 py-2 bg-background rounded-lg border border-secondary/20 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
            />
            <button className="px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary-hover transition-colors font-semibold text-sm">
              {t("subscribe")}
            </button>
          </div>
        </motion.div>

        <motion.div
          className="flex items-center justify-between border-t border-secondary/20 pt-8"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          <p className="text-sm text-muted-foreground">
            &copy; {currentYear} LBAL. {t("all_rights")}
          </p>
          <motion.div className="flex gap-4">
            {socialLinks.map((social) => (
              <motion.a
                key={social.label}
                href={social.href}
                className="p-2 rounded-full bg-secondary/10 text-muted-foreground hover:bg-primary hover:text-primary-foreground transition-colors"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
                variants={itemVariants}
              >
                <social.icon className="h-4 w-4" />
              </motion.a>
            ))}
          </motion.div>
        </motion.div>
      </div>

      <motion.div
        className="text-center py-4 text-xs text-muted-foreground border-t border-secondary/10"
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        transition={{ delay: 0.5 }}
      >
        {t("made_with_love")} <Heart className="h-3 w-3 inline fill-red-500 text-red-500" />{" "}
        {t("in_morocco")}
      </motion.div>
    </footer>
  );
};

export default Footer;
