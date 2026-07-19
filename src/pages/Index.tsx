import Navbar from "@/components/Navbar";
import HeroSearch from "@/components/HeroSearch";
import AdsGrid from "@/components/AdsGrid";
import Footer from "@/components/Footer";
import FeaturedAds from "@/components/FeaturedAds";
import AnimatedStats from "@/components/AnimatedStats";
import Testimonials from "@/components/Testimonials";
import HowItWorks from "@/components/HowItWorks";
import FeaturedSellers from "@/components/marketing/FeaturedSellers";
import FAQ from "@/components/FAQ";
import ChatBot from "@/components/ChatBot";
import { motion } from "framer-motion";

const sectionVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.6 },
  },
};

const slideInLeft = {
  hidden: { opacity: 0, x: -40 },
  visible: {
    opacity: 1,
    x: 0,
    transition: { duration: 0.6 },
  },
};

const scaleUp = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: {
    opacity: 1,
    scale: 1,
    transition: { duration: 0.5 },
  },
};

const Index = () => {
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
        <HeroSearch />
        <FeaturedSellers />

        {/* Featured Ads Section */}
        <motion.div
          variants={slideInLeft}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
        >
          <FeaturedAds />
        </motion.div>

        {/* Recent Ads */}
        <motion.div
          variants={sectionVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
        >
          <AdsGrid />
        </motion.div>

        {/* Animated Statistics */}
        <motion.div
          variants={scaleUp}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="container px-4"
        >
          <AnimatedStats />
        </motion.div>

        {/* How It Works */}
        <motion.div
          variants={sectionVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
        >
          <HowItWorks />
        </motion.div>

        {/* Testimonials */}
        <motion.div
          variants={scaleUp}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
        >
          <Testimonials />
        </motion.div>

        {/* FAQ */}
        <motion.div
          variants={slideInLeft}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
        >
          <FAQ />
        </motion.div>
      </main>
      <Footer />

      {/* ChatBot */}
      <ChatBot />
    </motion.div>
  );
};

export default Index;
