<?php
// App\Http\Requests\Address\AddressRequest
namespace App\Http\Requests\Address;

use Illuminate\Foundation\Http\FormRequest;

class AddressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'full_name'          => ['required', 'string', 'max:150'],
            'phone'              => ['nullable', 'string', 'max:20'],
            'country'            => ['required', 'string', 'max:100'],
            'region'             => ['nullable', 'string', 'max:100'],
            'city'               => ['required', 'string', 'max:100'],
            'postal_code'        => ['nullable', 'string', 'max:20'],
            'address_line1'      => ['required', 'string', 'max:255'],
            'address_line2'      => ['nullable', 'string', 'max:255'],
            'landmark'           => ['nullable', 'string', 'max:255'],
            'latitude'           => ['nullable', 'numeric', 'between:-90,90'],
            'longitude'          => ['nullable', 'numeric', 'between:-180,180'],
            'is_default_shipping'=> ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'full_name.required'     => 'Le nom complet est obligatoire.',
            'country.required'       => 'Le pays est obligatoire.',
            'city.required'          => 'La ville est obligatoire.',
            'address_line1.required' => 'L\'adresse (ligne 1) est obligatoire.',
            'latitude.between'       => 'La latitude doit être comprise entre -90 et 90.',
            'longitude.between'      => 'La longitude doit être comprise entre -180 et 180.',
        ];
    }
}