import { motion } from "framer-motion";
import { useRef } from "react";
import { useInView } from "framer-motion";
import { useLanguage } from "@/contexts/LanguageContext";

const AnimatedCounter = ({ value, suffix }: { value: number; suffix: string }) => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, scale: 0.5 }}
      animate={isInView ? { opacity: 1, scale: 1 } : { opacity: 0, scale: 0.5 }}
      transition={{ duration: 0.5 }}
    >
      <div className="text-4xl font-bold text-primary">
        {isInView && (
          <motion.span
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 2.5 }}
          >
            {value.toLocaleString()}
            {suffix}
          </motion.span>
        )}
      </div>
    </motion.div>
  );
};

const AnimatedStats = () => {
  const { t } = useLanguage();

  const stats = [
    { label: t("active_users"), value: 250000, suffix: "+" },
    { label: t("daily_ads"), value: 15000, suffix: "+" },
    { label: t("safe_transactions"), value: 500000, suffix: "+" },
    { label: t("cities_covered"), value: 12, suffix: "" },
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.1 } },
  };
  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.6 } },
  };

  return (
    <section className="py-16 bg-gradient-to-r from-primary/10 via-secondary/10 to-primary/10 rounded-3xl my-12">
      <div className="container">
        <h2 className="text-3xl font-heading font-bold text-center mb-12">{t("stats_title")}</h2>
        <motion.div
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8"
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          {stats.map((stat, idx) => (
            <motion.div
              key={idx}
              className="text-center p-6"
              variants={itemVariants}
              whileHover={{ scale: 1.05 }}
            >
              <div className="mb-4">
                <AnimatedCounter value={stat.value} suffix={stat.suffix} />
              </div>
              <p className="text-muted-foreground font-medium">{stat.label}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};

export default AnimatedStats;
