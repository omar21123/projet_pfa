<?php
// app/Http/Requests/Delivery/GetVendorDeliveriesRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class GetVendorDeliveriesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status'    => ['nullable', 'string', 'in:pending,accepted,picked_up,in_transit,delivered,failed,cancelled'],
            'is_taken'  => ['nullable', 'boolean'],
            'page'      => ['nullable', 'integer', 'min:1'],
            'per_page'  => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}