<?php
// app/Http/Requests/Delivery/SuspendDeliveryProfileRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class SuspendDeliveryProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Reason' => ['nullable', 'string', 'max:500'],
        ];
    }
}