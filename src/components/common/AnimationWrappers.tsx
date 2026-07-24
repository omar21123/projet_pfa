import { motion } from "framer-motion";
import React from "react";

// Wrapper pour animations au scroll
export const ScrollAnimationWrapper = ({
  children,
  animationType = "fadeInUp",
}: {
  children: React.ReactNode;
  animationType?: "fadeInUp" | "fadeInLeft" | "fadeInRight" | "slideInUp" | "scaleIn";
}) => {
  const variants = {
    fadeInUp: {
      hidden: { opacity: 0, y: 40 },
      visible: { opacity: 1, y: 0 },
    },
    fadeInLeft: {
      hidden: { opacity: 0, x: -40 },
      visible: { opacity: 1, x: 0 },
    },
    fadeInRight: {
      hidden: { opacity: 0, x: 40 },
      visible: { opacity: 1, x: 0 },
    },
    slideInUp: {
      hidden: { opacity: 0, y: 60 },
      visible: { opacity: 1, y: 0 },
    },
    scaleIn: {
      hidden: { opacity: 0, scale: 0.9 },
      visible: { opacity: 1, scale: 1 },
    },
  };

  return (
    <motion.div
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount: 0.3 }}
      transition={{ duration: 0.6, ease: "easeOut" }}
      variants={variants[animationType]}
    >
      {children}
    </motion.div>
  );
};

// Wrapper pour hover effects
export const HoverScaleWrapper = ({
  children,
  scale = 1.05,
}: {
  children: React.ReactNode;
  scale?: number;
}) => (
  <motion.div whileHover={{ scale }} transition={{ duration: 0.3 }}>
    {children}
  </motion.div>
);

// Wrapper pour transitions de page
export const PageTransition = ({ children }: { children: React.ReactNode }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.4 }}
  >
    {children}
  </motion.div>
);

// Container pour animations en cascade
export const StaggerContainer = ({
  children,
  staggerDelay = 0.1,
}: {
  children: React.ReactNode;
  staggerDelay?: number;
}) => (
  <motion.div
    initial="hidden"
    whileInView="visible"
    viewport={{ once: true, amount: 0.1 }}
    variants={{
      visible: {
        transition: {
          staggerChildren: staggerDelay,
        },
      },
    }}
  >
    {children}
  </motion.div>
);

// Item enfant pour StaggerContainer
export const StaggerItem = ({ children }: { children: React.ReactNode }) => (
  <motion.div
    variants={{
      hidden: { opacity: 0, y: 20 },
      visible: { opacity: 1, y: 0 },
    }}
    transition={{ duration: 0.5 }}
  >
    {children}
  </motion.div>
);

// Hover lift effect
export const HoverLiftWrapper = ({ children }: { children: React.ReactNode }) => (
  <motion.div
    whileHover={{ y: -8, boxShadow: "0 20px 25px rgba(0,0,0,0.1)" }}
    transition={{ duration: 0.3 }}
  >
    {children}
  </motion.div>
);

// Pulse animation
export const PulseWrapper = ({ children }: { children: React.ReactNode }) => (
  <motion.div animate={{ scale: [1, 1.05, 1] }} transition={{ duration: 2, repeat: Infinity }}>
    {children}
  </motion.div>
);
