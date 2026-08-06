<?php

namespace App\Services\Interface;

use App\DTOs\Geo\IpLocationDto;

interface IpLocationServiceInterface
{
    /**
     * Résout une adresse IP en localisation (pays/région/ville).
     * Retourne null si l'IP est invalide, non résolvable, ou en cas
     * d'échec réseau/API — jamais d'exception pour un service auxiliaire
     * comme celui-ci (voir note d'intégration ci-dessous).
     */
    public function locate(string $ip): ?IpLocationDto;
}