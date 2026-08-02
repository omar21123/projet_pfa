<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class GetProductInfoRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Route publique — un visiteur non connecté peut consulter un produit.
        // L'appartenance/visibilité (produit bloqué, inactif, etc.) est vérifiée
        // côté service/SP, pas ici.
        return true;
    }

    public function rules(): array
    {
        return [
            'ProductID'  => 'required|integer|min:1',
            'FromSearch' => 'nullable|boolean',
            'SearchTerm' => 'nullable|string|max:255|required_if:FromSearch,true',
        ];
    }

    public function messages(): array
    {
        return [
            'ProductID.required'        => 'L\'identifiant du produit est requis.',
            'ProductID.integer'         => 'L\'identifiant du produit doit être un nombre entier.',
            'SearchTerm.required_if'    => 'SearchTerm est requis lorsque FromSearch est vrai.',
        ];
    }
}