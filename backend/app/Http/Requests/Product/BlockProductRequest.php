<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class BlockProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // gated via route middleware (admin guard)
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['product' => $this->route('product')]);
    }

    public function rules(): array
    {
        return [
            'product'       => ['required', 'integer', 'min:1'],
            'BlockedNotes'  => ['required', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'product.required'      => 'L\'identifiant du produit est requis.',
            'product.integer'       => 'L\'identifiant du produit est invalide.',
            'BlockedNotes.required' => 'Le motif du blocage est requis.',
            'BlockedNotes.max'      => 'Le motif du blocage ne peut pas dépasser 1000 caractères.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => $validator->errors()->first(),
        ], 422));
    }
}