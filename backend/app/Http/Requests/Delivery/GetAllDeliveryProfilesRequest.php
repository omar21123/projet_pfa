<?php
// app/Http/Requests/Delivery/GetAllDeliveryProfilesRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class GetAllDeliveryProfilesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'search'       => ['nullable', 'string', 'max:255'],
            'is_available' => ['nullable', 'boolean'],
            'is_approved'  => ['nullable', 'boolean'],
            'is_suspended' => ['nullable', 'boolean'],
            'page'         => ['nullable', 'integer', 'min:1'],
            'per_page'     => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}