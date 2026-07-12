<?php

namespace App\Services;

use App\Services\Interface\FileUploadServiceInterface;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class FileUploadService implements FileUploadServiceInterface
{
    public function storeAvatar(UploadedFile $file): string
    {
        $path = $file->store('avatars', 'public');
        return Storage::disk('public')->url($path);
    }

    public function delete(?string $url): void
    {
        if (!$url) {
            return;
        }

        $path = str_replace('/storage/', '', parse_url($url, PHP_URL_PATH));
        Storage::disk('public')->delete($path);
    }
}