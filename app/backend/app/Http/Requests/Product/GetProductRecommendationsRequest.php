<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class GetProductRecommendationsRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Route publique — accessible aux invités. L'utilisateur (s'il est
        // connecté) est résolu via le token JWT dans le controller, pas ici.
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'limit' => $this->query('limit', 20),
        ]);
    }

    public function rules(): array
    {
        return [
            'limit'       => 'nullable|integer|min:1|max:100',
            'category_id' => 'nullable|integer|min:1|exists:Categories,CategoryID',
        ];
    }

    public function messages(): array
    {
        return [
            'limit.integer'        => 'limit doit être un nombre entier.',
            'limit.min'             => 'limit doit être au moins 1.',
            'limit.max'             => 'limit ne doit pas dépasser 100.',
            'category_id.integer'  => 'category_id doit être un nombre entier.',
            'category_id.exists'   => 'La catégorie spécifiée n\'existe pas.',
        ];
    }
}