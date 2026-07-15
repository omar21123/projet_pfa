<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class VendorRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'first_name'   => 'required|string|max:100',
            'last_name'    => 'required|string|max:100',
            'email'        => 'required|email|max:255',
            'password'     => 'required|string|min:8',
            'phone_number' => 'nullable|string|max:30',
            'birth_date'   => 'nullable|date',
            'gender'       => 'nullable|integer|in:1,2',
            'avatar'       => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',

            'store_name'   => 'required|string|max:150',
            'description'  => 'nullable|string|max:2000',
        ];
    }

    public function messages(): array
    {
        return [
            'store_name.required' => 'Le nom de la boutique est requis.',
        ];
    }
}