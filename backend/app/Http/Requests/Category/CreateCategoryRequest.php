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
            'name' => 'required|string|max:255',
            'parentCategoryID' => 'nullable|integer|exists:categories,CategoryID',
            'iconURL' => 'nullable|url|max:2048',
            'isActive' => 'nullable|boolean',
            'displayOrder' => 'nullable|integer',
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