<?php

namespace App\Http\Requests\Address;

use Illuminate\Foundation\Http\FormRequest;
use OpenApi\Attributes as OA;

#[OA\Schema(schema: "UserIDRequest")]
class UserIDRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => ['required', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'user_id.required' => 'Le UserID est obligatoire.',
            'user_id.integer'  => 'Le UserID doit être un entier.',
        ];
    }
}
