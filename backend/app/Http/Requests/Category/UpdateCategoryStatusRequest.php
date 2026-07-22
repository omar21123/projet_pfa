<?php
namespace App\Http\Requests\Category;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCategoryStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'IsActive' => 'required|boolean',
        ];
    }

    /**
     * Convenience wrapper to mirror other requests and support
     * `$request->validated('IsActive')` usage.
     */
    public function validated($key = null, $default = null)
    {
        $data = parent::validated();

        if ($key === null) {
            return $data;
        }

        return $data[$key] ?? $default;
    }
}
