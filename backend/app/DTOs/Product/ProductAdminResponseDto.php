<?php

namespace App\DTOs\Product;

class ProductAdminResponseDto
{
    public function __construct(
        public readonly int $productId,
        public readonly string $productName,
        public readonly ?string $fullName,
        public readonly ?string $brandName,
        public readonly ?string $brandLogo,
        public readonly ?string $modelName,
        public readonly ?string $status,
        public readonly ?string $createdAt,
        public readonly ?int $refuseAttempt,
        public readonly ?string $refuseNotes,
        public readonly ?string $refusedBy,
        public readonly ?string $refuseAt,
        public readonly ?string $validatorBy,
        public readonly ?string $validationNotes,
        public readonly ?string $validationDate,
        public readonly bool $isActive,
        public readonly ?string $deletedAt,
        public readonly bool $isBlocked,
        public readonly ?string $blockedDate,
        public readonly ?string $blockedNotes,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            productId: (int) $row->ProductId,
            productName: $row->ProductName,
            fullName: $row->FullName,
            brandName: $row->BrandName,
            brandLogo: $row->BrandLogo,
            modelName: $row->ModelName,
            status: $row->Status,
            createdAt: $row->CreatedAt,
            refuseAttempt: $row->RefuseAttempt !== null ? (int) $row->RefuseAttempt : null,
            refuseNotes: $row->RefuseNotes,
            refusedBy: $row->RefusedBy,
            refuseAt: $row->RefuseAt,
            validatorBy: $row->ValidatorBy,
            validationNotes: $row->ValidationNotes,
            validationDate: $row->ValidationDate,
            isActive: (bool) $row->IsActive,
            deletedAt: $row->DeletedAt,
            isBlocked: (bool) $row->IsBlocked,
            blockedDate: $row->BlockedDate,
            blockedNotes: $row->BlockedNotes,
        );
    }

    public function toArray(): array
    {
        return [
            'product_id'       => $this->productId,
            'product_name'     => $this->productName,
            'full_name'        => $this->fullName,
            'brand_name'       => $this->brandName,
            'brand_logo'       => $this->brandLogo,
            'model_name'       => $this->modelName,
            'status'           => $this->status,
            'created_at'       => $this->createdAt,
            'refuse_attempt'   => $this->refuseAttempt,
            'refuse_notes'     => $this->refuseNotes,
            'refused_by'       => $this->refusedBy,
            'refuse_at'        => $this->refuseAt,
            'validator_by'     => $this->validatorBy,
            'validation_notes' => $this->validationNotes,
            'validation_date'  => $this->validationDate,
            'is_active'        => $this->isActive,
            'deleted_at'       => $this->deletedAt,
            'is_blocked'       => $this->isBlocked,
            'blocked_date'     => $this->blockedDate,
            'blocked_notes'    => $this->blockedNotes,
        ];
    }
}