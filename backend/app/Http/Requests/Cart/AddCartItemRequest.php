<?php

namespace App\Http\Requests\Cart;

use Illuminate\Foundation\Http\FormRequest;

class AddCartItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Nécessite un utilisateur authentifié (un panier appartient à un UserID).
        return true;
    }

    public function rules(): array
    {
        return [
            'productID'     => 'required|integer|min:1',
            'FromSearch'    => 'nullable|boolean',
            'SearchTerm'    => 'nullable|string|max:255|required_if:FromSearch,true',
            'CompositionID' => 'nullable|integer|min:1',
            'UnitPrice'     => 'required|numeric|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'productID.required'     => 'L\'identifiant du produit est requis.',
            'UnitPrice.required'     => 'Le prix unitaire est requis.',
            'SearchTerm.required_if' => 'SearchTerm est requis lorsque FromSearch est vrai.',
        ];
    }
}