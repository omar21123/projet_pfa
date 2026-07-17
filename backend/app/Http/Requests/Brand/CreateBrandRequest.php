<?php

namespace App\Http\Requests\Brand;

use Illuminate\Foundation\Http\FormRequest;

class CreateBrandRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name'        => ['required', 'string', 'max:150'],
            'LogoURL'     => ['nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'Website'     => ['nullable', 'string', 'url', 'max:255'],
            'Description' => ['nullable', 'string'],
            'CountryID'   => ['nullable', 'integer'],
        ];
    }

    public function messages(): array
    {
        return [
            'Name.required'    => 'Le nom de la marque est obligatoire.',
            'Name.max'          => 'Le nom de la marque ne doit pas dépasser 150 caractères.',
            'LogoURL.image'     => 'Le logo doit être une image.',
            'LogoURL.mimes'     => 'Le logo doit être au format jpg, jpeg, png ou webp.',
            'LogoURL.max'       => 'Le logo ne doit pas dépasser 2 Mo.',
            'Website.url'       => 'Le site web doit être une URL valide.',
            'CountryID.exists'  => 'Le pays spécifié n\'existe pas.',
        ];
    }
}