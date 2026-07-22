<?php

namespace App\Http\Requests\ProductsConfigAttribute;

use Illuminate\Foundation\Http\FormRequest;

class CreateProductsConfigAttributeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name'         => ['required', 'string', 'max:150'],
            'UnitID'       => ['nullable', 'integer'],
            'DisplayOrder' => ['nullable', 'integer', 'min:0'],
        ];
    }
}