<?php

namespace App\Http\Requests\Promotion;

use Illuminate\Foundation\Http\FormRequest;

class CreatePromotionForCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {   
        return true; // rôle déjà vérifié par le middleware role:ADMIN
    }

    public function rules(): array
    {
        return [
            'CategoryID'         =>  ['required', 'integer', 'exists:Categories,CategoryID'],
            'Name'                => ['required', 'string', 'max:150'],
            'Description'         => ['nullable', 'string', 'max:500'],
            'PromoCode'           => ['nullable', 'string', 'max:50'],
            'DiscountTypeCode'    => ['required', 'string', 'in:PERCENTAGE,FIXED_AMOUNT'],
            'DiscountValue'       => ['required', 'numeric', 'gt:0'],
            'MaxDiscountAmount'   => ['nullable', 'numeric', 'min:0'],
            'MinOrderAmount'      => ['nullable', 'numeric', 'min:0'],
            'UsageLimitTotal'     => ['nullable', 'integer', 'min:1'],
            'UsageLimitPerUser'   => ['nullable', 'integer', 'min:1'],
            'StartDate'           => ['required', 'date'],
            'EndDate'             => ['required', 'date', 'after:StartDate'],
        ];
    }
}