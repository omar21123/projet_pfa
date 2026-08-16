<?php
// app/Http/Requests/Delivery/RequestWithdrawRequest.php
namespace App\Http\Requests\Delivery;

use Illuminate\Foundation\Http\FormRequest;

class RequestWithdrawRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'Amount'          => ['required', 'numeric', 'min:0.01'],
            'PaymentMethodID' => ['required', 'integer', 'min:1'],
        ];
    }
}