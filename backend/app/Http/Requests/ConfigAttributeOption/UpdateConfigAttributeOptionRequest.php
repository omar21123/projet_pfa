<?php

namespace App\Http\Requests\ConfigAttributeOption;

use Illuminate\Foundation\Http\FormRequest;

class UpdateConfigAttributeOptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ProductsConfigAttributeID' => ['sometimes', 'required', 'integer'],
            'OptionLabel'               => ['sometimes', 'required', 'string', 'max:150'],
            'OptionValue'               => ['sometimes', 'required', 'string', 'max:150'],
            'DisplayOrder'              => ['nullable', 'integer', 'min:0'],
            'IsDefaultForAttribute'     => ['nullable', 'boolean'],
        ];
    }
}