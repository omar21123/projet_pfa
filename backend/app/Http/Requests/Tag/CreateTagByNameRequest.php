<?php

namespace App\Http\Requests\Tag;

use Illuminate\Foundation\Http\FormRequest;

class CreateTagByNameRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name' => ['required', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'Name.required' => 'Le nom du tag est obligatoire.',
            'Name.max'       => 'Le nom du tag ne doit pas dépasser 100 caractères.',
        ];
    }
}