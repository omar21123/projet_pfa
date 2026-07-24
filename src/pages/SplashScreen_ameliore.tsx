import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence, useMotionValue, useTransform, useSpring, MotionValue } from 'framer-motion';

const RIBBON_PATH =
  'M 200,100 C 140,20 50,20 50,100 C 50,180 140,180 200,100 C 260,20 350,20 350,100 C 350,180 260,180 200,100 Z';

interface SplashScreenProps {
  onFinish?: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onFinish }) => {
  const [status, setStatus] = useState<'init' | 'drawing' | 'finalizing' | 'exiting'>('init');
  const progress = useMotionValue(0);
  const smoothProgress = useSpring(progress, { stiffness: 20, damping: 15 });

  // Transforms réactifs pour Framer Motion
  const progressWidth = useTransform(smoothProgress, [0, 100], ['0%', '100%']);

  // Orchestration du séquençage
  useEffect(() => {
    const sequence = async () => {
      // 1. Apparition des halos
      setStatus('init');
      await new Promise(r => setTimeout(r, 500));
      
      // 2. Lancement du tracé
      setStatus('drawing');
      progress.set(100);
      
      // 3. Fin du tracé et Flash
      await new Promise(r => setTimeout(r, 2800));
      setStatus('finalizing');
      
      // 4. Sortie
      await new Promise(r => setTimeout(r, 1000));
      setStatus('exiting');
      setTimeout(() => onFinish?.(), 800);
    };
    sequence();
  }, [progress, onFinish]);

  return (
    <AnimatePresence>
      {status !== 'exiting' && (
        <motion.div
          key="splash-screen"
          initial={{ opacity: 1 }}
          exit={{ 
            opacity: 0, 
            scale: 1.05, 
            filter: 'blur(16px)',
            transition: { duration: 1.3, ease: "easeInOut" } 
          }}
          className="fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-white overflow-hidden select-none"
        >
          {/* --- FOND : RAYONS & HALOS --- */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            {/* Pattern Rayons */}
            <svg className="absolute w-[200%] h-[200%] opacity-[0.03] animate-[spin_60s_linear_infinite]">
              <defs>
                <pattern id="rays" x="50%" y="50%" width="40" height="40" patternUnits="userSpaceOnUse">
                  <line x1="0" y1="0" x2="400" y2="400" stroke="black" strokeWidth="0.5" />
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#rays)" />
            </svg>

            {/* Halos lumineux */}
            <motion.div 
              animate={{ 
                scale: [0.95, 1.1, 0.95],
                opacity: [0.2, 0.4, 0.2],
                rotate: [0, 90, 0]
              }}
              transition={{ duration: 10, repeat: Infinity, ease: "linear" }}
              className="absolute w-[600px] h-[600px]"
            >
              <div className="absolute top-0 left-0 w-full h-full bg-sky-200 rounded-full blur-[120px]" />
              <div className="absolute top-0 left-0 w-full h-full bg-emerald-100 rounded-full blur-[100px] translate-x-20" />
            </motion.div>
          </div>

          {/* --- LOGO CONTAINER --- */}
          <motion.div 
            animate={{ y: [-4, 4, -4] }}
            transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
            className="relative flex flex-col items-center"
          >
            <svg className="w-80 h-48 drop-shadow-2xl overflow-visible" viewBox="0 0 400 200">
              <defs>
                {/* Filtre Glow */}
                <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
                  <feGaussianBlur stdDeviation="6" result="blur" />
                  <feComposite in="SourceGraphic" in2="blur" operator="over" />
                </filter>

                {/* Reflet brillant */}
                <linearGradient id="shine" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="white" stopOpacity="0" />
                  <stop offset="50%" stopColor="white" stopOpacity="0.8" />
                  <stop offset="100%" stopColor="white" stopOpacity="0" />
                </linearGradient>

                {/* Gradient principal Connectia */}
                <linearGradient id="brandGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#0EA5E9" />
                  <stop offset="100%" stopColor="#10B981" />
                </linearGradient>
              </defs>

              {/* Épaisseur 3D (Ombre) */}
              <path d={RIBBON_PATH} stroke="#CBD5E1" strokeWidth="28" fill="none" strokeLinecap="round" opacity="0.2" transform="translate(0, 4)" />

              {/* Tracé Fantôme */}
              <path d={RIBBON_PATH} stroke="#F1F5F9" strokeWidth="26" fill="none" strokeLinecap="round" />

              {/* Tracé Principal Animé */}
              <motion.path
                d={RIBBON_PATH}
                stroke="url(#brandGrad)"
                strokeWidth="26"
                fill="none"
                strokeLinecap="round"
                strokeLinejoin="round"
                style={{ 
                  pathLength: smoothProgress, 
                  pathOffset: 0, 
                  filter: status === 'finalizing' ? 'url(#glow)' : 'none' 
                }}
              />

              {/* Reflet Métallique */}
              <motion.path
                d={RIBBON_PATH}
                stroke="url(#shine)"
                strokeWidth="12"
                fill="none"
                strokeLinecap="round"
                style={{ pathLength: smoothProgress, opacity: 0.4 }}
                transform="translate(0, -4)"
              />

              {/* La Comète de Tracé */}
              {(status === 'drawing' || status === 'finalizing') && (
                <CometTail progress={smoothProgress} />
              )}
            </svg>

            {/* Flash Lumineux à la fin */}
            <AnimatePresence>
              {status === 'finalizing' && (
                <motion.div 
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: [0, 1, 0], scale: [1, 2, 2.5] }}
                  transition={{ duration: 0.6 }}
                  className="absolute inset-0 bg-white rounded-full blur-3xl z-50 pointer-events-none"
                />
              )}
            </AnimatePresence>

            {/* Texte Animé Lettre par Lettre */}
            <div className="mt-8 overflow-hidden flex">
              {"CONNECTIA".split("").map((char, i) => (
                <motion.span
                  key={i}
                  initial={{ y: 50, opacity: 0 }}
                  animate={status !== 'init' ? { y: 0, opacity: 1 } : {}}
                  transition={{ delay: 0.4 + i * 0.07, duration: 0.8, ease: [0.33, 1, 0.68, 1] }}
                  className={`text-5xl font-black tracking-tighter ${char === 'I' || char === 'A' ? 'text-sky-500' : 'text-slate-900'}`}
                >
                  {char}
                </motion.span>
              ))}
            </div>

            {/* Sous-titre */}
            <motion.p
              initial={{ opacity: 0, letterSpacing: "0.2em" }}
              animate={status !== 'init' ? { opacity: 1, letterSpacing: "0.5em" } : {}}
              transition={{ delay: 1.3, duration: 1.8 }}
              className="text-[10px] font-bold text-slate-400 uppercase mt-4"
            >
              Votre place de marché en ligne
            </motion.p>

            {/* Barre de Progression Glassmorphism */}
            <div className="mt-10 w-64 h-[6px] bg-slate-100/80 rounded-full relative overflow-hidden backdrop-blur-md border border-slate-200/50 shadow-inner">
              <motion.div 
                className="absolute top-0 left-0 h-full bg-gradient-to-r from-sky-500 via-blue-500 to-emerald-500 rounded-full"
                style={{ width: progressWidth }}
              >
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/40 to-transparent animate-pulse" />
              </motion.div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

// Composant pour la comète avec suivi réactif du tracé
const CometTail = ({ progress }: { progress: MotionValue<number> }) => {
  const offsetDistance = useTransform(progress, (v) => `${v}%`);

  return (
    <motion.circle
      r="7"
      fill="#FFFFFF"
      filter="url(#glow)"
      style={{
        offsetPath: `path('${RIBBON_PATH}')`,
        offsetDistance,
      }}
    />
  );
};

export default SplashScreen;