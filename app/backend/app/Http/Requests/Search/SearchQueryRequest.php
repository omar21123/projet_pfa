<?php

namespace App\Http\Requests\Search;

use Illuminate\Foundation\Http\FormRequest;

class SearchQueryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // endpoint public, pas d'authentification requise
    }

    public function rules(): array
    {
        return [
            'q'         => ['required', 'string', 'min:2', 'max:150'],
            'page'      => ['nullable', 'integer', 'min:1'],
            'page_size' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'q.required' => 'La requête de recherche est obligatoire.',
            'q.min'      => 'La requête doit contenir au moins 2 caractères.',
            'q.max'      => 'La requête ne doit pas dépasser 150 caractères.',
        ];
    }
}