<?php
// app/DTOs/Delivery/DeliveryProfileListItemDto.php

namespace App\DTOs\Delivery;

class DeliveryProfileListItemDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly ?string $avatarUrl,
        public readonly ?string $displayName,
        public readonly ?string $email,
        public readonly ?string $vehicleType,
        public readonly ?string $licensePlate,
        public readonly float $rating,
        public readonly int $deliveryCount,
        public readonly bool $identityVerified,
        public readonly ?string $lastLoginAt,
        public readonly bool $isAvailable,
        public readonly bool $isApproved,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryProfileId: (int) $row->DeliveryProfileID,
            avatarUrl: $row->AvatarURL,
            displayName: $row->DisplayName,
            email: $row->Email,
            vehicleType: $row->VehicleType,
            licensePlate: $row->LicensePlate,
            rating: (float) $row->Rating,
            deliveryCount: (int) $row->DeliveryCount,
            identityVerified: (bool) $row->IdentityVerified,
            lastLoginAt: $row->LastLoginAt,
            isAvailable: (bool) $row->IsAvailable,
            isApproved: (bool) $row->IsApproved,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_profile_id' => $this->deliveryProfileId,
            'avatar_url'          => $this->avatarUrl,
            'display_name'        => $this->displayName,
            'email'               => $this->email,
            'vehicle_type'        => $this->vehicleType,
            'license_plate'       => $this->licensePlate,
            'rating'              => $this->rating,
            'delivery_count'      => $this->deliveryCount,
            'identity_verified'   => $this->identityVerified,
            'last_login_at'       => $this->lastLoginAt,
            'is_available'        => $this->isAvailable,
            'is_approved'         => $this->isApproved,
        ];
    }
}