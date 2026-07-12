<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class CreateAdminRequest extends FormRequest
{
   


    public function rules(): array
    {
        return [
            'FirstName' => 'required|string|max:100',
            'LastName' => 'required|string|max:100',
            'Email' => 'required|email|max:150|unique:users,Email',
            'Password' => 'required|string|min:8|max:255',
            'PhoneNumber' => 'nullable|string|max:20',
        ];
    }
}