<?php
// app/Http/Requests/Delivery/MarkDeliveryDeliveredByLivreurRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class MarkDeliveryDeliveredByLivreurRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // Only required/relevant when the order is cash-on-delivery;
            // the SP itself ignores it for non-COD orders.
            'CollectedAmount' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}