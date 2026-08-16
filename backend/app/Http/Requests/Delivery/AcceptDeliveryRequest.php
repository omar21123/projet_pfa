<?php
// app/Http/Requests/Delivery/AcceptDeliveryRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class AcceptDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [];
        // DeliveryID comes from route, DeliveryProfileID resolved from JWT
    }
}