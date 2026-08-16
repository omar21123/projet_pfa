<?php
// app/Http/Requests/Vendor/RequestVendorWithdrawRequest.php
namespace App\Http\Requests\Vendor;

use Illuminate\Foundation\Http\FormRequest;

class RequestVendorWithdrawRequest extends FormRequest
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