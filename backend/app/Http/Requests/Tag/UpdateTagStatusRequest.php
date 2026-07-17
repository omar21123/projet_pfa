<?php

namespace App\Http\Requests\Tag;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTagStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'IsActive' => ['required', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'IsActive.required' => 'Le statut actif est obligatoire.',
            'IsActive.boolean'   => 'Le statut actif doit être vrai ou faux.',
        ];
    }
}