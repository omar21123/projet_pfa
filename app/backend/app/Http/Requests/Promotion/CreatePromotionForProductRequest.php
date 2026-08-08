<?php

namespace App\Http\Requests\Promotion;

use Illuminate\Foundation\Http\FormRequest;

class CreatePromotionForProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Propriété vérifiée côté SP via le token JWT
    }

    public function rules(): array
    {
        return [
            'ProductID'          => ['required', 'integer', 'min:1'],
            'Name'               => ['required', 'string', 'max:150'],
            'Description'        => ['nullable', 'string', 'max:500'],
            'PromoCode'          => ['nullable', 'string', 'max:50'],
            'DiscountTypeCode'   => ['required', 'string', 'in:PERCENTAGE,FIXED_AMOUNT'],
            'DiscountValue'      => ['required', 'numeric', 'min:0.01'],
            'MaxDiscountAmount'  => ['nullable', 'numeric', 'min:0'],
            'MinOrderAmount'     => ['nullable', 'numeric', 'min:0'],
            'UsageLimitTotal'    => ['nullable', 'integer', 'min:1'],
            'UsageLimitPerUser'  => ['nullable', 'integer', 'min:1'],
            'StartDate'          => ['required', 'date'],
            'EndDate'            => ['required', 'date', 'after:StartDate'],
        ];
    }

    public function messages(): array
    {
        return [
            'ProductID.required'        => 'Le produit est obligatoire.',
            'Name.required'             => 'Le nom de la promotion est obligatoire.',
            'DiscountTypeCode.required' => 'Le type de réduction est obligatoire.',
            'DiscountTypeCode.in'       => 'Le type de réduction doit être PERCENTAGE ou FIXED_AMOUNT.',
            'DiscountValue.required'    => 'La valeur de la réduction est obligatoire.',
            'DiscountValue.min'         => 'La valeur de la réduction doit être supérieure à 0.',
            'StartDate.required'        => 'La date de début est obligatoire.',
            'EndDate.required'          => 'La date de fin est obligatoire.',
            'EndDate.after'             => 'La date de fin doit être postérieure à la date de début.',
        ];
    }
}