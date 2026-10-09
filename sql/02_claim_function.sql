CREATE OR REPLACE FUNCTION claim_pending_rows(p_batch_size INTEGER)
RETURNS TABLE (
    id           BIGINT,
    external_id  VARCHAR,
    company_name VARCHAR,
    phone        VARCHAR,
    city         VARCHAR,
    industry     VARCHAR
)
LANGUAGE sql
AS $$
    UPDATE customers_staging AS c
    SET sync_status = 'IN_PROGRESS', sync_error = NULL
    WHERE c.id IN (
        SELECT s.id
        FROM customers_staging AS s
        WHERE s.sync_status = 'PENDING'
        ORDER BY s.id
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    )
    RETURNING c.id, c.external_id, c.company_name, c.phone, c.city, c.industry;
$$;