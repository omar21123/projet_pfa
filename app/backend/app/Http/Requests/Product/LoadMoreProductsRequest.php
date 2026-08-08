<?php

namespace App\Http\Requests\Product;

use Illuminate\Foundation\Http\FormRequest;

class LoadMoreProductsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'page'      => $this->query('page', 1),
            'page_size' => $this->query('page_size', 20),
        ]);
    }

    public function rules(): array
    {
        return [
            'page'         => 'nullable|integer|min:1',
            'page_size'    => 'nullable|integer|min:1|max:100',
            'category_id'  => 'nullable|integer|min:1|exists:Categories,CategoryID',
            'days_back'    => 'nullable|integer|min:1',
        ];
    }
}