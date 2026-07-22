<?php

namespace App\Http\Requests\Category;

use Illuminate\Foundation\Http\FormRequest;

class CreateCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // À lier à tes middlewares de rôles si nécessaire
    }

    public function rules(): array
    {
        return [
            'Name' => 'required|string|max:255',
            'ParentCategoryID' => 'nullable|integer',
            'IconURL' => 'nullable|file|image|max:2048', // 2MB max
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