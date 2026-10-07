-- GRT burned and issued on Arbitrum, with the bridge taken out (graph-network-subgraph#337).
--
-- `gross_*` is what the network subgraph reports as totalGRTBurned / totalGRTMinted. A withdrawal
-- to L1 emits a `Transfer` to zero and a `BridgeBurned` for the same amount in the same tx; the GRT
-- is released from the L1 escrow, not destroyed. Subtracting the bridge events leaves what was
-- actually burned or newly issued on L2.
CREATE VIEW grt_supply AS
WITH t AS (
  SELECT CAST(value AS HUGEINT) AS v,
         "from" = '0x0000000000000000000000000000000000000000' AS is_mint,
         "to"   = '0x0000000000000000000000000000000000000000' AS is_burn
  FROM graph_token__transfer
  WHERE "from" <> "to"
    AND ("from" = '0x0000000000000000000000000000000000000000'
      OR "to"   = '0x0000000000000000000000000000000000000000')
)
SELECT CAST((SELECT coalesce(sum(v), 0) FROM t WHERE is_burn) AS VARCHAR) AS gross_burned,
       CAST((SELECT coalesce(sum(CAST(amount AS HUGEINT)), 0) FROM graph_token__bridge_burned) AS VARCHAR) AS bridge_burned,
       CAST((SELECT coalesce(sum(v), 0) FROM t WHERE is_burn)
          - (SELECT coalesce(sum(CAST(amount AS HUGEINT)), 0) FROM graph_token__bridge_burned) AS VARCHAR) AS burned,
       CAST((SELECT coalesce(sum(v), 0) FROM t WHERE is_mint) AS VARCHAR) AS gross_minted,
       CAST((SELECT coalesce(sum(CAST(amount AS HUGEINT)), 0) FROM graph_token__bridge_minted) AS VARCHAR) AS bridge_minted,
       CAST((SELECT coalesce(sum(v), 0) FROM t WHERE is_mint)
          - (SELECT coalesce(sum(CAST(amount AS HUGEINT)), 0) FROM graph_token__bridge_minted) AS VARCHAR) AS issued;

-- Real burns by the contract that burned them: HorizonStaking, L2Curation, GraphPayments and so on.
CREATE VIEW grt_burns_by_source AS
SELECT b."from" AS burner,
       count(*) AS burns,
       CAST(sum(CAST(b.value AS HUGEINT)) AS VARCHAR) AS burned
FROM graph_token__transfer b
WHERE b."to" = '0x0000000000000000000000000000000000000000'
  AND b."from" <> b."to"
  AND NOT EXISTS (SELECT 1 FROM graph_token__bridge_burned x
                  WHERE x.tx_hash = b.tx_hash AND CAST(x.amount AS HUGEINT) = CAST(b.value AS HUGEINT))
GROUP BY b."from"
ORDER BY sum(CAST(b.value AS HUGEINT)) DESC;
