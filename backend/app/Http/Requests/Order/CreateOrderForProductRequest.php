<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CreateOrderForProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // auth handled by JWT middleware upstream
    }

    public function rules(): array
    {
        return [
            'AddressID'       => ['required', 'integer', 'min:1'],
            'PaymentMethodID' => ['required', 'integer', 'min:1'],
            'ProductID'       => ['required', 'integer', 'min:1'],
            'Quantity'        => ['required', 'integer', 'min:1'],
            'CombinationID'   => ['nullable', 'integer', 'min:1'],
            'PromotionID'     => ['nullable', 'integer', 'min:1'],
            'Notes'           => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'AddressID.required'       => 'L\'adresse est requise.',
            'AddressID.integer'        => 'L\'adresse fournie est invalide.',
            'PaymentMethodID.required' => 'La méthode de paiement est requise.',
            'PaymentMethodID.integer'  => 'La méthode de paiement fournie est invalide.',
            'ProductID.required'       => 'Le produit est requis.',
            'ProductID.integer'        => 'Le produit fourni est invalide.',
            'Quantity.required'        => 'La quantité est requise.',
            'Quantity.integer'         => 'La quantité doit être un nombre entier.',
            'Quantity.min'             => 'La quantité doit être supérieure à zéro.',
            'CombinationID.integer'    => 'La variante fournie est invalide.',
            'PromotionID.integer'      => 'La promotion fournie est invalide.',
            'Notes.max'                => 'Les notes ne doivent pas dépasser :max caractères.',
        ];
    }
}