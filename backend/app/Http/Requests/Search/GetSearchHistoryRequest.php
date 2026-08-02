<?php

namespace App\Http\Requests\Search;

use Illuminate\Foundation\Http\FormRequest;

class GetSearchHistoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        // L'utilisateur doit être authentifié — vérifié par le middleware JWT
        // en amont, pas ici. La résolution UserID/existence reste dans le controller.
        return true;
    }

    protected function prepareForValidation(): void
    {
        // Applique les valeurs par défaut avant validation, pour que les règles
        // ci-dessous s'appliquent aussi bien à la valeur fournie qu'au défaut.
        $this->merge([
            'latest_limit' => $this->query('latest_limit', 10),
            'famous_limit' => $this->query('famous_limit', 10),
        ]);
    }

    public function rules(): array
    {
        return [
            'latest_limit' => 'nullable|integer|min:1|max:50',
            'famous_limit' => 'nullable|integer|min:1|max:50',
        ];
    }

    public function messages(): array
    {
        return [
            'latest_limit.integer' => 'latest_limit doit être un nombre entier.',
            'latest_limit.min'     => 'latest_limit doit être au moins 1.',
            'latest_limit.max'     => 'latest_limit ne doit pas dépasser 50.',
            'famous_limit.integer' => 'famous_limit doit être un nombre entier.',
            'famous_limit.min'     => 'famous_limit doit être au moins 1.',
            'famous_limit.max'     => 'famous_limit ne doit pas dépasser 50.',
        ];
    }
}