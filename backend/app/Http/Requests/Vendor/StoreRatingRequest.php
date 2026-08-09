<?php
// App\Http\Requests\Vendor\StoreRatingRequest
namespace App\Http\Requests\Vendor;

use Illuminate\Foundation\Http\FormRequest;

class StoreRatingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'rating'  => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'rating.required' => 'La note est obligatoire.',
            'rating.integer'  => 'La note doit être un entier.',
            'rating.min'      => 'La note doit être comprise entre 1 et 5.',
            'rating.max'      => 'La note doit être comprise entre 1 et 5.',
            'comment.max'     => 'Le commentaire ne peut pas dépasser 1000 caractères.',
        ];
    }
}