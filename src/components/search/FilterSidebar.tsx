import { memo, useCallback, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, SlidersHorizontal, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { format } from "date-fns";
import { fr } from "date-fns/locale";
import { CalendarIcon } from "lucide-react";
import { cn } from "@/lib/utils";
import { useLanguage } from "@/contexts/LanguageContext";

export interface Filters {
  priceRange: [number, number];
  categories: string[];
  cities: string[];
  dateFrom?: Date;
  dateTo?: Date;
}

const categories = [
  "Électronique",
  "Immobilier",
  "Véhicules",
  "Mobilier",
  "Mode",
  "Sports",
  "Services",
  "Autres",
];
const cities = ["Casablanca", "Rabat", "Marrakech", "Fès", "Tanger", "Agadir", "Meknès", "Oujda"];

interface FilterSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  filters: Filters;
  onFiltersChange: (filters: Filters) => void;
  onApply?: () => void;
  onReset?: () => void;
  activeFilterCount: number;
}

const sidebarVariants = {
  hidden: { x: "-100%", opacity: 0 },
  visible: {
    x: 0,
    opacity: 1,
    transition: { type: "spring" as const, stiffness: 300, damping: 30 },
  },
  exit: { x: "-100%", opacity: 0, transition: { duration: 0.25, ease: "easeIn" as const } },
};
const overlayVariants = { hidden: { opacity: 0 }, visible: { opacity: 1 }, exit: { opacity: 0 } };
const itemVariants = {
  hidden: { opacity: 0, x: -20 },
  visible: (i: number) => ({ opacity: 1, x: 0, transition: { delay: i * 0.08, duration: 0.3 } }),
};

const FilterSidebar = ({
  isOpen,
  onClose,
  filters,
  onFiltersChange,
  onApply,
  onReset,
  activeFilterCount,
}: FilterSidebarProps) => {
  const { t } = useLanguage();
  const presets = useMemo(() => [5000, 20000, 100000, 500000], []);

  const handlePriceChange = useCallback(
    (value: number[]) => {
      onFiltersChange({ ...filters, priceRange: [value[0], value[1]] as [number, number] });
    },
    [filters, onFiltersChange],
  );

  const toggleCategory = useCallback(
    (cat: string) => {
      const updated = filters.categories.includes(cat)
        ? filters.categories.filter((c) => c !== cat)
        : [...filters.categories, cat];
      onFiltersChange({ ...filters, categories: updated });
    },
    [filters, onFiltersChange],
  );

  const toggleCity = useCallback(
    (city: string) => {
      const updated = filters.cities.includes(city)
        ? filters.cities.filter((c) => c !== city)
        : [...filters.cities, city];
      onFiltersChange({ ...filters, cities: updated });
      if (onApply) onApply();
    },
    [filters, onFiltersChange, onApply],
  );

  const resetFilters = useCallback(() => {
    onFiltersChange({
      priceRange: [0, 1000000],
      categories: [],
      cities: [],
      dateFrom: undefined,
      dateTo: undefined,
    });
  }, [onFiltersChange]);

  const formatPrice = (v: number) =>
    v >= 1000000
      ? `${(v / 1000000).toFixed(1)}M`
      : v >= 1000
        ? `${(v / 1000).toFixed(0)}K`
        : `${v}`;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 lg:hidden"
            variants={overlayVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
            onClick={onClose}
          />
          <motion.aside
            className="fixed top-0 left-0 h-full w-80 bg-card border-r border-border z-50 overflow-y-auto shadow-xl lg:sticky lg:top-0 lg:z-10 lg:shadow-none"
            variants={sidebarVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
          >
            <div className="sticky top-0 bg-card/95 backdrop-blur-sm border-b border-border p-4 flex items-center justify-between z-10">
              <div className="flex items-center gap-2">
                <SlidersHorizontal className="h-5 w-5 text-primary" />
                <h3 className="font-heading font-bold text-lg">{t("filters")}</h3>
                {activeFilterCount > 0 && (
                  <Badge variant="default" className="text-xs px-2 py-0.5">
                    {activeFilterCount}
                  </Badge>
                )}
              </div>
              <div className="flex items-center gap-1">
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => {
                    resetFilters();
                    if (onReset) onReset();
                  }}
                  className="h-8 w-8 text-muted-foreground hover:text-foreground"
                  title={t("reset")}
                >
                  <RotateCcw className="h-4 w-4" />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={onClose}
                  className="h-8 w-8 text-muted-foreground hover:text-foreground"
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            </div>

            <div className="p-4 space-y-6">
              <motion.div custom={0} variants={itemVariants} initial="hidden" animate="visible">
                <Label className="text-sm font-semibold mb-3 block">{t("budget")}</Label>
                <div className="flex items-center justify-between text-xs text-muted-foreground mb-2">
                  <span>{formatPrice(filters.priceRange[0])} DH</span>
                  <span>{formatPrice(filters.priceRange[1])} DH</span>
                </div>
                <Slider
                  value={filters.priceRange}
                  onValueChange={handlePriceChange}
                  min={0}
                  max={1000000}
                  step={1000}
                  className="mt-1"
                />
                <div className="flex gap-2 mt-3">
                  {presets.map((preset) => (
                    <motion.button
                      key={preset}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => onFiltersChange({ ...filters, priceRange: [0, preset] })}
                      className={cn(
                        "text-xs px-2 py-1 rounded-full border border-border transition-colors",
                        filters.priceRange[1] === preset
                          ? "bg-primary text-primary-foreground border-primary"
                          : "hover:border-primary/50",
                      )}
                    >
                      {formatPrice(preset)}
                    </motion.button>
                  ))}
                </div>
              </motion.div>

              <Separator />

              <motion.div custom={1} variants={itemVariants} initial="hidden" animate="visible">
                <Label className="text-sm font-semibold mb-3 block">{t("categories")}</Label>
                <div className="space-y-2">
                  {categories.map((cat) => (
                    <motion.label
                      key={cat}
                      className="flex items-center gap-2 cursor-pointer group"
                      whileHover={{ x: 4 }}
                      transition={{ type: "spring", stiffness: 400 }}
                    >
                      <Checkbox
                        checked={filters.categories.includes(cat)}
                        onCheckedChange={() => toggleCategory(cat)}
                      />
                      <span className="text-sm group-hover:text-primary transition-colors">
                        {cat}
                      </span>
                    </motion.label>
                  ))}
                </div>
              </motion.div>

              <Separator />

              <motion.div custom={2} variants={itemVariants} initial="hidden" animate="visible">
                <Label className="text-sm font-semibold mb-3 block">{t("cities")}</Label>
                <div className="flex flex-wrap gap-2">
                  {cities.map((city) => (
                    <motion.button
                      key={city}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => toggleCity(city)}
                      className={cn(
                        "text-xs px-3 py-1.5 rounded-full border transition-all",
                        filters.cities.includes(city)
                          ? "bg-primary text-primary-foreground border-primary shadow-sm"
                          : "border-border hover:border-primary/50 hover:bg-accent",
                      )}
                    >
                      {city}
                    </motion.button>
                  ))}
                </div>
              </motion.div>

              <Separator />

              <motion.div custom={3} variants={itemVariants} initial="hidden" animate="visible">
                <Label className="text-sm font-semibold mb-3 block">{t("period")}</Label>
                <div className="space-y-2">
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "w-full justify-start text-left text-sm font-normal",
                          !filters.dateFrom && "text-muted-foreground",
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateFrom
                          ? format(filters.dateFrom, "dd MMM yyyy", { locale: fr })
                          : t("start_date")}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={filters.dateFrom}
                        onSelect={(d) => onFiltersChange({ ...filters, dateFrom: d })}
                        initialFocus
                        className="p-3 pointer-events-auto"
                      />
                    </PopoverContent>
                  </Popover>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        className={cn(
                          "w-full justify-start text-left text-sm font-normal",
                          !filters.dateTo && "text-muted-foreground",
                        )}
                      >
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {filters.dateTo
                          ? format(filters.dateTo, "dd MMM yyyy", { locale: fr })
                          : t("end_date")}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={filters.dateTo}
                        onSelect={(d) => onFiltersChange({ ...filters, dateTo: d })}
                        initialFocus
                        className="p-3 pointer-events-auto"
                      />
                    </PopoverContent>
                  </Popover>
                </div>
              </motion.div>

              <Separator />

              <motion.div custom={4} variants={itemVariants} initial="hidden" animate="visible">
                <Button
                  onClick={() => {
                    if (onApply) onApply();
                    onClose();
                  }}
                  className="w-full font-semibold"
                >
                  {t("apply_filters")}
                </Button>
              </motion.div>
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
};

export default memo(FilterSidebar);
