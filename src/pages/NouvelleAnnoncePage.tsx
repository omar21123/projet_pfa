import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, ArrowRight, Check, CheckCircle2, Clock } from "lucide-react";
import { type CreateProductPayload } from "@/api/product";
import { useCreateProduct } from "@/hooks/useProducts";

import { STEPS } from "@/features/nouvelle-annonce/steps.config";
import { initialState, type FormState } from "@/types/types";
import { validateStep } from "@/features/nouvelle-annonce/validation";

import { StepInfos } from "@/features/nouvelle-annonce/components/StepInfos";
import { StepMedias } from "@/features/nouvelle-annonce/components/StepMedias";
import { StepCategories } from "@/features/nouvelle-annonce/components/StepCategories";
import { StepAttributes } from "@/features/nouvelle-annonce/components/StepAttributes";
import { StepTagsPayment } from "@/features/nouvelle-annonce/components/StepTagsPayment";
import { StepRecap } from "@/features/nouvelle-annonce/components/StepRecap";

export default function NouvelleAnnoncePage() {
  const navigate = useNavigate();
  const [step, setStep] = useState<number>(1);
  const [form, setForm] = useState<FormState>(initialState);
  const [apiError, setApiError] = useState<string | null>(null);

  // État de succès pour afficher l'écran de confirmation
  const [isSuccess, setIsSuccess] = useState<boolean>(false);

  const { mutate, isPending } = useCreateProduct();

  useEffect(() => {
    document.title = "Nouvelle annonce — Espace vendeur";
  }, []);

  const setField = <K extends keyof FormState>(key: K, value: FormState[K]) =>
    setForm((f) => ({ ...f, [key]: value }));

  const stepErrors = useMemo(() => validateStep(step, form), [step, form]);
  const canNext = stepErrors.length === 0;

  const goNext = () => {
    if (!canNext) return;
    setApiError(null);
    setStep((s) => Math.min(STEPS.length, s + 1));
  };

  const goPrev = () => {
    setApiError(null);
    setStep((s) => Math.max(1, s - 1));
  };

  const submitForm = () => {
    setApiError(null);

    const payload: CreateProductPayload = {
      name: form.name,
      barcode: form.barcode,
      description: form.description,
      basePrice: form.basePrice,
      stock: form.stock,
      brandId: form.brandId,
      modelId: form.modelId,
      categories: form.categories,
      tags: form.tags,
      allowedPayment: form.allowedPayment,
      resources: form.resources.map((r) => ({
        rawFile: r.rawFile,
        kind: r.kind,
        role: r.role,
      })),
      attributes: form.attributes.map((a) => ({
        configName: a.configName,
        options: [{ name: a.optionName, isDefault: true }],
      })),
    };

    mutate(payload, {
      onSuccess: () => {
        setIsSuccess(true);
        // Redirection automatique vers l'accueil au bout de 5 secondes
        setTimeout(() => {
          navigate("/");
        }, 5000);
      },
      onError: (err: any) => {
        if (err.response?.data?.errors) {
          const allErrors = Object.values(err.response.data.errors).flat().join(" | ");
          setApiError(`Erreurs de validation : ${allErrors}`);
        } else {
          setApiError(err.response?.data?.message || "Erreur de communication avec le serveur.");
        }
      },
    });
  };

  // ============================================================
  // ÉCRAN DE SUCCÈS APPRÈS SOUMISSION
  // ============================================================
  if (isSuccess) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center p-6">
        <div className="max-w-md w-full bg-white rounded-2xl p-8 text-center shadow-sm border border-slate-200/80 space-y-6">
          <div className="size-16 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mx-auto border border-emerald-100">
            <CheckCircle2 className="size-8" />
          </div>

          <div className="space-y-2">
            <h2 className="text-xl font-bold text-slate-900">Produit ajouté avec succès !</h2>
            <p className="text-sm text-slate-600 leading-relaxed">
              Vous avez ajouté le produit avec succès. La validation sera effectuée sous{" "}
              <strong>24 heures</strong>. Veuillez patienter pendant la modération.
            </p>
          </div>

          <div className="p-3.5 bg-amber-50/80 rounded-xl border border-amber-200/60 flex items-center justify-center gap-2.5 text-xs text-amber-800 font-medium">
            <Clock className="size-4 shrink-0 text-amber-600" />
            <span>Redirection automatique dans quelques secondes...</span>
          </div>

          <button
            type="button"
            onClick={() => navigate("/")}
            className="w-full h-11 bg-[#375260] text-white font-semibold rounded-lg hover:bg-[#2c424e] transition-colors text-sm"
          >
            Retourner à l'accueil
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6">
      <header className="flex items-start justify-between gap-4">
        <h1 className="text-2xl font-extrabold tracking-tight text-[#0A0908]">
          Créer un nouveau produit
        </h1>
      </header>

      {/* Stepper */}
      <ol className="flex items-center gap-2 overflow-x-auto pb-1">
        {STEPS.map((s) => {
          const done = step > s.id;
          const active = step === s.id;
          return (
            <li key={s.id} className="flex items-center gap-2 shrink-0">
              <button
                type="button"
                onClick={() => (done ? setStep(s.id) : undefined)}
                className={`flex items-center gap-2 px-3.5 h-10 rounded-full text-sm font-medium ring-1 transition-all ${
                  active
                    ? "bg-[#375260] text-cream ring-transparent"
                    : done
                      ? "bg-[#C7E545] text-[#0A0908]"
                      : "bg-white text-ink/60 ring-black/5"
                }`}
              >
                {s.label}
              </button>
              {s.id !== STEPS.length && <span className="w-6 h-px bg-ink/10" />}
            </li>
          );
        })}
      </ol>

      {/* Conteneur d'étapes */}
      <div className="rounded-2xl bg-white ring-1 ring-black/5 p-6 md:p-8">
        {step === 1 && <StepInfos form={form} setField={setField} />}
        {step === 2 && <StepMedias form={form} setField={setField} />}
        {step === 3 && <StepCategories form={form} setField={setField} />}
        {step === 4 && <StepAttributes form={form} setField={setField} />}
        {step === 5 && <StepTagsPayment form={form} setField={setField} />}
        {step === 6 && <StepRecap form={form} />}

        {stepErrors.length > 0 && step !== 6 && (
          <div className="mt-6 rounded-lg bg-red-50 text-red-700 text-sm px-4 py-3 ring-1 ring-red-100">
            <ul className="list-disc pl-5">
              {stepErrors.map((e) => (
                <li key={e}>{e}</li>
              ))}
            </ul>
          </div>
        )}

        {apiError && (
          <div className="mt-6 rounded-lg bg-amber-50 text-amber-900 font-medium text-sm px-4 py-3 ring-1 ring-amber-200">
            {apiError}
          </div>
        )}
      </div>

      {/* Contrôles de Navigation */}
      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={goPrev}
          disabled={step === 1 || isPending}
          className="inline-flex items-center gap-2 h-11 px-4 rounded-lg text-sm font-semibold hover:bg-ink/5 disabled:opacity-40"
        >
          <ArrowLeft className="size-4" /> Retour
        </button>

        {step < STEPS.length ? (
          <button
            type="button"
            onClick={goNext}
            disabled={!canNext}
            className="inline-flex items-center gap-2 h-11 px-5 rounded-lg bg-[#375260] text-cream text-sm font-semibold disabled:opacity-40"
          >
            Continuer <ArrowRight className="size-4" />
          </button>
        ) : (
          <button
            type="button"
            onClick={submitForm}
            disabled={isPending}
            className="inline-flex items-center gap-2 h-11 px-5 rounded-lg bg-[#C7E545] text-[#0A0908] text-sm font-semibold hover:brightness-95 disabled:opacity-60"
          >
            {isPending ? "Envoi des données..." : "Soumettre pour modération"}
            <Check className="size-4" />
          </button>
        )}
      </div>
    </div>
  );
}
