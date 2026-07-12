<?php

namespace App\Services\Interface;

use Illuminate\Http\UploadedFile;

interface FileUploadServiceInterface
{
    public function storeAvatar(UploadedFile $file): string;
    public function delete(?string $url): void;
}