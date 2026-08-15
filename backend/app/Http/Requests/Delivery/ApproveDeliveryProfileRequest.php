<?php
// app/Http/Requests/Delivery/ApproveDeliveryProfileRequest.php

namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class ApproveDeliveryProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [];
        // no body needed — DeliveryProfileID comes from route, ApprovedBy from JWT
    }
}