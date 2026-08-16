<?php
// app/Http/Requests/Delivery/MarkDeliveryPickedUpRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class MarkDeliveryPickedUpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [];
        // DeliveryID from route, DeliveryProfileID resolved from JWT
    }
}