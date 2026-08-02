<?php

namespace App\Http\Requests\ProductLike;

use Illuminate\Foundation\Http\FormRequest;

class AddProductLikeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'product_id' => ['required', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'product_id.required' => 'L\'identifiant du produit est requis.',
            'product_id.integer'  => 'L\'identifiant du produit doit être un entier.',
            'product_id.min'      => 'Identifiant de produit invalide.',
        ];
    }
}