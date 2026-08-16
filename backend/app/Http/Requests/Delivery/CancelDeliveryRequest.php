<?php
// app/Http/Requests/Delivery/CancelDeliveryRequest.php
namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class CancelDeliveryRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'Reason' => ['nullable', 'string', 'max:500'],
        ];
    }
}