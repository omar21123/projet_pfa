<?php
// app/Http/Requests/Order/GetCustomerOrdersRequest.php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class GetCustomerOrdersRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status'   => ['nullable', 'string', 'in:PENDING,CONFIRMED,SHIPPED,DELIVERED,CANCELLED'],
            'page'     => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}