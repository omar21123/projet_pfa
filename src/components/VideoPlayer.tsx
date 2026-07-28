import React from "react";
import { getMediaUrl } from "@/utils/mediaUtils";

interface VideoPlayerProps {
  src?: string | null | string[];
  className?: string;
}

export const VideoPlayer: React.FC<VideoPlayerProps> = ({
  src,
  className = "w-full rounded-2xl overflow-hidden bg-slate-950 shadow-inner",
}) => {
  let rawPath: string | null = null;

  if (Array.isArray(src) && src.length > 0) {
    rawPath = src[0];
  } else if (typeof src === "string") {
    try {
      const parsed = JSON.parse(src);
      rawPath = Array.isArray(parsed) ? parsed[0] : src;
    } catch {
      rawPath = src;
    }
  }

  if (!rawPath) {
    return (
      <div className="bg-slate-50 border border-slate-200 text-slate-400 p-6 rounded-2xl text-center text-xs font-medium">
        Aucune vidéo disponible pour ce produit.
      </div>
    );
  }

  const mediaUrl = getMediaUrl(rawPath);

  return (
    <div className={className}>
      <video
        key={mediaUrl}
        controls
        preload="metadata"
        className="w-full max-h-[360px] object-contain mx-auto"
      >
        <source src={mediaUrl} type="video/mp4" />
        <source src={mediaUrl} type="video/webm" />
        <source src={mediaUrl} type="video/ogg" />
        Votre navigateur ne prend pas en charge la lecture de vidéos.
      </video>
    </div>
  );
};
