<?php

namespace App\Adapters\Payment;

use App\DTOs\Order\OrderDto;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Placeholder adapter. It deliberately does not call Stripe or persist payment data.
 */
class StripePaymentAdapter implements PaymentAdapterInterface
{
    public function authorize(OrderDto $order): PaymentResultStripe
    {
        $payment = new PaymentResultStripe(
            provider: 'stripe',
            transactionId: 'pi_placeholder_' . Str::lower(Str::random(24)),
            status: 'authorized',
        );

        Log::info('Placeholder Stripe payment authorized.', [
            'orderId' => $order->orderId,
            'amount' => $order->total,
            'currency' => $order->currency,
            'transactionId' => $payment->transactionId,
        ]);

        return $payment;
    }

    public function capture(PaymentResultStripe $payment): PaymentResultStripe
    {
        $capturedPayment = new PaymentResultStripe(
            provider: $payment->provider,
            transactionId: $payment->transactionId,
            status: 'captured',
        );

        Log::info('Placeholder Stripe payment captured.', [
            'transactionId' => $capturedPayment->transactionId,
        ]);

        return $capturedPayment;
    }
}
