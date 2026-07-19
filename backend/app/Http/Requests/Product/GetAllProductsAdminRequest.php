<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class GetAllProductsAdminRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // authorization handled via route middleware (admin guard)
    }

    public function rules(): array
    {
        return [
            'status'     => ['nullable', 'integer', 'exists:ProductStatus,Id'],
            'vendor_id'  => ['nullable', 'integer', 'exists:VendorProfiles,VendorProfileID'],
            'brand_id'   => ['nullable', 'integer', 'exists:Brands,BrandID'],
            'model_id'   => ['nullable', 'integer', 'exists:Models,ModelID'],
            'search'     => ['nullable', 'string', 'max:255'],
            'is_active'  => ['nullable', 'boolean'],
            'is_blocked' => ['nullable', 'boolean'],
            'date_from'  => ['nullable', 'date'],
            'date_to'    => ['nullable', 'date', 'after_or_equal:date_from'],
            'page'       => ['nullable', 'integer', 'min:1'],
            'per_page'   => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'status.exists'     => 'Le statut spécifié n\'existe pas.',
            'vendor_id.exists'  => 'Le vendeur spécifié n\'existe pas.',
            'brand_id.exists'   => 'La marque spécifiée n\'existe pas.',
            'model_id.exists'   => 'Le modèle spécifié n\'existe pas.',
            'date_to.after_or_equal' => 'La date de fin doit être postérieure ou égale à la date de début.',
            'per_page.max'      => 'Le nombre d\'éléments par page ne peut pas dépasser 100.',
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