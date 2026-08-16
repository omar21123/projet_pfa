<?php
// app/Http/Requests/Delivery/RemitCashRequest.php
namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class RemitCashRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'ExpectedAmount' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}