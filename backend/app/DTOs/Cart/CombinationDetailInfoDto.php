<?php
// App\DTOs\Cart\CombinationDetailInfoDto
namespace App\DTOs\Cart;

class CombinationDetailInfoDto
{
    public function __construct(
        public readonly int $combinationDetailId,
        public readonly int $attributeId,
        public readonly string $configName,
        public readonly string $optionLabel,
        public readonly int $optionId,
    ) {}
    public function toArray(): array
{
    return [
        'CombinationDetailID' => $this->combinationDetailId,
        'AttributeID'         => $this->attributeId,
        'ConfigName'          => $this->configName,
        'OptionLabel'         => $this->optionLabel,
        'OptionID'            => $this->optionId,
    ];
}
    public static function fromRow(object $row): self
    {
        return new self(
            combinationDetailId: (int) $row->CombinationDetailID,
            attributeId: (int) $row->AttributeID,
            configName: $row->ConfigName,
            optionLabel: $row->OptionLabel,
            optionId: (int) $row->OptionID,
        );
    }
}