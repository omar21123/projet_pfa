<?php
// app/DTOs/Delivery/DeliveryProfileDetailsDto.php

namespace App\DTOs\Delivery;

class DeliveryProfileDetailsDto
{
    public function __construct(
        public readonly int $deliveryProfileId,
        public readonly int $userId,
        public readonly ?string $publicId,
        public readonly ?string $firstName,
        public readonly ?string $lastName,
        public readonly ?string $displayName,
        public readonly ?string $email,
        public readonly ?string $phoneNumber,
        public readonly ?string $avatarUrl,
        public readonly bool $emailVerified,
        public readonly bool $phoneVerified,
        public readonly bool $userIsActive,
        public readonly ?string $lastLoginAt,
        public readonly ?string $userCreatedAt,

        public readonly ?string $vehicleType,
        public readonly ?string $licensePlate,
        public readonly float $rating,
        public readonly int $deliveryCount,
        public readonly bool $isAvailable,
        public readonly ?string $lastOnlineAt,
        public readonly ?float $currentLatitude,
        public readonly ?float $currentLongitude,
        public readonly bool $identityVerified,
        public readonly bool $isApproved,
        public readonly bool $isSuspended,
        public readonly ?string $profileCreatedAt,
        public readonly ?string $profileUpdatedAt,

        public readonly ?int $deliveryWalletId,
        public readonly ?float $currentBalance,
        public readonly ?float $withdrawableBalance,
        public readonly ?float $pendingBalance,
        public readonly ?string $currencyCode,
        public readonly ?bool $walletIsLocked,
    ) {
    }

    public static function fromRow(object $row): self
    {
        return new self(
            deliveryProfileId: (int) $row->DeliveryProfileID,
            userId: (int) $row->UserID,
            publicId: $row->PublicID,
            firstName: $row->FirstName,
            lastName: $row->LastName,
            displayName: $row->DisplayName,
            email: $row->Email,
            phoneNumber: $row->PhoneNumber,
            avatarUrl: $row->AvatarURL,
            emailVerified: (bool) $row->EmailVerified,
            phoneVerified: (bool) $row->PhoneVerified,
            userIsActive: (bool) $row->UserIsActive,
            lastLoginAt: $row->LastLoginAt,
            userCreatedAt: $row->UserCreatedAt,

            vehicleType: $row->VehicleType,
            licensePlate: $row->LicensePlate,
            rating: (float) $row->Rating,
            deliveryCount: (int) $row->DeliveryCount,
            isAvailable: (bool) $row->IsAvailable,
            lastOnlineAt: $row->LastOnlineAt,
            currentLatitude: $row->CurrentLatitude !== null ? (float) $row->CurrentLatitude : null,
            currentLongitude: $row->CurrentLongitude !== null ? (float) $row->CurrentLongitude : null,
            identityVerified: (bool) $row->IdentityVerified,
            isApproved: (bool) $row->IsApproved,
            isSuspended: (bool) $row->IsSuspended,
            profileCreatedAt: $row->ProfileCreatedAt,
            profileUpdatedAt: $row->ProfileUpdatedAt,

            deliveryWalletId: $row->DeliveryWalletID !== null ? (int) $row->DeliveryWalletID : null,
            currentBalance: $row->CurrentBalance !== null ? (float) $row->CurrentBalance : null,
            withdrawableBalance: $row->WithdrawableBalance !== null ? (float) $row->WithdrawableBalance : null,
            pendingBalance: $row->PendingBalance !== null ? (float) $row->PendingBalance : null,
            currencyCode: $row->CurrencyCode,
            walletIsLocked: $row->WalletIsLocked !== null ? (bool) $row->WalletIsLocked : null,
        );
    }

    public function toArray(): array
    {
        return [
            'delivery_profile_id' => $this->deliveryProfileId,
            'user' => [
                'user_id'        => $this->userId,
                'public_id'      => $this->publicId,
                'first_name'     => $this->firstName,
                'last_name'      => $this->lastName,
                'display_name'   => $this->displayName,
                'email'          => $this->email,
                'phone_number'   => $this->phoneNumber,
                'avatar_url'     => $this->avatarUrl,
                'email_verified' => $this->emailVerified,
                'phone_verified' => $this->phoneVerified,
                'is_active'      => $this->userIsActive,
                'last_login_at'  => $this->lastLoginAt,
                'created_at'     => $this->userCreatedAt,
            ],
            'vehicle_type'      => $this->vehicleType,
            'license_plate'     => $this->licensePlate,
            'rating'            => $this->rating,
            'delivery_count'    => $this->deliveryCount,
            'is_available'      => $this->isAvailable,
            'last_online_at'    => $this->lastOnlineAt,
            'current_latitude'  => $this->currentLatitude,
            'current_longitude' => $this->currentLongitude,
            'identity_verified' => $this->identityVerified,
            'is_approved'       => $this->isApproved,
            'is_suspended'      => $this->isSuspended,
            'created_at'        => $this->profileCreatedAt,
            'updated_at'        => $this->profileUpdatedAt,
            'wallet' => $this->deliveryWalletId === null ? null : [
                'delivery_wallet_id'   => $this->deliveryWalletId,
                'current_balance'      => $this->currentBalance,
                'withdrawable_balance' => $this->withdrawableBalance,
                'pending_balance'      => $this->pendingBalance,
                'currency_code'        => $this->currencyCode,
                'is_locked'            => $this->walletIsLocked,
            ],
        ];
    }
}