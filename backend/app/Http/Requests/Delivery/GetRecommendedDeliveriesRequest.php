<?php
// app/Http/Requests/Delivery/GetRecommendedDeliveriesRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class GetRecommendedDeliveriesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'max_distance_km' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'page'             => ['nullable', 'integer', 'min:1'],
            'per_page'         => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}