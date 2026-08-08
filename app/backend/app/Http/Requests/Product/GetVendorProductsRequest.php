<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class GetVendorProductsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status'     => 'nullable|integer',
            'search'     => 'nullable|string|max:255',
            'is_active'  => 'nullable|boolean',
            'is_blocked' => 'nullable|boolean',
            'page'       => 'nullable|integer|min:1',
            'per_page'   => 'nullable|integer|min:1|max:100',
        ];
    }
}