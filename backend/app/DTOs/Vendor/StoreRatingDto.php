<?php
// App\DTOs\Vendor\StoreRatingDto
namespace App\DTOs\Vendor;

class StoreRatingDto
{
    public function __construct(
        public readonly int     $ratingID,
        public readonly int     $rating,
        public readonly ?string $comment,
        public readonly string  $commenterName,
        public readonly ?string $commenterAvatar,
    ) {}

    public static function fromRow(object $row): self
    {
        return new self(
            ratingID:         (int)   $row->RatingID,
            rating:           (int)   $row->Rating,
            comment:          $row->Comment         ?? null,
            commenterName:    $row->CommenterName,
            commenterAvatar:  $row->CommenterAvatar ?? null,
        );
    }

    public function toArray(): array
    {
        return [
            'RatingID'        => $this->ratingID,
            'Rating'          => $this->rating,
            'Comment'         => $this->comment,
            'CommenterName'   => $this->commenterName,
            'CommenterAvatar' => $this->commenterAvatar,
        ];
    }
}