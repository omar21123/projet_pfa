import { useState } from "react";
import { ChevronDown, History, Loader2, Search, TrendingUp, X } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useLanguage } from "@/contexts/LanguageContext";
import { useSearch } from "@/components/search/useSearch";

type SearchType = "ads" | "members" | "all";

export default function SearchBar() {
  const navigate = useNavigate();
  const { t } = useLanguage();
  const [searchType, setSearchType] = useState<SearchType>("all");

  const executeSearch = (searchTerm: string) => {
    const normalizedTerm = searchTerm.trim();
    if (!normalizedTerm) return;

    const params = new URLSearchParams({ q: normalizedTerm });
    if (searchType !== "all") params.set("type", searchType);
    // Les résultats sont affichés dans les sections de la page d'accueil.
    navigate(`/?${params.toString()}`);
  };

  const {
    query,
    setQuery,
    suggestions,
    history,
    isLoading,
    isOpen,
    setIsOpen,
    containerRef,
    handleFocus,
    handleSelectTerm,
    clearQuery,
  } = useSearch(executeSearch);

  const searchPlaceholder =
    searchType === "members"
      ? t("search_members_placeholder")
      : searchType === "ads"
        ? t("search_ads_placeholder")
        : "Rechercher un produit...";

  const highlightMatch = (text: string, match: string) => {
    if (!match.trim()) return text;
    const parts = text.split(new RegExp(`(${match.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "gi"));
    return parts.map((part, index) =>
      part.toLowerCase() === match.toLowerCase() ? (
        <span key={index} className="font-bold text-teal">{part}</span>
      ) : part,
    );
  };

  return (
    <div ref={containerRef} className="hidden md:block relative flex-1 min-w-[260px] max-w-2xl">
      <form
        onSubmit={(event) => {
          event.preventDefault();
          setIsOpen(false);
          executeSearch(query);
        }}
        className="flex h-9 border border-border rounded-lg overflow-hidden bg-surface shadow-sm focus-within:ring-1 focus-within:ring-teal transition-all"
      >
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button type="button" className="px-3 bg-cream text-xs font-medium text-foreground border-r border-border/60 hover:bg-muted transition-colors flex items-center gap-1 shrink-0 focus:outline-none">
              <span className="truncate max-w-[110px]">
                {searchType === "members" ? t("search_type_members") : searchType === "ads" ? t("search_type_ads") : "Toutes catégories"}
              </span>
              <ChevronDown className="h-3 w-3 text-muted-foreground shrink-0" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="start" className="w-44 z-50">
            <DropdownMenuItem onClick={() => setSearchType("all")}>Toutes catégories</DropdownMenuItem>
            <DropdownMenuItem onClick={() => setSearchType("ads")}>{t("search_type_ads")}</DropdownMenuItem>
            <DropdownMenuItem onClick={() => setSearchType("members")}>{t("search_type_members")}</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        <div className="relative flex-1 bg-surface min-w-0 flex items-center">
          <input
            type="text"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onFocus={handleFocus}
            placeholder={searchPlaceholder}
            aria-label={searchPlaceholder}
            className="w-full h-full pl-3 pr-8 text-xs bg-transparent outline-none text-foreground placeholder:text-muted-foreground/60 truncate"
          />
          {isLoading ? (
            <Loader2 className="absolute right-2.5 h-3.5 w-3.5 animate-spin text-muted-foreground" />
          ) : query ? (
            <button type="button" onClick={clearQuery} className="absolute right-2.5 p-0.5 hover:bg-muted rounded-full text-muted-foreground hover:text-foreground transition-colors" aria-label="Effacer la recherche">
              <X className="h-3.5 w-3.5" />
            </button>
          ) : null}
        </div>

        <button type="submit" className="bg-teal hover:bg-teal-dark text-cream px-4 text-xs font-semibold transition-colors flex items-center gap-1.5 shrink-0">
          <Search className="h-3.5 w-3.5 shrink-0" />
          <span className="hidden lg:inline">Rechercher</span>
        </button>
      </form>

      {isOpen && (
        <div className="absolute left-0 right-0 top-full mt-1.5 bg-background border border-border rounded-xl shadow-xl overflow-hidden z-50 text-xs animate-in fade-in duration-150">
          {query.trim().length >= 2 ? (
            <div className="py-2">
              <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Suggestions</div>
              {suggestions.length > 0 ? suggestions.map((item, index) => (
                <button key={index} type="button" onClick={() => handleSelectTerm(item.text)} className="w-full text-left px-3 py-2 text-foreground hover:bg-muted flex items-center gap-2.5 transition-colors">
                  <Search className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
                  <span className="truncate">{highlightMatch(item.text, query)}</span>
                </button>
              )) : !isLoading ? <div className="px-3 py-3 text-muted-foreground text-center">Aucune suggestion pour « {query} »</div> : null}
            </div>
          ) : (
            <div className="py-2 divide-y divide-border">
              {history.latest?.length > 0 && (
                <div className="py-1.5">
                  <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1"><History className="h-3 w-3" /> Recherches récentes</div>
                  {history.latest.map((item, index) => <button key={index} type="button" onClick={() => handleSelectTerm(item.text)} className="w-full text-left px-3 py-1.5 text-foreground hover:bg-muted flex items-center justify-between transition-colors"><span className="truncate">{item.text}</span><span className="text-[10px] text-muted-foreground/70">Récent</span></button>)}
                </div>
              )}
              {history.famous?.length > 0 && (
                <div className="py-1.5">
                  <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1"><TrendingUp className="h-3 w-3 text-promo" /> Tendances</div>
                  <div className="flex flex-wrap gap-1 px-3 pt-1">{history.famous.map((item, index) => <button key={index} type="button" onClick={() => handleSelectTerm(item.text)} className="px-2.5 py-1 bg-muted hover:bg-teal/10 hover:text-teal text-foreground rounded-md text-[11px] font-medium transition-colors">{item.text}</button>)}</div>
                </div>
              )}
              {!history.latest?.length && !history.famous?.length && <div className="px-3 py-3 text-muted-foreground text-center">Saisissez au moins 2 caractères pour rechercher...</div>}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
