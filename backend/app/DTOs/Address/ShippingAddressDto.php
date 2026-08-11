<?php
// App\DTOs\Address\ShippingAddressDto
namespace App\DTOs\Address;

class ShippingAddressDto
{
    public function __construct(
        public readonly string  $fullName,
        public readonly ?string $phone,
        public readonly string  $country,
        public readonly ?string $region,
        public readonly string  $city,
        public readonly ?string $postalCode,
        public readonly string  $addressLine1,
        public readonly ?string $addressLine2,
        public readonly ?string $landmark,
        public readonly ?float  $latitude,
        public readonly ?float  $longitude,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            fullName:     $row->FullName,
            phone:        $row->Phone        ?? null,
            country:      $row->Country,
            region:       $row->Region       ?? null,
            city:         $row->City,
            postalCode:   $row->PostalCode   ?? null,
            addressLine1: $row->AddressLine1,
            addressLine2: $row->AddressLine2 ?? null,
            landmark:     $row->Landmark     ?? null,
            latitude:     isset($row->Latitude)  ? (float) $row->Latitude  : null,
            longitude:    isset($row->Longitude) ? (float) $row->Longitude : null,
        );
    }

    public function toArray(): array
    {
        return [
            'FullName'     => $this->fullName,
            'Phone'        => $this->phone,
            'Country'      => $this->country,
            'Region'       => $this->region,
            'City'         => $this->city,
            'PostalCode'   => $this->postalCode,
            'AddressLine1' => $this->addressLine1,
            'AddressLine2' => $this->addressLine2,
            'Landmark'     => $this->landmark,
            'Latitude'     => $this->latitude,
            'Longitude'    => $this->longitude,
        ];
    }
}