<?php

namespace App\Http\Requests\Wishlist;

use Illuminate\Foundation\Http\FormRequest;

class AddWishlistItemRequest extends FormRequest
{
    public function authorize(): bool
    {
        // L'appartenance de la wishlist à l'utilisateur est vérifiée
        // côté SP (SP_AddWishlistItem), pas ici.
        return true;
    }

    public function rules(): array
    {
        return [
            'product_id' => 'required|integer|min:1|exists:Products,ProductID',
        ];
    }

    public function messages(): array
    {
        return [
            'product_id.required' => 'L\'identifiant du produit est requis.',
            'product_id.integer'  => 'L\'identifiant du produit doit être un nombre entier.',
            'product_id.exists'   => 'Le produit spécifié n\'existe pas.',
        ];
    }
}