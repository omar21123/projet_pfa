import { useState } from "react";
import { Video, Trash2, AlertCircle, UploadCloud, Image } from "lucide-react";
import type { FormState, ResourceItem } from "@/features/nouvelle-annonce/types";
import { SectionTitle } from "./shared";

const MAX_VIDEO_SIZE_MB = 50;
const ALLOWED_VIDEO_TYPES = ["video/mp4", "video/webm"];

const MAX_IMAGE_SIZE_MB = 5;
const ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MAX_IMAGES = 5;

interface StepMediasProps {
  form: FormState;
  setField: <K extends keyof FormState>(field: K, value: FormState[K]) => void;
}

export function StepMedias({ form, setField }: StepMediasProps) {
  const [error, setError] = useState<string | null>(null);

  const currentVideo = form.resources.find((r) => r.kind === "video");
  const images = form.resources.filter((r) => r.kind === "image");

  const handleVideoUpload = (file: File | null) => {
    if (!file) return;
    setError(null);

    if (!ALLOWED_VIDEO_TYPES.includes(file.type)) {
      setError("Format vidéo non pris en charge. Formats autorisés : MP4, WEBM.");
      return;
    }

    if (file.size > MAX_VIDEO_SIZE_MB * 1024 * 1024) {
      setError(`La vidéo dépasse la limite autorisée de ${MAX_VIDEO_SIZE_MB} Mo.`);
      return;
    }

    const newVideo: ResourceItem = {
      id: crypto.randomUUID(),
      kind: "video",
      role: 1,
      name: file.name,
      previewUrl: URL.createObjectURL(file),
      rawFile: file,
    };

    const otherResources = form.resources.filter((r) => r.kind !== "video");
    setField("resources", [...otherResources, newVideo]);
  };

  const handleRemoveVideo = () => {
    if (currentVideo?.previewUrl) {
      URL.revokeObjectURL(currentVideo.previewUrl);
    }
    setField(
      "resources",
      form.resources.filter((r) => r.kind !== "video")
    );
  };

  const handleImageUpload = (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setError(null);

    const remaining = MAX_IMAGES - images.length;
    if (remaining <= 0) {
      setError(`Vous ne pouvez pas ajouter plus de ${MAX_IMAGES} images.`);
      return;
    }

    const newImages: ResourceItem[] = [];
    const fileArray = Array.from(files).slice(0, remaining);

    for (const file of fileArray) {
      if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
        setError(`Format non pris en charge : ${file.name}. Formats autorisés : JPG, PNG, WEBP.`);
        continue;
      }
      if (file.size > MAX_IMAGE_SIZE_MB * 1024 * 1024) {
        setError(`${file.name} dépasse la limite de ${MAX_IMAGE_SIZE_MB} Mo.`);
        continue;
      }
      newImages.push({
        id: crypto.randomUUID(),
        kind: "image",
        role: 2,
        name: file.name,
        previewUrl: URL.createObjectURL(file),
        rawFile: file,
      });
    }

    if (newImages.length > 0) {
      setField("resources", [...form.resources.filter((r) => r.kind !== "image"), ...newImages]);
    }
  };

  const handleRemoveImage = (id: string) => {
    const target = form.resources.find((r) => r.id === id);
    if (target?.previewUrl) {
      URL.revokeObjectURL(target.previewUrl);
    }
    setField(
      "resources",
      form.resources.filter((r) => r.id !== id)
    );
  };

  return (
    <div className="space-y-8">
      {/* Section Images */}
      <div className="space-y-4">
        <SectionTitle
          title="Images du produit"
          subtitle={`Ajoutez jusqu'à ${MAX_IMAGES} images (JPG, PNG, WEBP, max ${MAX_IMAGE_SIZE_MB} Mo chacune).`}
        />

        {error && (
          <div className="p-3.5 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700 flex items-center gap-2">
            <AlertCircle className="size-4 shrink-0 text-red-600" />
            <span>{error}</span>
          </div>
        )}

        {images.length > 0 && (
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
            {images.map((img) => (
              <div
                key={img.id}
                className="relative group aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-50"
              >
                <img
                  src={img.previewUrl}
                  alt={img.name}
                  className="w-full h-full object-cover"
                />
                <button
                  type="button"
                  onClick={() => handleRemoveImage(img.id)}
                  className="absolute top-1 right-1 p-1.5 bg-white/80 hover:bg-red-500 hover:text-white rounded-full shadow-sm text-red-600 opacity-0 group-hover:opacity-100 transition-all"
                  title="Supprimer"
                >
                  <Trash2 className="size-3.5" />
                </button>
                <span className="absolute bottom-1 left-1 px-1.5 py-0.5 bg-black/60 text-white text-[10px] rounded truncate max-w-[90%]">
                  {img.name}
                </span>
              </div>
            ))}
            {images.length < MAX_IMAGES && (
              <label className="aspect-square flex flex-col items-center justify-center gap-1 border-2 border-dashed border-slate-300 hover:border-[#375260] rounded-lg cursor-pointer transition-colors bg-white">
                <UploadCloud className="size-6 text-slate-400" />
                <span className="text-[10px] text-slate-500 font-medium">Ajouter</span>
                <input
                  type="file"
                  accept={ALLOWED_IMAGE_TYPES.join(",")}
                  multiple
                  className="hidden"
                  onChange={(e) => handleImageUpload(e.target.files)}
                />
              </label>
            )}
          </div>
        )}

        {images.length === 0 && (
          <label className="flex flex-col items-center justify-center gap-3 border-2 border-dashed border-slate-300 hover:border-[#375260] rounded-xl py-10 text-center cursor-pointer transition-colors bg-white">
            <div className="p-3 bg-slate-100 rounded-full text-[#375260]">
              <Image className="size-8" />
            </div>
            <div>
              <span className="text-sm font-semibold text-slate-800 block">
                Glissez ou cliquez pour ajouter des images
              </span>
              <span className="text-xs text-slate-500 mt-1 block">
                {MAX_IMAGES} images max · JPG, PNG, WEBP (Max {MAX_IMAGE_SIZE_MB} Mo)
              </span>
            </div>
            <input
              type="file"
              accept={ALLOWED_IMAGE_TYPES.join(",")}
              multiple
              className="hidden"
              onChange={(e) => handleImageUpload(e.target.files)}
            />
          </label>
        )}
      </div>

      {/* Section Vidéo */}
      <div className="space-y-4">
        <SectionTitle
          title="Vidéo de validation"
          subtitle="Téléversez une vidéo courte de présentation du produit (max 50 Mo)."
        />

        {!currentVideo ? (
          <label className="flex flex-col items-center justify-center gap-3 border-2 border-dashed border-slate-300 hover:border-[#375260] rounded-xl py-12 text-center cursor-pointer transition-colors bg-white">
            <div className="p-3 bg-slate-100 rounded-full text-[#375260]">
              <UploadCloud className="size-8" />
            </div>
            <div>
              <span className="text-sm font-semibold text-slate-800 block">
                Glissez ou cliquez pour importer la vidéo
              </span>
              <span className="text-xs text-slate-500 mt-1 block">
                Formats acceptés : MP4, WEBM (Max 50 Mo)
              </span>
            </div>
            <input
              type="file"
              accept="video/mp4,video/webm"
              className="hidden"
              onChange={(e) => handleVideoUpload(e.target.files?.[0] || null)}
            />
          </label>
        ) : (
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-slate-800 font-semibold text-sm">
                <Video className="size-4 text-[#375260]" />
                <span>{currentVideo.name}</span>
              </div>
              <button
                type="button"
                onClick={handleRemoveVideo}
                className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors text-xs font-semibold flex items-center gap-1"
              >
                <Trash2 className="size-4" /> Supprimer
              </button>
            </div>

            <div className="aspect-video w-full max-w-xl mx-auto rounded-lg overflow-hidden bg-black shadow-md">
              <video src={currentVideo.previewUrl} controls className="w-full h-full object-contain" />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
