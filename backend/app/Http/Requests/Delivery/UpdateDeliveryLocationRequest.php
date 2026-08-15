<?php
// app/Http/Requests/Delivery/UpdateDeliveryLocationRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDeliveryLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Latitude'  => ['required', 'numeric', 'between:-90,90'],
            'Longitude' => ['required', 'numeric', 'between:-180,180'],
        ];
    }
}