<?php
// App\Repositories\sql\AddressRepository
namespace App\Repositories\sql;

use App\DTOs\Address\AddressDto;
use App\DTOs\Address\ShippingAddressDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\AddressRepositoryInterface;
use Illuminate\Support\Facades\DB;

class AddressRepository implements AddressRepositoryInterface
{
    public function create(int $userID, array $data): int
    {
        DB::statement('SET @v_AddressID = NULL');
        DB::statement('SET @v_Success   = FALSE');
        DB::statement('SET @v_Message   = ""');

        DB::statement('CALL SP_AddAddress(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @v_Success, @v_Message, @v_AddressID)', [
            $userID,
            $data['full_name'],
            $data['phone']          ?? null,
            $data['country'],
            $data['region']         ?? null,
            $data['city'],
            $data['postal_code']    ?? null,
            $data['address_line1'],
            $data['address_line2']  ?? null,
            $data['landmark']       ?? null,
            $data['latitude']       ?? null,
            $data['longitude']      ?? null,
            isset($data['is_default_shipping']) ? (int) $data['is_default_shipping'] : 0,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message, @v_AddressID AS AddressID');

        if (!$output->Success) {
            throw new BusinessValidationException($output->Message, 422);
        }

        return (int) $output->AddressID;
    }

    public function getAllByUserID(int $userID): array
    {
        $rows = DB::select('SELECT * FROM Addresses WHERE UserID = ? ORDER BY IsDefaultShipping DESC, CreatedAt DESC', [
            $userID,
        ]);

        return array_map(fn($row) => AddressDto::fromRow($row), $rows);
    }

    public function getByID(int $addressID, int $userID): ?AddressDto
    {
        $row = DB::selectOne(
            'SELECT * FROM Addresses WHERE AddressID = ? AND UserID = ?',
            [$addressID, $userID]
        );

        return $row ? AddressDto::fromRow($row) : null;
    }

    public function update(int $addressID, int $userID, array $data): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_UpdateAddress(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @v_Success, @v_Message)', [
            $addressID,
            $userID,
            $data['full_name'],
            $data['phone']          ?? null,
            $data['country'],
            $data['region']         ?? null,
            $data['city'],
            $data['postal_code']    ?? null,
            $data['address_line1'],
            $data['address_line2']  ?? null,
            $data['landmark']       ?? null,
            $data['latitude']       ?? null,
            $data['longitude']      ?? null,
            isset($data['is_default_shipping']) ? (int) $data['is_default_shipping'] : 0,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new BusinessValidationException($output->Message, 422);
        }

        return true;
    }

    public function delete(int $addressID, int $userID): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_DeleteAddress(?, ?, @v_Success, @v_Message)', [
            $addressID,
            $userID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new BusinessValidationException($output->Message, 422);
        }

        return true;
    }

    public function setDefaultShipping(int $addressID, int $userID): bool
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        DB::statement('CALL SP_SetDefaultShippingAddress(?, ?, @v_Success, @v_Message)', [
            $addressID,
            $userID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new BusinessValidationException($output->Message, 422);
        }

        return true;
    }
    public function getDefaultShippingAddress(int $userID): ?ShippingAddressDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select('CALL SP_GetUserShippingAddress(?, @v_Success, @v_Message)', [
            $userID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new \App\Exceptions\BusinessValidationException($output->Message, 404);
        }

        if (empty($results)) {
            return null;
        }

        return ShippingAddressDto::fromRow($results[0]);
    }

    public function getOrderShippingAddress(int $orderID, ?int $vendorProfileID): ?ShippingAddressDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select(
            'CALL SP_GetOrderShippingAddress(?, ?, @v_Success, @v_Message)',
            [$orderID, $vendorProfileID]
        );

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success) {
            throw new BusinessValidationException($output->Message, 404);
        }

        return empty($results) ? null : ShippingAddressDto::fromRow($results[0]);
    }
}
