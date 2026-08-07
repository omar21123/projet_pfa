import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, ArrowRight, Check, CheckCircle2, Clock } from "lucide-react";
import { useCreateProduct } from "@/hooks/useProducts";
import axios from "axios";

import { STEPS } from "@/features/nouvelle-annonce/steps.config";
import { initialState, type FormState } from "@/features/nouvelle-annonce/types";
import { validateStep } from "@/features/nouvelle-annonce/validation";

import { StepInfos } from "@/features/nouvelle-annonce/components/StepInfos";
import { StepMedias } from "@/features/nouvelle-annonce/components/StepMedias";
import { StepCategories } from "@/features/nouvelle-annonce/components/StepCategories";
import { StepAttributes } from "@/features/nouvelle-annonce/components/StepAttributes";
import { StepCombinations } from "@/features/nouvelle-annonce/components/StepCombinations"; // NOUVELLE ÉTAPE
import { StepTagsPayment } from "@/features/nouvelle-annonce/components/StepTagsPayment";
import { StepRecap } from "@/features/nouvelle-annonce/components/StepRecap";

export default function NouvelleAnnoncePage() {
  const navigate = useNavigate();
  const [step, setStep] = useState<number>(1);
  const [form, setForm] = useState<FormState>(initialState);
  const [apiError, setApiError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState<boolean>(false);

  const { mutate, isPending } = useCreateProduct();

  useEffect(() => {
    document.title = "Nouveau produit — Espace vendeur";
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

    try {
      const formData = new FormData();

      // 1. Informations générales
      formData.append("Name", form.name || "");
      formData.append("Barcode", form.barcode || "");
      if (form.description) {
        formData.append("Description", form.description);
      }
      formData.append("BasePrice", String(parseFloat(form.basePrice) || 0));
      formData.append("Stock", String(parseInt(form.stock, 10) || 0));

      if (form.brandId) formData.append("BrandID", String(form.brandId));
      if (form.modelId) formData.append("ModelID", String(form.modelId));

      // 2. Tableaux d'identifiants simples
      (form.categories || []).forEach((catId, index) => {
        formData.append(`Categories[${index}]`, String(catId));
      });

      (form.allowedPayment || []).forEach((payId, index) => {
        formData.append(`AllowedPayment[${index}]`, String(payId));
      });

      (form.tags || []).forEach((tag, index) => {
        formData.append(`Tags[${index}]`, tag);
      });

      // 3. Ressources Média (type + Role)
      (form.resources || []).forEach((res, index) => {
        if (res.rawFile) {
          formData.append(`Ressource[${index}][file]`, res.rawFile);
          formData.append(`Ressource[${index}][type]`, res.kind); // 'type' au lieu de 'kind'
          formData.append(`Ressource[${index}][Role]`, String(res.role ?? 1)); // 'Role' majuscule
        }
      });

      // 4. Attributs (ConfigName + ConfigOptions)
      (form.attributes || []).forEach((attr, aIdx) => {
        formData.append(`Attribute[${aIdx}][ConfigName]`, attr.configName);
        (attr.options || []).forEach((opt, oIdx) => {
          formData.append(`Attribute[${aIdx}][ConfigOptions][${oIdx}][Name]`, opt.name);
          formData.append(
            `Attribute[${aIdx}][ConfigOptions][${oIdx}][IsDefault]`,
            opt.isDefault ? "1" : "0",
          );
        });
      });

      // 5. Combinaisons / Variantes (Price, Options, ConfigName, OptionName)
      (form.combinations || []).forEach((combo, cIdx) => {
        if (combo.sku) {
          formData.append(`Combinations[${cIdx}][SKU]`, combo.sku);
        }
        formData.append(
          `Combinations[${cIdx}][Price]`,
          String(parseFloat(combo.price) || parseFloat(form.basePrice) || 0),
        );

        formData.append(`Combinations[${cIdx}][Stock]`, String(parseInt(combo.stock, 10) || 0));
        formData.append(`Combinations[${cIdx}][IsDefault]`, combo.isDefault ? "1" : "0");

        if (combo.image instanceof File) {
          formData.append(`Combinations[${cIdx}][Image]`, combo.image);
        }

        (combo.options || []).forEach((opt, oIdx) => {
          formData.append(`Combinations[${cIdx}][Options][${oIdx}][ConfigName]`, opt.configName);
          formData.append(`Combinations[${cIdx}][Options][${oIdx}][OptionName]`, opt.optionName);
        });
      });

      // Envoi à l'API
      mutate(formData, {
        onSuccess: () => {
          setIsSuccess(true);
          setTimeout(() => navigate("/"), 5000);
        },
        onError: (err: unknown) => {
          if (axios.isAxiosError(err) && err.response?.data?.errors) {
            const allErrors = Object.values(err.response.data.errors).flat().join(" | ");
            setApiError(`Erreurs de validation : ${allErrors}`);
          } else if (axios.isAxiosError(err)) {
            setApiError(err.response?.data?.message || "Erreur lors de la création du produit.");
          } else {
            setApiError("Erreur lors de la création du produit.");
          }
        },
      });
    } catch (error) {
      setApiError("Une erreur est survenue lors de la préparation des données.");
    }
  };
  if (isSuccess) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center p-6">
        <div className="max-w-md w-full bg-white rounded-2xl p-8 text-center shadow-sm border border-slate-200 space-y-6">
          <div className="size-16 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mx-auto border border-emerald-100">
            <CheckCircle2 className="size-8" />
          </div>

          <div className="space-y-2">
            <h2 className="text-xl font-bold text-slate-900">Produit créé avec succès !</h2>
            <p className="text-sm text-slate-600 leading-relaxed">
              Le produit et ses variantes ont été soumis pour modération. Validation sous{" "}
              <strong>24h</strong>.
            </p>
          </div>

          <div className="p-3.5 bg-amber-50 rounded-xl border border-amber-200 flex items-center justify-center gap-2.5 text-xs text-amber-800 font-medium">
            <Clock className="size-4 shrink-0 text-amber-600" />
            <span>Redirection automatique dans 5 secondes...</span>
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

      {/* Stepper Navigation */}
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
                    ? "bg-[#375260] text-white ring-transparent"
                    : done
                      ? "bg-[#C7E545] text-[#0A0908]"
                      : "bg-white text-slate-600 ring-black/5"
                }`}
              >
                {s.label}
              </button>
              {s.id !== STEPS.length && <span className="w-6 h-px bg-slate-200" />}
            </li>
          );
        })}
      </ol>

      {/* Étape Courante */}
      <div className="rounded-2xl bg-white ring-1 ring-black/5 p-6 md:p-8">
        {step === 1 && <StepInfos form={form} setField={setField} />}
        {step === 2 && <StepMedias form={form} setField={setField} />}
        {step === 3 && <StepCategories form={form} setField={setField} />}
        {step === 4 && <StepAttributes form={form} setField={setField} />}
        {step === 5 && <StepCombinations form={form} setField={setField} />}
        {step === 6 && <StepTagsPayment form={form} setField={setField} />}
        {step === 7 && <StepRecap form={form} />}

        {stepErrors.length > 0 && step !== 7 && (
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
          className="inline-flex items-center gap-2 h-11 px-4 rounded-lg text-sm font-semibold hover:bg-slate-100 disabled:opacity-40"
        >
          <ArrowLeft className="size-4" /> Retour
        </button>

        {step < STEPS.length ? (
          <button
            type="button"
            onClick={goNext}
            disabled={!canNext}
            className="inline-flex items-center gap-2 h-11 px-5 rounded-lg bg-[#375260] text-white text-sm font-semibold disabled:opacity-40"
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
