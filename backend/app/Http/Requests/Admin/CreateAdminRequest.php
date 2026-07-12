<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class CreateAdminRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // gate/policy handled by middleware (bearerAuth + admin role)
    }

    public function rules(): array
    {
        return [
            'first_name'      => ['required', 'string', 'max:100'],
            'last_name'       => ['required', 'string', 'max:100'],
            'email'           => ['required', 'email', 'max:255'],
            'password'        => ['required', 'string', 'min:8'],
            'phone_number'    => ['nullable', 'string', 'max:30'],
            'birth_date'      => ['nullable', 'date'],
            'gender'          => ['nullable', 'integer', 'in:1,2'],
            'cin'             => ['nullable', 'string', 'max:30'],
            'employee_number' => ['nullable', 'string', 'max:30'],
            'position'        => ['nullable', 'string', 'max:30'],
            'hire_date'       => ['nullable', 'date'],
            'avatar_url'      => ['nullable', 'url', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'first_name.required'      => 'Le prénom est requis.',
            'last_name.required'       => 'Le nom est requis.',
            'email.required'           => 'L\'email est requis.',
            'email.email'              => 'L\'email doit être une adresse valide.',
            'password.required'        => 'Le mot de passe est requis.',
            'password.min'             => 'Le mot de passe doit contenir au moins 8 caractères.',
            'gender.in'                => 'Le genre doit être 1 (Homme) ou 2 (Femme).',
            'avatar_url.url'           => 'L\'URL de l\'avatar est invalide.',
        ];
    }
}