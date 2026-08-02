<?php

namespace App\Http\Requests\Cart;

use Illuminate\Foundation\Http\FormRequest;

class GetCartRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Nécessite un utilisateur authentifié — le panier est résolu via son UserID.
        return true;
    }

    public function rules(): array
    {
        // Aucun paramètre d'entrée : le panier est entièrement déterminé par
        // l'utilisateur authentifié (user_id injecté par le middleware auth).
        return [];
    }
}