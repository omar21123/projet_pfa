<?php

namespace App\Http\Requests\ConfigAttributeOption;

use Illuminate\Foundation\Http\FormRequest;

class CreateConfigAttributeOptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ProductsConfigAttributeID' => ['required', 'integer'],
            'OptionLabel'               => ['required', 'string', 'max:150'],
            'OptionValue'               => ['required', 'string', 'max:150'],
            'DisplayOrder'              => ['nullable', 'integer', 'min:0'],
            'IsDefaultForAttribute'     => ['nullable', 'boolean'],
        ];
    }
}