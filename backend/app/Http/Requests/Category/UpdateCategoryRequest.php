<?php
namespace App\Http\Requests\Category;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Name' => 'required|string|max:255',
            'IconURL' => 'nullable|url|max:2048',
            'DisplayOrder' => 'nullable|integer',
            'IsActive' => 'required|boolean',
        ];
    }

    /**
     * Convenience wrapper to keep compatibility with DTOs calling
     * `$request->validated('Key', $default)` throughout the codebase.
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