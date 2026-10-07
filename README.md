# grt-supply-nest

GRT minted and burned on Arbitrum One, with the bridge taken out.

The network subgraph counts every L2GraphToken `Transfer` to or from the zero address as a burn or a
mint, and a withdrawal to L1 is one of those: `bridgeBurn` emits a `Transfer` to zero for GRT that is
released from the L1 escrow, not destroyed. On Arbitrum about 99% of `totalGRTBurned` is withdrawals
([graph-network-subgraph#337](https://github.com/graphprotocol/graph-network-subgraph/issues/337)).
This nest indexes the same `Transfer` stream plus `BridgeBurned` and `BridgeMinted`, which carry the
bridge share exactly, and subtracts one from the other.

## Views

- **`grt_supply`** - one row: `gross_burned` / `gross_minted` (what the subgraph reports), the bridge
  share of each, and `burned` / `issued` with the bridge removed. Wei, as strings.
- **`grt_burns_by_source`** - real burns grouped by the burning address (HorizonStaking, L2Curation,
  GraphPayments and the rest).

Lodestar reads `grt_supply` through kittiwake's `/supply` mount for `/api/grt-flow`.

## Scope

Arbitrum only. Burns on Ethereum L1 (about 27M GRT, the bulk before the move to L2) need a mainnet
nest; a nest is one chain.

Kept apart from graph-allocations-nest because it is the whole GRT transfer stream, over ten million
rows, and nuthatch filters `getLogs` on address and topic0 only.

## Running

```sh
nuthatch dev --dir . --window 81920
```

`--window 81920` is what `nuthatch doctor --address 0x9623…88c7` recommends on arb1.arbitrum.io.
