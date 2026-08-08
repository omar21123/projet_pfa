<?php

namespace App\Http\Requests\Search;

use Illuminate\Foundation\Http\FormRequest;

class SearchSuggestionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // endpoint public, pas d'authentification requise
    }

    public function rules(): array
    {
        return [
            'q'     => ['required', 'string', 'min:2', 'max:150'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:20'],
        ];
    }
}