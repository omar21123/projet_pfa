import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Upload,
  X,
  ArrowLeft,
  ChevronRight,
  ChevronLeft,
  Camera,
  Tag,
  MapPin,
  Info,
  CheckCircle2,
  Layout,
  Loader2,
  ChevronDown,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link, useNavigate } from "react-router-dom";
import Navbar from "@/components/Navbar";
import { useLanguage } from "@/contexts/LanguageContext";
import axios from "axios";
import { cn } from "@/lib/utils";
import { annonceApi } from "@/api/annonce.api";
import { env } from "@/config/env";

interface CategoryNode {
  id: number;
  nom: string;
  children?: CategoryNode[];
}

interface PhotoItem {
  file: File;
  url: string;
  isMain: boolean;
}

type PublishStatus = "draft" | "published";

type ValidationKey =
  | "title"
  | "photos"
  | "city"
  | "condition"
  | "category"
  | "subcategory"
  | "description"
  | "price"
  | "submit";

interface ValidationState {
  [key: string]: string;
}

interface SubmitNotice {
  type: "success" | "error";
  message: string;
}

const cities = ["Casablanca", "Rabat", "Marrakech", "Fès", "Tanger", "Agadir"];

const PRODUCT_CONDITIONS = [
  { value: "new_with_tags", icon: "✨" },
  { value: "new_without_tags", icon: "🏷️" },
  { value: "very_good", icon: "🌟" },
  { value: "good", icon: "👍" },
  { value: "acceptable", icon: "🆗" },
  { value: "used", icon: "♻️" },
];

const ATTR_IDS = {
  brand: 1,
  size: 2,
  color: 3,
} as const;

const CATEGORY_ENDPOINT = `${env.apiUrl || "https://localhost:7111"}/api/Categorie/tree`;

const CreateAd = () => {
  const navigate = useNavigate();
  const { t: rawT } = useLanguage();
  const t = rawT as (key: string, options?: { defaultValue?: string }) => string;

  const [step, setStep] = useState(1);
  const [images, setImages] = useState<PhotoItem[]>([]);
  const [categoriesTree, setCategoriesTree] = useState<CategoryNode[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<CategoryNode | null>(null);
  const [selectedSubcategory, setSelectedSubcategory] = useState<CategoryNode | null>(null);
  const [subcategories, setSubcategories] = useState<CategoryNode[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [categoryLoading, setCategoryLoading] = useState(true);
  const [categoryError, setCategoryError] = useState<string | null>(null);
  const [formErrors, setFormErrors] = useState<ValidationState>({});
  const [submitNotice, setSubmitNotice] = useState<SubmitNotice | null>(null);

  const [title, setTitle] = useState("");
  const [brand, setBrand] = useState("");
  const [size, setSize] = useState("");
  const [city, setCity] = useState("");
  const [conditionValue, setConditionValue] = useState("");
  const [colorValue, setColorValue] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState<number | "">("");

  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    let isMounted = true;

    const loadCategories = async () => {
      try {
        setCategoryLoading(true);
        setCategoryError(null);
        const response = await axios.get<CategoryNode[]>(CATEGORY_ENDPOINT);

        if (!Array.isArray(response.data)) {
          throw new Error("La réponse de l'API catégories doit être un tableau.");
        }

        if (isMounted) {
          setCategoriesTree(response.data);
        }
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "Impossible de charger les catégories.";
        if (isMounted) {
          setCategoryError(message);
        }
      } finally {
        if (isMounted) {
          setCategoryLoading(false);
        }
      }
    };

    loadCategories();

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    setSubcategories(selectedCategory?.children ?? []);
    setSelectedSubcategory(null);
  }, [selectedCategory]);

  useEffect(() => {
    return () => {
      images.forEach((image) => URL.revokeObjectURL(image.url));
    };
  }, [images]);

  const setMainImage = (index: number) => {
    setImages((prev) =>
      prev.map((image, currentIndex) => ({ ...image, isMain: currentIndex === index })),
    );
  };

  const handleImageChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!event.target.files) return;

    const selectedFiles = Array.from(event.target.files);

    const newImageItems = selectedFiles.map((file) => ({
      file,
      url: URL.createObjectURL(file),
      isMain: false,
    }));

    setImages((prev) => {
      const merged = [...prev, ...newImageItems].slice(0, 6);
      if (merged.length > 0 && !merged.some((photo) => photo.isMain)) {
        merged[0].isMain = true;
      }
      return merged;
    });
  };

  const removeImage = (index: number) => {
    setImages((prev) => {
      const removed = prev[index];
      if (removed) {
        URL.revokeObjectURL(removed.url);
      }

      const next = prev.filter((_, currentIndex) => currentIndex !== index);
      if (next.length > 0 && !next.some((photo) => photo.isMain)) {
        next[0].isMain = true;
      }
      return next;
    });
  };

  const generateSlug = (text: string) => {
    const base = text
      .toLowerCase()
      .normalize("NFKD")
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-");

    const randomId = Math.random().toString(36).slice(2, 7);
    return `${base}-${randomId}`;
  };

  const getAttributePayload = () => {
    const attributes: { idAttribut: number; valeur: string }[] = [];

    if (brand.trim()) {
      attributes.push({ idAttribut: ATTR_IDS.brand, valeur: brand.trim() });
    }

    if (size.trim()) {
      attributes.push({ idAttribut: ATTR_IDS.size, valeur: size.trim() });
    }

    if (colorValue.trim()) {
      attributes.push({ idAttribut: ATTR_IDS.color, valeur: colorValue.trim() });
    }

    return attributes;
  };

  const setError = (key: ValidationKey, value: string) => {
    setFormErrors((prev) => ({ ...prev, [key]: value }));
  };

  const clearError = (key: ValidationKey) => {
    setFormErrors((prev) => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
  };

  const validateStep = (currentStep: number) => {
    const nextErrors: ValidationState = {};

    if (currentStep === 1) {
      if (images.length < 1) nextErrors.photos = t("photos_required");
      if (!title.trim() || title.trim().length < 10) {
        nextErrors.title = t("title_min", {
          defaultValue: "Le titre doit contenir au moins 10 caractères.",
        });
      } else if (title.trim().length > 100) {
        nextErrors.title = t("title_max", {
          defaultValue: "Le titre ne peut pas dépasser 100 caractères.",
        });
      }
    }

    if (currentStep === 2) {
      if (!city) nextErrors.city = t("city_required");
      if (!conditionValue) {
        nextErrors.condition = t("condition_required", {
          defaultValue: "L'état du produit est obligatoire.",
        });
      }
      if (!selectedCategory) {
        nextErrors.category = t("category_required", {
          defaultValue: "La catégorie est obligatoire.",
        });
      }
      if (!selectedSubcategory) {
        nextErrors.subcategory = t("subcategory_required", {
          defaultValue: "La sous-catégorie est obligatoire.",
        });
      }
    }

    if (currentStep === 3) {
      if (!description.trim() || description.trim().length < 50) {
        nextErrors.description = t("description_min");
      }

      if (!price || Number(price) <= 0) {
        nextErrors.price = t("price_positive", {
          defaultValue: "Le prix doit être supérieur à 0.",
        });
      }
    }

    setFormErrors((prev) => ({
      ...prev,
      ...nextErrors,
    }));

    return Object.keys(nextErrors).length === 0;
  };

  const validateAll = () => {
    const nextErrors: ValidationState = {};

    if (images.length < 1)
      nextErrors.photos = t("photos_required", { defaultValue: "Ajoutez au moins une photo." });
    if (!title.trim() || title.trim().length < 5) {
      nextErrors.title = t("title_min", {
        defaultValue: "Le titre doit contenir au moins 5 caractères.",
      });
    } else if (title.trim().length > 100) {
      nextErrors.title = t("title_max", {
        defaultValue: "Le titre ne peut pas dépasser 100 caractères.",
      });
    }
    if (!city) nextErrors.city = t("city_required", { defaultValue: "La ville est obligatoire." });
    if (!conditionValue) {
      nextErrors.condition = t("condition_required", {
        defaultValue: "L'état du produit est obligatoire.",
      });
    }
    if (!selectedCategory) {
      nextErrors.category = t("category_required", {
        defaultValue: "La catégorie est obligatoire.",
      });
    }
    if (!selectedSubcategory) {
      nextErrors.subcategory = t("subcategory_required", {
        defaultValue: "La sous-catégorie est obligatoire.",
      });
    }
    if (!description.trim() || description.trim().length < 10) {
      nextErrors.description = t("description_min", {
        defaultValue: "La description doit contenir au moins 10 caractères.",
      });
    }
    if (!price || Number(price) <= 0) {
      nextErrors.price = t("price_positive");
    }

    setFormErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const nextStep = () => {
    if (validateStep(step)) {
      setStep((currentStep) => Math.min(currentStep + 1, 4));
      setSubmitNotice(null);
    }
  };

  const prevStep = () => {
    setStep((currentStep) => Math.max(currentStep - 1, 1));
    setSubmitNotice(null);
  };

  const handleSubmit = async (status: PublishStatus) => {
    if (!validateAll()) {
      setStep(1);
      setSubmitNotice({
        type: "error",
        message: t("ad_create_error", {
          defaultValue: "Corrigez les erreurs du formulaire avant de continuer.",
        }),
      });
      return;
    }

    setSubmitting(true);
    setSubmitNotice(null);

    try {
      const response = await annonceApi.create({
        titre: title.trim(),
        description: description.trim(),
        prix: Number(price),
        idCategorie: selectedCategory!.id,
        idSousCategorie: selectedSubcategory!.id,
        localisationVille: city,
        etat: conditionValue,
        statut: status === "draft" ? "draft" : "published",
        Images: images.map((image) => image.file),
        Attributs: getAttributePayload(),
        slug: generateSlug(title),
      });

      const createdId = response.id ?? (response as { data?: { id?: number | string } }).data?.id;

      setSubmitNotice({
        type: "success",
        message: t("ad_created_success"),
      });

      window.setTimeout(() => {
        if (createdId !== undefined && createdId !== null) {
          navigate(`/ad/${createdId}`);
        } else {
          navigate("/");
        }
      }, 900);
    } catch (error) {
      console.error("Erreur création annonce:", error);
      setSubmitNotice({
        type: "error",
        message: t("ad_create_error"),
      });
    } finally {
      setSubmitting(false);
    }
  };

  const selectedCategoryId = selectedCategory?.id ?? "";
  const selectedSubcategoryId = selectedSubcategory?.id ?? "";

  const StepIndicator = () => (
    <div className="flex items-center justify-center mb-8 gap-4">
      {[1, 2, 3, 4].map((currentStep) => (
        <div key={currentStep} className="flex items-center">
          <div
            className={cn(
              "w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all duration-300",
              step >= currentStep
                ? "border-primary bg-primary text-white"
                : "border-muted bg-background text-muted-foreground",
            )}
          >
            {step > currentStep ? <CheckCircle2 className="h-5 w-5" /> : currentStep}
          </div>
          {currentStep < 4 && (
            <div
              className={cn("w-12 h-0.5 mx-2", step > currentStep ? "bg-primary" : "bg-muted")}
            />
          )}
        </div>
      ))}
    </div>
  );

  return (
    <div className="min-h-screen bg-[#F8F9FB] dark:bg-background pb-20">
      <Navbar />

      <div className="container max-w-3xl py-8">
        <Link
          to="/"
          className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-primary mb-8 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" /> {t("back")}
        </Link>

        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold tracking-tight mb-2">{t("create_ad_title")}</h1>
          <p className="text-muted-foreground">
            {t("fill_details_step", {
              defaultValue: "Remplissez les détails de votre annonce en plusieurs étapes.",
            })}
          </p>
        </div>

        <StepIndicator />

        {submitNotice && (
          <div
            className={cn(
              "mb-6 rounded-2xl border px-4 py-3 text-sm",
              submitNotice.type === "success"
                ? "border-green-200 bg-green-50 text-green-700"
                : "border-destructive/20 bg-destructive/10 text-destructive",
            )}
          >
            {submitNotice.message}
          </div>
        )}

        <div className="bg-card rounded-3xl border border-border/50 shadow-xl shadow-black/[0.03] overflow-hidden">
          <div className="p-8">
            <AnimatePresence mode="wait">
              {step === 1 && (
                <motion.div
                  key="step1"
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: -20, opacity: 0 }}
                  className="space-y-6"
                >
                  <div className="flex items-center gap-2 mb-4 text-primary">
                    <Camera className="h-5 w-5" />
                    <h2 className="font-semibold text-xl">
                      {t("photos_and_title", { defaultValue: "Photos et titre" })}
                    </h2>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    {images.map((image, index) => (
                      <motion.div
                        layout
                        key={`${image.url}-${index}`}
                        className="group relative aspect-square rounded-2xl overflow-hidden bg-muted border border-border"
                      >
                        <img
                          src={image.url}
                          alt={`Photo ${index + 1}`}
                          className="w-full h-full object-cover cursor-pointer"
                          onClick={() => setMainImage(index)}
                        />

                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                          <button
                            type="button"
                            onClick={() => removeImage(index)}
                            className="p-2 bg-destructive text-white rounded-full hover:scale-110 transition-transform"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>

                        {image.isMain && (
                          <span className="absolute bottom-2 left-2 px-2 py-1 bg-primary text-[10px] font-bold text-white rounded-md uppercase">
                            {t("main_photo", { defaultValue: "Principale" })}
                          </span>
                        )}
                      </motion.div>
                    ))}

                    {images.length < 6 && (
                      <button
                        type="button"
                        onClick={() => fileRef.current?.click()}
                        className="aspect-square rounded-2xl border-2 border-dashed border-muted-foreground/20 flex flex-col items-center justify-center gap-2 hover:border-primary/50 hover:bg-primary/5 transition-all group"
                      >
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center group-hover:scale-110 transition-transform">
                          <Upload className="h-5 w-5 text-primary" />
                        </div>
                        <span className="text-xs font-medium text-muted-foreground">
                          {t("add_photo")}
                        </span>
                      </button>
                    )}
                  </div>

                  {formErrors.photos && (
                    <p className="text-sm text-destructive">{formErrors.photos}</p>
                  )}

                  <div className="space-y-4 pt-4">
                    <div>
                      <label className="text-sm font-semibold mb-2 block">{t("title")}</label>
                      <input
                        value={title}
                        onChange={(event) => {
                          setTitle(event.target.value);
                          if (formErrors.title) {
                            clearError("title");
                          }
                        }}
                        placeholder={t("title_placeholder")}
                        className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border focus:ring-2 focus:ring-primary/20 outline-none transition-all"
                      />
                      <p className="text-[11px] text-muted-foreground mt-2 flex items-center gap-1">
                        <Info className="h-3 w-3" />
                        {t("title_min_info", {
                          defaultValue: "Le titre doit contenir entre 10 et 100 caractères.",
                        })}
                      </p>
                      {formErrors.title && (
                        <p className="text-xs text-destructive mt-1">{formErrors.title}</p>
                      )}
                    </div>
                  </div>
                </motion.div>
              )}

              {step === 2 && (
                <motion.div
                  key="step2"
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: -20, opacity: 0 }}
                  className="space-y-6"
                >
                  <div className="flex items-center gap-2 mb-4 text-primary">
                    <Tag className="h-5 w-5" />
                    <h2 className="font-semibold text-xl">
                      {t("category_details", { defaultValue: "Catégorie et détails" })}
                    </h2>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="text-sm font-semibold">{t("city")}</label>
                      <select
                        value={city}
                        onChange={(event) => {
                          setCity(event.target.value);
                          if (formErrors.city) {
                            clearError("city");
                          }
                        }}
                        className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none appearance-none"
                      >
                        <option value="">
                          {t("choose_city", { defaultValue: "Choisir une ville" })}
                        </option>
                        {cities.map((currentCity) => (
                          <option key={currentCity} value={currentCity}>
                            {currentCity}
                          </option>
                        ))}
                      </select>
                      {formErrors.city && (
                        <p className="text-xs text-destructive">{formErrors.city}</p>
                      )}
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-semibold">{t("marque")}</label>
                      <input
                        value={brand}
                        onChange={(event) => setBrand(event.target.value)}
                        placeholder={t("brand_placeholder", {
                          defaultValue: "Ex: Nike, Samsung...",
                        })}
                        className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <label className="text-sm font-semibold">
                        {t("size", { defaultValue: "Taille" })}
                      </label>
                      <input
                        type="text"
                        value={size}
                        onChange={(event) => setSize(event.target.value)}
                        placeholder={t("size_placeholder", { defaultValue: "Ex: M, 42, XL" })}
                        className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none"
                      />
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-semibold">{t("color")}</label>
                      <input
                        type="text"
                        value={colorValue}
                        onChange={(event) => setColorValue(event.target.value)}
                        placeholder={t("color_placeholder", { defaultValue: "Ex: black, blue..." })}
                        className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none"
                      />
                    </div>
                  </div>

                  <div className="space-y-3">
                    <label className="text-sm font-semibold">{t("condition")}</label>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                      {PRODUCT_CONDITIONS.map((condition) => (
                        <button
                          type="button"
                          key={condition.value}
                          onClick={() => {
                            setConditionValue(condition.value);
                            if (formErrors.condition) {
                              clearError("condition");
                            }
                          }}
                          className={cn(
                            "flex flex-col items-center justify-center p-3 rounded-xl border-2 transition-all",
                            conditionValue === condition.value
                              ? "border-primary bg-primary/5 text-primary"
                              : "border-border hover:border-primary/30",
                          )}
                        >
                          <span className="text-xl mb-1">{condition.icon}</span>
                          <span className="text-xs font-medium">
                            {t(`condition_${condition.value}`)}
                          </span>
                        </button>
                      ))}
                    </div>
                    {formErrors.condition && (
                      <p className="text-xs text-destructive">{formErrors.condition}</p>
                    )}
                  </div>

                  <div className="space-y-3 pt-4 border-t border-border/50">
                    <div className="flex items-center justify-between gap-3">
                      <label className="text-sm font-semibold">
                        {t("category", { defaultValue: "Catégorie" })}
                      </label>
                      {categoryLoading && (
                        <span className="inline-flex items-center gap-2 text-xs text-muted-foreground">
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          {t("loading", { defaultValue: "Chargement..." })}
                        </span>
                      )}
                    </div>

                    {categoryError && (
                      <div className="rounded-xl border border-destructive/20 bg-destructive/10 px-3 py-2 text-sm text-destructive">
                        {categoryError}
                      </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <label className="text-xs font-medium text-muted-foreground">
                          {t("category", { defaultValue: "Catégorie" })}
                        </label>
                        <div className="relative">
                          <select
                            value={selectedCategoryId}
                            onChange={(event) => {
                              const catId = Number(event.target.value);
                              const found = categoriesTree.find((c) => c.id === catId);
                              setSelectedCategory(found ?? null);
                              if (formErrors.category) {
                                clearError("category");
                              }
                            }}
                            className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none appearance-none"
                            disabled={categoryLoading || !!categoryError}
                          >
                            <option value="">
                              {t("choose_category", {
                                defaultValue: "Choisir une catégorie",
                              })}
                            </option>
                            {categoriesTree.map((cat) => (
                              <option key={cat.id} value={cat.id}>
                                {cat.nom}
                              </option>
                            ))}
                          </select>
                          <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        </div>
                        {formErrors.category && (
                          <p className="text-xs text-destructive">{formErrors.category}</p>
                        )}
                      </div>

                      <div className="space-y-2">
                        <label className="text-xs font-medium text-muted-foreground">
                          {t("subcategory", { defaultValue: "Sous-catégorie" })}
                        </label>
                        <div className="relative">
                          <select
                            value={selectedSubcategoryId}
                            onChange={(event) => {
                              const subId = Number(event.target.value);
                              const found = subcategories.find((s) => s.id === subId);
                              setSelectedSubcategory(found ?? null);
                              if (formErrors.subcategory) {
                                clearError("subcategory");
                              }
                            }}
                            className="w-full h-12 px-4 rounded-xl bg-muted/30 border border-border outline-none appearance-none"
                            disabled={!selectedCategory || subcategories.length === 0}
                          >
                            <option value="">
                              {t("choose_subcategory", {
                                defaultValue: "Choisir une sous-catégorie",
                              })}
                            </option>
                            {subcategories.map((sub) => (
                              <option key={sub.id} value={sub.id}>
                                {sub.nom}
                              </option>
                            ))}
                          </select>
                          <ChevronDown className="absolute right-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                        </div>
                        {formErrors.subcategory && (
                          <p className="text-xs text-destructive">{formErrors.subcategory}</p>
                        )}
                      </div>
                    </div>
                  </div>
                </motion.div>
              )}

              {step === 3 && (
                <motion.div
                  key="step3"
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: -20, opacity: 0 }}
                  className="space-y-6"
                >
                  <div className="flex items-center gap-2 mb-4 text-primary">
                    <Layout className="h-5 w-5" />
                    <h2 className="font-semibold text-xl">
                      {t("description_price", {
                        defaultValue: "Description et prix",
                      })}
                    </h2>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-semibold">{t("description")}</label>
                    <textarea
                      value={description}
                      onChange={(event) => {
                        setDescription(event.target.value);
                        if (formErrors.description) {
                          clearError("description");
                        }
                      }}
                      placeholder={t("description_placeholder")}
                      className="w-full h-32 p-4 rounded-xl bg-muted/30 border border-border outline-none resize-none"
                      rows={6}
                    />
                    <p className="text-[11px] text-muted-foreground flex items-center gap-1">
                      <Info className="h-3 w-3" />
                      {t("description_min_info", {
                        defaultValue: "La description doit contenir au moins 50 caractères.",
                      })}
                    </p>
                    {formErrors.description && (
                      <p className="text-xs text-destructive">{formErrors.description}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-semibold">{t("price")}</label>
                    <div className="relative">
                      <input
                        type="number"
                        value={price}
                        onChange={(event) => {
                          const nextPrice = event.target.value;
                          setPrice(nextPrice === "" ? "" : Number(nextPrice));
                          if (formErrors.price) {
                            clearError("price");
                          }
                        }}
                        placeholder="0.00"
                        className="w-full h-12 pl-4 pr-12 rounded-xl bg-muted/30 border border-border outline-none"
                      />
                      <span className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground font-semibold">
                        MAD
                      </span>
                    </div>
                    {formErrors.price && (
                      <p className="text-xs text-destructive">{formErrors.price}</p>
                    )}
                  </div>
                </motion.div>
              )}

              {step === 4 && (
                <motion.div
                  key="step4"
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: -20, opacity: 0 }}
                  className="text-center"
                >
                  <CheckCircle2 className="h-16 w-16 text-green-500 mx-auto mb-4" />
                  <h2 className="font-bold text-2xl mb-2">
                    {t("ad_ready", { defaultValue: "Votre annonce est prête !" })}
                  </h2>
                  <p className="text-muted-foreground mb-6">
                    {t("publish_or_draft", {
                      defaultValue:
                        "Vous pouvez la publier maintenant ou la sauvegarder comme brouillon.",
                    })}
                  </p>

                  <div className="flex justify-center gap-4">
                    <Button
                      onClick={() => handleSubmit("draft")}
                      variant="outline"
                      size="lg"
                      disabled={submitting}
                    >
                      {submitting ? <Loader2 className="h-5 w-5 animate-spin" /> : t("save_draft")}
                    </Button>
                    <Button
                      onClick={() => handleSubmit("published")}
                      size="lg"
                      disabled={submitting}
                    >
                      {submitting ? <Loader2 className="h-5 w-5 animate-spin" /> : t("publish_ad")}
                    </Button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          <div className="bg-muted/30 border-t border-border/50 px-8 py-4 flex justify-between items-center">
            <Button variant="ghost" onClick={prevStep} disabled={step === 1}>
              <ChevronLeft className="h-4 w-4 mr-2" />
              {t("previous")}
            </Button>

            {step < 4 ? (
              <Button onClick={nextStep}>
                {t("next")}
                <ChevronRight className="h-4 w-4 ml-2" />
              </Button>
            ) : (
              <div />
            )}
          </div>
        </div>
      </div>
      <input
        type="file"
        ref={fileRef}
        className="hidden"
        multiple
        accept="image/png, image/jpeg, image/webp"
        onChange={handleImageChange}
      />
    </div>
  );
};

export default CreateAd;
