<?php
// app/Http/Requests/Auth/DeliveryRegisterRequest.php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class DeliveryRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'first_name'     => ['required', 'string', 'max:100'],
            'last_name'      => ['required', 'string', 'max:100'],
            'email'          => ['required', 'email', 'max:255'],
            'password'       => ['required', 'string', 'min:8'],
            'phone_number'   => ['nullable', 'string', 'max:30'],
            'vehicle_type'   => ['nullable', 'string', 'max:50'],
            'license_plate'  => ['nullable', 'string', 'max:20'],
        ];
    }
}