<?php

namespace App\Services;

use App\DTOs\Geo\IpLocationDto;
use App\Services\Interface\IpLocationServiceInterface;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class IpWhoIsLocationService implements IpLocationServiceInterface
{
    private const BASE_URL = 'https://ipwho.is';
    private const TIMEOUT_SECONDS = 3;

    public function locate(string $ip): ?IpLocationDto
    {
        // IP locales/privées (dev, réseau interne) ne sont pas résolvables
        // par un service de géolocalisation public — évite un appel inutile.
        if (!$this->isPubliclyRoutable($ip)) {
            return null;
        }

        try {
            $response = Http::timeout(self::TIMEOUT_SECONDS)
                ->get(self::BASE_URL . '/' . $ip);
        } catch (\Throwable $e) {
            Log::warning('IpWhoIsLocationService: échec réseau', [
                'ip'    => $ip,
                'error' => $e->getMessage(),
            ]);
            return null;
        }

        if (!$response->successful()) {
            Log::warning('IpWhoIsLocationService: réponse HTTP non réussie', [
                'ip'     => $ip,
                'status' => $response->status(),
            ]);
            return null;
        }

        $data = $response->json();

        if (!($data['success'] ?? false)) {
            // L'API répond 200 mais success=false pour une IP invalide/non résolvable.
            Log::info('IpWhoIsLocationService: résolution échouée côté API', [
                'ip'      => $ip,
                'message' => $data['message'] ?? 'raison inconnue',
            ]);
            return null;
        }

        return IpLocationDto::fromApiResponse($data);
    }

    private function isPubliclyRoutable(string $ip): bool
    {
        return filter_var(
            $ip,
            FILTER_VALIDATE_IP,
            FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE
        ) !== false;
    }
}