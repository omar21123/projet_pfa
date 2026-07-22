<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminProfileResource extends JsonResource
{
    /**
     * Structure la réponse JSON finale pour l'application cliente.
     *
     * @param Request $request
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var \App\DTOs\Admin\AdminProfileDto $dto */
        $dto = $this->resource;

        return [
            'success' => true,
            'data' => [
                'user' => [
                    'public_id'    => $dto->publicId,
                    'first_name'   => $dto->firstName,
                    'last_name'    => $dto->lastName,
                    'display_name' => $dto->displayName,
                    'email'        => $dto->email,
                    'phone_number' => $dto->phoneNumber,
                    'avatar_url'   => $dto->avatarUrl,
                    'last_login_at'=> $dto->lastLoginAt,
                ],
                'admin_profile' => [
                    'employee_number'   => $dto->employeeNumber,
                    'cin'               => $dto->cin,
                    'position'          => $dto->position,
                    'status'            => $dto->status,
                    'identity_verified' => $dto->identityVerified,
                    'hire_date'         => $dto->hireDate,
                ]
            ]
        ];
    }
}