<?php

namespace App\Http\Requests\Unit;

use Illuminate\Foundation\Http\FormRequest;

class CreateUnitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name'         => ['required', 'string', 'max:100'],
            'Symbol'       => ['required', 'string', 'max:20'],
            'DisplayOrder' => ['nullable', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'Name.required'   => 'Le nom de l\'unité est obligatoire.',
            'Name.max'         => 'Le nom de l\'unité ne doit pas dépasser 100 caractères.',
            'Symbol.required' => 'Le symbole est obligatoire.',
            'Symbol.max'       => 'Le symbole ne doit pas dépasser 20 caractères.',
        ];
    }
}