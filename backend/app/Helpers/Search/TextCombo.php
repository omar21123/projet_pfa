<?php

namespace App\Helpers\Search;

class TextCombo
{
    public function __construct(
        public readonly string $text,
        public readonly int $score,
    ) {}
}