<?php

namespace App\Adapters\Payment;

use App\DTOs\Order\OrderDto;

interface PaymentAdapterInterface
{
    public function authorize(OrderDto $order): PaymentResultStripe;

    public function capture(PaymentResultStripe $payment): PaymentResultStripe;
}
