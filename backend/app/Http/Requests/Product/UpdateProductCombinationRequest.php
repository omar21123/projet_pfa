<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProductCombinationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // La propriété est vérifiée côté SP via le token JWT
    }

    public function rules(): array
    {
        return [
            'SKU'             => ['nullable', 'string', 'max:64'],
            'Price'           => ['required', 'numeric', 'min:0'],
            'CompareAtPrice'  => ['nullable', 'numeric', 'min:0', 'gte:Price'],
            'Stock'           => ['required', 'integer', 'min:0'],
            'Image'           => ['nullable', 'image', 'max:5120'], // 5MB
            'IsDefault'       => ['nullable', 'boolean'],
            'IsActive'        => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'Price.required'          => 'Le prix est obligatoire.',
            'Price.min'                => 'Le prix doit être supérieur ou égal à 0.',
            'CompareAtPrice.gte'       => 'Le prix barré doit être supérieur ou égal au prix.',
            'Stock.required'           => 'Le stock est obligatoire.',
            'Stock.min'                 => 'Le stock doit être supérieur ou égal à 0.',
            'Image.image'              => 'Le fichier doit être une image.',
            'Image.max'                => 'L\'image ne doit pas dépasser 5MB.',
        ];
    }
}