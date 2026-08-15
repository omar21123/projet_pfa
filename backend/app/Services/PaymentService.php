<?php
// app/Services/PaymentService.php

namespace App\Services;

use App\DTOs\Payment\PayFromOrderDto;
use App\DTOs\Payment\PaymentResultDto;
use App\Repositories\Interface\PaymentRepositoryInterface;
use App\Services\Interface\PaymentServiceInterface;

class PaymentService implements PaymentServiceInterface
{
    public function __construct(
        protected PaymentRepositoryInterface $paymentRepository
    ) {
    }

    public function payFromOrder(PayFromOrderDto $dto): PaymentResultDto
    {
        return $this->paymentRepository->payFromOrder($dto);
    }
}