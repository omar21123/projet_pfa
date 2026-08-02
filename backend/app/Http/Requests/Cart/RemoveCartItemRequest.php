<?php

namespace App\Http\Requests\Cart;

use Illuminate\Foundation\Http\FormRequest;

class RemoveCartItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'productID'     => 'required|integer|min:1',
            'CompositionID' => 'nullable|integer|min:1',
        ];
    }

    public function messages(): array
    {
        return [
            'productID.required' => 'L\'identifiant du produit est requis.',
        ];
    }
}