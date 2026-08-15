<?php
// app/DTOs/Delivery/AddressSummaryDto.php

namespace App\DTOs\Delivery;

class AddressSummaryDto
{
    public function __construct(
        public readonly int $addressId,
        public readonly ?string $addressLine1,
        public readonly ?string $addressLine2,
        public readonly ?string $city,
        public readonly ?string $region,
        public readonly ?string $postalCode,
        public readonly ?string $country,
    ) {
    }

    public static function fromRow(object $row, string $prefix): self
    {
        return new self(
            addressId: (int) $row->{"{$prefix}AddressID"},
            addressLine1: $row->{"{$prefix}AddressLine1"},
            addressLine2: $row->{"{$prefix}AddressLine2"},
            city: $row->{"{$prefix}City"},
            region: $row->{"{$prefix}Region"},
            postalCode: $row->{"{$prefix}PostalCode"},
            country: $row->{"{$prefix}Country"},
        );
    }

    public function toArray(): array
    {
        return [
            'address_id'     => $this->addressId,
            'address_line_1' => $this->addressLine1,
            'address_line_2' => $this->addressLine2,
            'city'           => $this->city,
            'region'         => $this->region,
            'postal_code'    => $this->postalCode,
            'country'        => $this->country,
        ];
    }
}