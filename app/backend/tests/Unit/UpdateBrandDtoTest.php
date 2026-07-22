<?php

namespace Tests\Unit;

use App\DTOs\Brand\UpdateBrandDto;
use Illuminate\Http\Request;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class UpdateBrandDtoTest extends TestCase
{
    #[Test]
    public function it_allows_missing_name_when_building_an_update_dto(): void
    {
        $request = Request::create('/api/brands/1', 'PUT', ['Website' => 'https://example.com']);

        $dto = UpdateBrandDto::fromRequest($request, null, (object) [
            'Name' => 'Existing Brand',
            'Website' => 'https://old.example.com',
            'Description' => 'Old description',
            'CountryID' => 12,
        ]);

        $this->assertSame('Existing Brand', $dto->name);
        $this->assertSame('https://example.com', $dto->website);
        $this->assertSame('Old description', $dto->description);
        $this->assertSame(12, $dto->countryID);
    }
}
