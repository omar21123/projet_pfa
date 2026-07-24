import { ChevronDown, Plus } from "lucide-react";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useLanguage } from "@/contexts/LanguageContext";

export const FAQ = () => {
  const { t } = useLanguage();
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const faqs = [
    { question: t("faq_q1"), answer: t("faq_a1") },
    { question: t("faq_q2"), answer: t("faq_a2") },
    { question: t("faq_q3"), answer: t("faq_a3") },
    { question: t("faq_q4"), answer: t("faq_a4") },
    { question: t("faq_q5"), answer: t("faq_a5") },
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.1 } },
  };
  const itemVariants = {
    hidden: { opacity: 0, x: -20 },
    visible: { opacity: 1, x: 0, transition: { duration: 0.5 } },
  };

  return (
    <section className="py-16">
      <div className="container max-w-3xl">
        <h2 className="text-3xl font-heading font-bold text-center mb-4">{t("faq_title")}</h2>
        <p className="text-center text-muted-foreground mb-12">{t("faq_subtitle")}</p>

        <motion.div
          className="space-y-3"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          {faqs.map((faq, idx) => (
            <motion.div
              key={idx}
              variants={itemVariants}
              className="border border-secondary/20 rounded-xl overflow-hidden"
            >
              <motion.button
                onClick={() => setOpenIndex(openIndex === idx ? null : idx)}
                className="w-full px-6 py-4 flex items-center gap-3 bg-card hover:bg-secondary/5 transition-colors text-left"
                whileHover={{ paddingLeft: 24 + 4 }}
              >
                <ChevronDown
                  className={`h-5 w-5 text-primary transition-transform duration-300 ${openIndex === idx ? "rotate-180" : ""}`}
                />
                <span className="font-semibold flex-1">{faq.question}</span>
              </motion.button>
              <AnimatePresence>
                {openIndex === idx && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.3 }}
                    className="px-6 py-4 bg-secondary/5 text-muted-foreground border-t border-secondary/20"
                  >
                    {faq.answer}
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          ))}
        </motion.div>

        <motion.div
          className="text-center mt-12"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
        >
          <p className="text-muted-foreground mb-4">{t("no_answer")}</p>
          <button className="px-6 py-2 border border-primary text-primary rounded-lg hover:bg-primary/10 transition-colors inline-flex items-center gap-2 font-semibold">
            <Plus className="h-4 w-4" />
            {t("contact_support")}
          </button>
        </motion.div>
      </div>
    </section>
  );
};

export default FAQ;
