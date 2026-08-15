<?php
// app/Http/Requests/Order/CreateOrderFromCartRequest.php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CreateOrderFromCartRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'AddressID'       => ['required', 'integer', 'min:1'],
            'PaymentMethodID' => ['required', 'integer', 'min:1'],
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
            'Notes.max'                => 'Les notes ne doivent pas dépasser :max caractères.',
        ];
    }
}