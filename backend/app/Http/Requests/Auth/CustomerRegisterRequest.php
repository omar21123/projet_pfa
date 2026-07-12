<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class CustomerRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }


    public function rules(): array
    {
        return [
            'first_name' => [
                'required',
                'string',
                'max:100'
            ],

            'last_name' => [
                'required',
                'string',
                'max:100'
            ],

            'email' => [
                'required',
                'email',
                'max:255'
            ],

            'password' => [
                'required',
                'string',
                'min:8'
            ],

            'phone_number' => [
                'nullable',
                'string',
                'max:30'
            ],

            'birth_date' => [
                'nullable',
                'date'
            ],

            'gender' => [
                'nullable',
                'integer'
            ],

          'avatar' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048', // 2MB

        ];
    }
}