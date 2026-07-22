<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var \App\DTOs\Auth\UserDto $dto */
        $dto = $this->resource;

        return [
            'id'             => $dto->id,
            'public_id'      => $dto->publicId,
            'first_name'     => $dto->firstName,
            'last_name'      => $dto->lastName,
            'display_name'   => $dto->displayName,
            'email'          => $dto->email,
            'phone_number'   => $dto->phoneNumber,
            'avatar_url'     => $dto->avatarUrl,
            'email_verified' => $dto->emailVerified,
            'is_active'      => $dto->isActive,
            'roles'          => $dto->roles,
            'created_at'     => $dto->createdAt,
            // passwordHash n'apparaît jamais ici — c'est exactement le rôle du DTO :
            // porter la donnée en interne sans l'exposer forcément en sortie.
        ];
    }
}