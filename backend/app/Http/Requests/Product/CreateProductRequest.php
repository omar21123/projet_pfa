<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class CreateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'BrandID'                  => ['nullable', 'integer'],
            'ModelID'                  => ['nullable', 'integer'],
            'Name'                     => ['required', 'string', 'max:255'],
            'Barcode'                  => ['required', 'string', 'max:100'],
            'Description'              => ['nullable', 'string'],
            'BasePrice'                => ['required', 'numeric', 'min:0'],
            'Stock'                    => ['required', 'integer', 'min:0'],

            'Ressource'                => ['required', 'array', 'min:1'],
            'Ressource.*.file'         => ['required', 'file', 'max:51200'], // 50MB
            'Ressource.*.type'         => ['required', 'string', 'in:video,Image,image,Video'],
            'Ressource.*.Role'         => ['required', 'integer'],

            'Categories'               => ['required', 'array', 'min:1'],
            'Categories.*'             => ['integer'],

            'Attribute'                          => ['nullable', 'array'],
            'Attribute.*.ConfigName'             => ['required_with:Attribute', 'string', 'max:150'],
            'Attribute.*.ConfigOptions'          => ['required_with:Attribute', 'array', 'min:1'],
            'Attribute.*.ConfigOptions.*.Name'   => ['required', 'string', 'max:150'],
            'Attribute.*.ConfigOptions.*.IsDefault' => ['nullable', 'boolean'],

            'Tags'                     => ['nullable', 'array'],
            'Tags.*'                   => ['string', 'max:100'],

            'AllowedPayment'           => ['required', 'array', 'min:1'],
            'AllowedPayment.*'         => ['integer'],
        ];
    }

    public function messages(): array
    {
        return [
            'Ressource.required'        => 'Au moins une ressource (vidéo/image) est requise.',
            'Ressource.*.file.required' => 'Chaque ressource doit contenir un fichier.',
            'Categories.required'       => 'Au moins une catégorie est requise.',
            'AllowedPayment.required'   => 'Au moins un mode de paiement est requis.',
        ];
    }
}
