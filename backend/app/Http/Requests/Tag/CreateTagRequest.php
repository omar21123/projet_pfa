<?php

namespace App\Http\Requests\Tag;

use Illuminate\Foundation\Http\FormRequest;

class CreateTagRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name'        => ['required', 'string', 'max:100'],
            'Color'       => ['nullable', 'string', 'max:20'],
            'Description' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'Name.required'        => 'Le nom du tag est obligatoire.',
            'Name.max'              => 'Le nom du tag ne doit pas dépasser 100 caractères.',
            'Color.max'             => 'La couleur ne doit pas dépasser 20 caractères.',
            'Description.max'       => 'La description ne doit pas dépasser 255 caractères.',
        ];
    }
}