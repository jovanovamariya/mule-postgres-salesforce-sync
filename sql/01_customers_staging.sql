-- 01_customers_staging.sql
-- Staging table for the PostgreSQL -> Salesforce sync project.

-- 1. Staging table
CREATE TABLE customers_staging (
    id            BIGSERIAL PRIMARY KEY,
    external_id   VARCHAR(50)  NOT NULL UNIQUE,   -- business key, maps to External_Customer_ID__c in Salesforce
    company_name  VARCHAR(255) NOT NULL,
    phone         VARCHAR(30),
    city          VARCHAR(100),
    industry      VARCHAR(50),
    sync_status   VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                  CHECK (sync_status IN ('PENDING', 'IN_PROGRESS', 'SYNCED', 'FAILED')),
    sync_error    TEXT,                           -- Salesforce error message for FAILED rows
    synced_at     TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 2. Generate 100,000 test rows
INSERT INTO customers_staging (external_id, company_name, phone, city, industry)
SELECT
    'CUST-' || lpad(g::text, 6, '0'),
    'Company ' || g,
    '+3897' || lpad(floor(random() * 10000000)::int::text, 7, '0'),
    (ARRAY['Skopje','Bitola','Ohrid','Tetovo','Kumanovo','Prilep','Veles','Stip'])[1 + (g % 8)],
    (ARRAY['Banking','Technology','Retail','Healthcare','Energy','Manufacturing'])[1 + (g % 6)]
FROM generate_series(1, 100000) AS g;

-- 3. Partial index: covers only rows still waiting to be synced,
--    so the polling query stays fast as rows become SYNCED
CREATE INDEX idx_customers_pending
    ON customers_staging (id)
    WHERE sync_status = 'PENDING';

-- 4. Refresh planner statistics
ANALYZE customers_staging;