-- GRT burned and minted on Ethereum. No bridge correction: the L1 side of the bridge escrows.
CREATE VIEW grt_supply AS
SELECT CAST(coalesce(sum(CAST(value AS HUGEINT)) FILTER (
           WHERE "to" = '0x0000000000000000000000000000000000000000'), 0) AS VARCHAR) AS burned,
       CAST(coalesce(sum(CAST(value AS HUGEINT)) FILTER (
           WHERE "from" = '0x0000000000000000000000000000000000000000'), 0) AS VARCHAR) AS minted
FROM graph_token__transfer
WHERE "from" <> "to"
  AND ("from" = '0x0000000000000000000000000000000000000000'
    OR "to"   = '0x0000000000000000000000000000000000000000');

CREATE VIEW grt_burns_by_source AS
SELECT "from" AS burner, count(*) AS burns, CAST(sum(CAST(value AS HUGEINT)) AS VARCHAR) AS burned
FROM graph_token__transfer
WHERE "to" = '0x0000000000000000000000000000000000000000' AND "from" <> "to"
GROUP BY "from"
ORDER BY sum(CAST(value AS HUGEINT)) DESC;
