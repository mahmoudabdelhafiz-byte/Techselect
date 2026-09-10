-- TechSelectAI CardIQ logo metadata
-- Uses a locally hosted CardIQ brand asset and records the official public source reference.
SET NAMES utf8mb4;

UPDATE products
SET logo_path='/media/software/cardiq.svg',
    logo_source_url='https://card-iq.net/media_kit.php?lang=en',
    logo_attribution='CardIQ by Barmageyat — official public brand reference',
    logo_last_verified_at=NOW()
WHERE slug='cardiq';
