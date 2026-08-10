<?php

namespace App\Http\Requests\Cart;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCartItemQuantityRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'CartItemID' => 'required|integer|min:1',
            'Quantity'   => 'required|numeric|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'CartItemID.required' => 'L\'identifiant de l\'article du panier est requis.',
            'Quantity.required'   => 'La quantité est requise.',
            'Quantity.numeric'    => 'La quantité doit être un nombre.',
            'Quantity.min'        => 'La quantité ne peut pas être négative.',
        ];
    }
}