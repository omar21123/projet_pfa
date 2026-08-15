<?php
// app/Repositories/sql/PaymentRepository.php

namespace App\Repositories\sql;

use App\DTOs\Payment\PayFromOrderDto;
use App\DTOs\Payment\PaymentResultDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\PaymentRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentRepository implements PaymentRepositoryInterface
{
    public function payFromOrder(PayFromOrderDto $dto): PaymentResultDto
    {
        Log::info("========== PAY FROM ORDER START ==========", (array) $dto);

        DB::select(
            'CALL SP_PayFromOrder(?, ?, ?, ?, @paymentId, @success, @message)',
            [
                $dto->orderId,
                $dto->paymentMethodId,
                $dto->transactionId,
                $dto->providerReference,
            ]
        );

        $result = DB::selectOne(
            'SELECT @paymentId AS paymentId, @success AS success, @message AS message'
        );

        Log::info("PAY FROM ORDER RESULT", (array) $result);

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        Log::info("========== PAY FROM ORDER SUCCESS ==========");

        return PaymentResultDto::fromOutput($result);
    }
}