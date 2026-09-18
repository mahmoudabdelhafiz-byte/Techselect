-- TechSelectAI canonical industry taxonomy seed.
-- Keeps Company context > Industry usable in fresh and partially seeded environments.
-- Preserves existing rows/IDs and only inserts missing names/slugs.
SET NAMES utf8mb4;
START TRANSACTION;

INSERT IGNORE INTO industries(name,slug) VALUES
('Agriculture','agriculture'),
('Automotive','automotive'),
('Construction','construction'),
('Consulting','consulting'),
('Education','education'),
('Energy & Oil and Gas','energy-oil-gas'),
('Engineering','engineering'),
('Financial Services','financial-services'),
('Government & Public Sector','government-public-sector'),
('Healthcare','healthcare'),
('Hospitality','hospitality'),
('Insurance','insurance'),
('Logistics & Transportation','logistics-transportation'),
('Manufacturing','manufacturing'),
('Media & Entertainment','media-entertainment'),
('Nonprofit','nonprofit'),
('Professional Services','professional-services'),
('Real Estate','real-estate'),
('Retail & E-commerce','retail-ecommerce'),
('Shipping & Maritime','shipping-maritime'),
('Technology & Software','technology-software'),
('Telecommunications','telecommunications'),
('Utilities','utilities'),
('Other','other');

COMMIT;
