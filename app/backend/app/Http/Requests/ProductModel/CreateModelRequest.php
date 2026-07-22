<?php

namespace App\Http\Requests\ProductModel;

use Illuminate\Foundation\Http\FormRequest;

class CreateModelRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'BrandID'     => ['required', 'integer'],
            'Name'        => ['required', 'string', 'max:150'],
            'Code'        => ['nullable', 'string', 'max:50'],
            'Description' => ['nullable', 'string'],
            'ReleaseYear' => ['nullable', 'integer', 'digits:4', 'min:1900', 'max:' . (date('Y') + 1)],
        ];
    }

    public function messages(): array
    {
        return [
            'BrandID.required'    => 'La marque est obligatoire.',
            'Name.required'       => 'Le nom du modèle est obligatoire.',
            'Name.max'             => 'Le nom du modèle ne doit pas dépasser 150 caractères.',
            'Code.max'             => 'Le code ne doit pas dépasser 50 caractères.',
            'ReleaseYear.digits'   => 'L\'année de sortie doit être une année à 4 chiffres.',
            'ReleaseYear.min'      => 'L\'année de sortie n\'est pas valide.',
            'ReleaseYear.max'      => 'L\'année de sortie ne peut pas être dans le futur.',
        ];
    }
}