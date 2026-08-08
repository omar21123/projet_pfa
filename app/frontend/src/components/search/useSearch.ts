// src/hooks/useSearch.ts
import { useState, useEffect, useRef, useCallback } from "react";
import {
  fetchSearchSuggestions,
  fetchSearchHistory,
} from "../search/searchApi";
import type {
  SuggestionItem,
  SearchHistoryData,
} from "../search/searchApi";

export function useSearch(onSearchSubmit?: (query: string) => void) {
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<SuggestionItem[]>([]);
  const [history, setHistory] = useState<SearchHistoryData>({ latest: [], famous: [] });
  const [isLoading, setIsLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);

  const containerRef = useRef<HTMLDivElement | null>(null);

  // Charger l'historique (récents + populaires)
  const loadHistory = useCallback(async () => {
    try {
      const data = await fetchSearchHistory();
      setHistory(data);
    } catch {
      // Ignorer silencieusement si non connecté ou erreur réseau
      setHistory({ latest: [], famous: [] });
    }
  }, []);

  // Détection de saisie avec Debounce & AbortController
  useEffect(() => {
    const trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      setSuggestions([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    const controller = new AbortController();

    const timer = setTimeout(async () => {
      try {
        const results = await fetchSearchSuggestions(trimmedQuery, 8, controller.signal);
        setSuggestions(results);
      } catch (err: unknown) {
        if (err instanceof Error && err.name !== "AbortError") {
          setSuggestions([]);
        }
      } finally {
        setIsLoading(false);
      }
    }, 280); // Debounce de 280ms

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [query]);

  // Fermer le dropdown lors d'un clic à l'extérieur
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleFocus = () => {
    setIsOpen(true);
    if (query.trim().length < 2) {
      loadHistory();
    }
  };

  const handleSelectTerm = (selectedText: string) => {
    setQuery(selectedText);
    setIsOpen(false);
    if (onSearchSubmit) {
      onSearchSubmit(selectedText);
    }
  };

  const clearQuery = () => {
    setQuery("");
    setSuggestions([]);
    if (isOpen) {
      loadHistory();
    }
  };

  return {
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
  };
}
