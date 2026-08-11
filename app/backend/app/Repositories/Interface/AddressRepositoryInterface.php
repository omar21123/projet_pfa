<?php
// App\Repositories\Interface\AddressRepositoryInterface
namespace App\Repositories\Interface;

use App\DTOs\Address\AddressDto;
use App\DTOs\Address\ShippingAddressDto;

interface AddressRepositoryInterface
{
    public function create(int $userID, array $data): int;
    public function getAllByUserID(int $userID): array;
    public function getByID(int $addressID, int $userID): ?AddressDto;
    public function update(int $addressID, int $userID, array $data): bool;
    public function delete(int $addressID, int $userID): bool;
    public function setDefaultShipping(int $addressID, int $userID): bool;
    // Add to AddressRepositoryInterface
    public function getDefaultShippingAddress(int $userID): ?ShippingAddressDto;
    public function getOrderShippingAddress(int $orderID, ?int $vendorProfileID): ?ShippingAddressDto;
    
}
