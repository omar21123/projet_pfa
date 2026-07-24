import { CheckCircle2, Circle, ImagePlus, Trash2 } from "lucide-react";
import type { FormState, ResourceItem } from "@/types/types";
import { SectionTitle } from "./shared";

export function StepMedias({ form, setField }: { form: FormState; setField: any }) {
  const hasImage = form.resources.some((r) => r.kind === "image");
  const hasVideo = form.resources.some((r) => r.kind === "video");

  const onFiles = (files: FileList | null) => {
    if (!files) return;
    const next: ResourceItem[] = Array.from(files).map((f) => {
      const isVideo = f.type.startsWith("video");

      return {
        id: crypto.randomUUID(),
        kind: isVideo ? "video" : "image",
        role: isVideo ? 1 : 2, // Vidéo = Rôle 1, Image = Rôle 2
        name: f.name,
        previewUrl: URL.createObjectURL(f),
        rawFile: f,
      };
    });
    setField("resources", [...form.resources, ...next]);
  };

  const handleRemoveFile = (itemToRemove: ResourceItem) => {
    URL.revokeObjectURL(itemToRemove.previewUrl);
    setField("resources", form.resources.filter((x) => x.id !== itemToRemove.id));
  };

  return (
    <div className="space-y-6">
      <SectionTitle title="Photos & vidéos" subtitle="Fichiers de présentation du produit." />

      {/* Checklist visuelle de validation */}
      <div className="flex flex-wrap gap-3 rounded-xl bg-slate-50 ring-1 ring-black/5 p-4">
        <RequirementBadge ok={hasImage} label="Au moins 1 image" />
        <RequirementBadge ok={hasVideo} label="1 vidéo de validation" />
      </div>

      <label className="flex flex-col items-center justify-center gap-2 border-2 border-dashed border-ink/15 rounded-xl py-10 text-center cursor-pointer hover:bg-ink/[0.01]">
        <ImagePlus className="size-8 text-[#375260]" />
        <span className="text-sm font-medium">Glisser ou uploader des fichiers</span>
        <span className="text-xs text-ink/50">
          Format accepté : Images et vidéo de validation (.mp4, .webm)
        </span>
        <input
          type="file"
          multiple
          accept="image/*,video/*"
          className="hidden"
          onChange={(e) => onFiles(e.target.files)}
        />
      </label>

      {form.resources.length > 0 && (
        <div className="grid gap-4 grid-cols-2 md:grid-cols-4">
          {form.resources.map((r) => (
            <div
              key={r.id}
              className="relative rounded-xl overflow-hidden border bg-slate-50 p-2 flex flex-col justify-between"
            >
              <div className="w-full aspect-square bg-black/5 rounded-lg overflow-hidden flex items-center justify-center">
                {r.kind === "video" ? (
                  <video
                    src={r.previewUrl}
                    muted
                    playsInline
                    className="w-full h-full object-cover"
                    onMouseEnter={(e) => e.currentTarget.play()}
                    onMouseLeave={(e) => {
                      e.currentTarget.pause();
                      e.currentTarget.currentTime = 0;
                    }}
                  />
                ) : (
                  <img src={r.previewUrl} alt={r.name} className="w-full h-full object-cover" />
                )}
              </div>

              <div className="mt-2">
                <select
                  value={r.role}
                  onChange={(e) => {
                    const updated = form.resources.map((item) =>
                      item.id === r.id ? { ...item, role: Number(e.target.value) } : item
                    );
                    setField("resources", updated);
                  }}
                  className="w-full text-xs p-1 border rounded bg-white focus:outline-none focus:ring-1 focus:ring-[#375260]"
                >
                  <option value={1}>Vidéo (Rôle 1)</option>
                  <option value={2}>Image (Rôle 2)</option>
                </select>
              </div>

              <button
                type="button"
                onClick={() => handleRemoveFile(r)}
                className="absolute top-4 right-4 bg-red-600 text-white p-1.5 rounded-full shadow hover:bg-red-700 transition-colors"
                title="Supprimer ce fichier"
              >
                <Trash2 className="size-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function RequirementBadge({ ok, label }: { ok: boolean; label: string }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ${
        ok ? "bg-[#C7E545]/60 text-[#0A0908]" : "bg-white text-ink/50 ring-1 ring-black/10"
      }`}
    >
      {ok ? <CheckCircle2 className="size-3.5" /> : <Circle className="size-3.5" />}
      {label}
    </span>
  );
}