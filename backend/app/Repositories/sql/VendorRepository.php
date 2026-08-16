<?php

namespace App\Repositories\sql;

use App\DTOs\Product\ProductItemDto;
use App\DTOs\Vendor\PaginatedVendorWithdrawHistoryDto;
use App\DTOs\Vendor\RequestVendorWithdrawDto;
use App\DTOs\Vendor\VendorBankAccountDto;
use App\DTOs\Vendor\VendorProfileResponseDto;
use App\DTOs\Vendor\VendorPublicProfileResponseDto;
use App\DTOs\Vendor\VendorWithdrawItemDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\VendorRepositoryInterface;
use Illuminate\Support\Facades\DB;

class VendorRepository implements VendorRepositoryInterface
{
    public function findByUserId(int $userId): ?object
    {
        $row = DB::selectOne("
            SELECT *
            FROM VendorProfiles
            WHERE UserID = ?
        ", [$userId]);

        return $row ?: null;
    }
    public function findByProductId(int $productId): ?VendorProfileResponseDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select('CALL sp_GetVendorProfile(?, @v_Success, @v_Message)', [
            $productId,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success || empty($results)) {
            return null;
        }

        return VendorProfileResponseDto::fromRow($results[0]);
    }
    public function getVendorProducts(
        int     $vendorProfileID,
        ?string $userPublicID,
        ?int    $categoryID,
        int     $pageNumber,
        int     $pageSize
    ): array {
        DB::statement('SET @v_TotalCount = 0');
        DB::statement('SET @v_Success    = FALSE');
        DB::statement('SET @v_Message    = ""');

        $results = DB::select(
            'CALL SP_GetVendorProducts(?, ?, ?, ?, ?, @v_TotalCount, @v_Success, @v_Message)',
            [$vendorProfileID, $userPublicID, $categoryID, $pageNumber, $pageSize]
        );

        $output = DB::selectOne(
            'SELECT @v_Success AS Success, @v_Message AS Message, @v_TotalCount AS TotalCount'
        );

        if (!$output->Success) {
            return [
                'data'       => [],
                'total'      => 0,
                'page'       => $pageNumber,
                'pageSize'   => $pageSize,
                'totalPages' => 0,
            ];
        }

        return [
            'data'       => array_map(
                fn($row) => ProductItemDto::fromRow($row),
                $results
            ),
            'total'      => (int) $output->TotalCount,
            'page'       => $pageNumber,
            'pageSize'   => $pageSize,
            'totalPages' => (int) ceil($output->TotalCount / $pageSize),
        ];
    }
    public function getPublicProfile(int $vendorProfileID): ?VendorPublicProfileResponseDto
    {
        DB::statement('SET @v_Success = FALSE');
        DB::statement('SET @v_Message = ""');

        $results = DB::select('CALL sp_GetVendorPublicProfile(?, @v_Success, @v_Message)', [
            $vendorProfileID,
        ]);

        $output = DB::selectOne('SELECT @v_Success AS Success, @v_Message AS Message');

        if (!$output->Success || empty($results)) {
            return null;
        }

        return VendorPublicProfileResponseDto::fromRow($results[0]);
    }
    public function getBankAccountByVendorProfileId(int $vendorProfileId): ?VendorBankAccountDto
    {
        Log::info("========== GET VENDOR BANK ACCOUNT START ==========", ['vendorProfileId' => $vendorProfileId]);

        $row = DB::selectOne(
            'SELECT
            ba.BankAccountID, ba.VendorProfileID, ba.CurrentBalance,
            ba.WithdrawableBalance, ba.PendingBalance, ba.CurrencyCode, ba.IsLocked,
            COALESCE((
                SELECT SUM(h.Amount) FROM BankAccountHolds h
                WHERE h.BankAccountID = ba.BankAccountID AND h.Status = 0
            ), 0) AS TotalHeld,
            (
                SELECT COUNT(*) FROM BankAccountHolds h
                WHERE h.BankAccountID = ba.BankAccountID AND h.Status = 0
            ) AS ActiveHoldsCount
        FROM BankAccounts ba
        WHERE ba.VendorProfileID = ?',
            [$vendorProfileId]
        );

        Log::info("GET VENDOR BANK ACCOUNT RESULT", ['found' => (bool) $row]);

        return $row ? VendorBankAccountDto::fromRow($row) : null;
    }

    public function getVendorWithdrawHistory(int $vendorProfileId, int $page, int $perPage): PaginatedVendorWithdrawHistoryDto
    {
        Log::info("========== GET VENDOR WITHDRAW HISTORY START ==========", [
            'vendorProfileId' => $vendorProfileId,
            'page' => $page,
            'perPage' => $perPage,
        ]);

        $offset = ($page - 1) * $perPage;

        $totalRow = DB::selectOne(
            'SELECT COUNT(*) AS total
         FROM WithdrawHistory wh
         INNER JOIN BankAccounts ba ON ba.BankAccountID = wh.BankAccountID
         WHERE ba.VendorProfileID = ?',
            [$vendorProfileId]
        );

        $rows = DB::select(
            'SELECT wh.WithdrawID, wh.Amount, wh.PaymentMethodID, wh.ExternalReference,
                wh.Status, wh.Notes, wh.RequestedAt, wh.ProcessedAt
         FROM WithdrawHistory wh
         INNER JOIN BankAccounts ba ON ba.BankAccountID = wh.BankAccountID
         WHERE ba.VendorProfileID = ?
         ORDER BY wh.RequestedAt DESC
         LIMIT ? OFFSET ?',
            [$vendorProfileId, $perPage, $offset]
        );

        Log::info("GET VENDOR WITHDRAW HISTORY RESULT", ['total' => $totalRow->total, 'count' => count($rows)]);

        return new PaginatedVendorWithdrawHistoryDto(
            data: array_map(fn($row) => VendorWithdrawItemDto::fromRow($row), $rows),
            total: (int) $totalRow->total,
            page: $page,
            perPage: $perPage,
        );
    }

    public function requestVendorWithdraw(RequestVendorWithdrawDto $dto): int
    {
        Log::info("========== REQUEST VENDOR WITHDRAW START ==========", (array) $dto);

        DB::select(
            'CALL SP_RequestVendorWithdraw(?, ?, ?, @success, @message, @withdrawId)',
            [$dto->vendorProfileId, $dto->amount, $dto->paymentMethodId]
        );

        $result = DB::selectOne(
            'SELECT @success AS success, @message AS message, @withdrawId AS withdrawId'
        );

        Log::info("REQUEST VENDOR WITHDRAW RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== REQUEST VENDOR WITHDRAW SUCCESS ==========");

        return (int) $result->withdrawId;
    }
}
