<?php
// App\Services\AddressService
namespace App\Services;

use App\DTOs\Address\AddressDto;
use App\Repositories\Interface\AddressRepositoryInterface;
use App\Services\Interface\AddressServiceInterface;

class AddressService implements AddressServiceInterface
{
    public function __construct(
        protected AddressRepositoryInterface $addressRepository,
    ) {}

    public function create(int $userID, array $data): int
    {
        return $this->addressRepository->create($userID, $data);
    }

    public function getAllByUserID(int $userID): array
    {
        return $this->addressRepository->getAllByUserID($userID);
    }

    public function getByID(int $addressID, int $userID): ?AddressDto
    {
        return $this->addressRepository->getByID($addressID, $userID);
    }

    public function update(int $addressID, int $userID, array $data): bool
    {
        return $this->addressRepository->update($addressID, $userID, $data);
    }

    public function delete(int $addressID, int $userID): bool
    {
        return $this->addressRepository->delete($addressID, $userID);
    }

    public function setDefaultShipping(int $addressID, int $userID): bool
    {
        return $this->addressRepository->setDefaultShipping($addressID, $userID);
    }
    public function getDefaultShippingAddress(int $userID): ?\App\DTOs\Address\ShippingAddressDto
    {
        return $this->addressRepository->getDefaultShippingAddress($userID);
    }

    public function getOrderShippingAddress(int $orderID, ?int $vendorProfileID): ?\App\DTOs\Address\ShippingAddressDto
    {
        return $this->addressRepository->getOrderShippingAddress($orderID, $vendorProfileID);
    }
}
