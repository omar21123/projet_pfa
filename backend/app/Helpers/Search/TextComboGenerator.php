<?php

namespace App\Helpers\Search;

class TextComboGenerator
{
    /**
     * Génère toutes les combinaisons non vides des termes de $text (découpés par espace),
     * chacune associée à un score = nombre de termes qu'elle contient.
     *
     * Équivalent PHP de GetAllCombinations(string text) en C# :
     * - découpe le texte en mots (en ignorant les espaces multiples/vides)
     * - pour chaque masque de bits de 1 à 2^n - 1, reconstruit la sous-chaîne
     *   correspondant aux termes dont le bit est activé
     * - Score = nombre de bits activés dans le masque (nombre de termes inclus)
     *
     * @return TextCombo[]
     */
    public static function getAllCombinations(string $text): array
    {
        $items = preg_split('/\s+/', trim($text), -1, PREG_SPLIT_NO_EMPTY);
        $n = count($items);

        if ($n === 0) {
            return [];
        }

        $totalCombos = (1 << $n) - 1; // 2^n - 1, nombre exact de combinaisons
        $result = [];

        for ($mask = 1; $mask <= $totalCombos; $mask++) {
            $parts = [];

            for ($i = 0; $i < $n; $i++) {
                // vérifie si le bit i est activé -> le terme i fait partie de cette combinaison
                if (($mask & (1 << $i)) !== 0) {
                    $parts[] = $items[$i];
                }
            }

            $result[] = new TextCombo(
                text: implode(' ', $parts),
                score: substr_count(decbin($mask), '1'), // nombre de bits activés = nombre de termes
            );
        }

        return $result;
    }
        
}