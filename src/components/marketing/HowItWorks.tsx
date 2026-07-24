import { Search, ShoppingBag, TrendingUp, AlertCircle } from "lucide-react";
import { motion } from "framer-motion";
import { useLanguage } from "@/contexts/LanguageContext";

const HowItWorks = () => {
  const { t } = useLanguage();

  const steps = [
    { icon: Search, title: t("step_search"), description: t("step_search_desc") },
    { icon: ShoppingBag, title: t("step_contact"), description: t("step_contact_desc") },
    { icon: TrendingUp, title: t("step_review"), description: t("step_review_desc") },
    { icon: AlertCircle, title: t("step_secure"), description: t("step_secure_desc") },
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.15 } },
  };
  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.6 } },
  };

  return (
    <section className="py-16 bg-gradient-to-b from-transparent via-secondary/5 to-transparent">
      <div className="container">
        <h2 className="text-3xl font-heading font-bold text-center mb-4">{t("how_it_works")}</h2>
        <p className="text-center text-muted-foreground mb-12 max-w-2xl mx-auto">
          {t("how_it_works_subtitle")}
        </p>

        <motion.div
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          {steps.map((step, idx) => (
            <motion.div key={idx} className="relative" variants={itemVariants}>
              {idx < steps.length - 1 && (
                <div className="hidden lg:block absolute top-20 left-1/2 w-full h-0.5 bg-gradient-to-r from-primary/20 to-transparent" />
              )}
              <motion.div
                className="bg-card rounded-2xl p-6 text-center border border-secondary/20 relative z-10 h-full hover:shadow-lg transition-shadow"
                whileHover={{ y: -5 }}
              >
                <motion.div
                  className="absolute -top-4 left-1/2 -translate-x-1/2 w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold"
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  transition={{ delay: 0.2 + idx * 0.1 }}
                >
                  {idx + 1}
                </motion.div>
                <motion.div
                  className="w-16 h-16 rounded-xl bg-secondary/10 flex items-center justify-center mx-auto mb-4"
                  whileHover={{ scale: 1.1, rotate: 5 }}
                >
                  <step.icon className="h-8 w-8 text-primary" />
                </motion.div>
                <h3 className="font-bold text-lg mb-2">{step.title}</h3>
                <p className="text-sm text-muted-foreground">{step.description}</p>
              </motion.div>
            </motion.div>
          ))}
        </motion.div>

        <motion.div
          className="text-center mt-12"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          <button className="px-8 py-3 bg-primary text-primary-foreground rounded-xl font-semibold hover:bg-primary-hover transition-colors">
            {t("start_now")}
          </button>
        </motion.div>
      </div>
    </section>
  );
};

export default HowItWorks;
