<?php

namespace App\DTOs\Search;

class SearchSuggestionsQueryDto
{
    public function __construct(
        public readonly string $normalizedQuery,
        public readonly int $limit,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            normalizedQuery: self::normalize($data['Query']),
            limit: (int) ($data['Limit'] ?? 10),
        );
    }

    /**
     * Normalise la requête pour qu'elle corresponde au format stocké dans
     * SearchDictionary.NormalizedText : minuscules, espaces superflus retirés.
     * Ajuste ici si NormalizedText applique aussi un retrait des accents côté DB.
     */
    private static function normalize(string $raw): string
    {
        return mb_strtolower(trim($raw));
    }
}