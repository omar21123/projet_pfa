<?php

namespace App\Http\Requests\Wishlist;

use Illuminate\Foundation\Http\FormRequest;

class CreateWishlistRequest extends FormRequest
{
    public function authorize(): bool
    {
        // L'autorisation métier (utilisateur valide, etc.) est vérifiée
        // plus loin via le token JWT + la SP, pas ici.
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'nullable|string|max:150',
        ];
    }

    public function messages(): array
    {
        return [
            'name.string' => 'Le nom de la wishlist doit être une chaîne de caractères.',
            'name.max'    => 'Le nom de la wishlist ne doit pas dépasser 150 caractères.',
        ];
    }
}