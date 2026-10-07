# grt-supply-nest

GRT burned and minted on Ethereum and Arbitrum One, with the bridge taken out. Two nests, one per
chain, because a nest follows one chain: `mainnet/` and `arbitrum-one/`.

The network subgraph counts every L2GraphToken `Transfer` to or from the zero address as a burn or a
mint, and a withdrawal to L1 is one of those: `bridgeBurn` emits a `Transfer` to zero for GRT that is
released from the L1 escrow, not destroyed. On Arbitrum about 99% of `totalGRTBurned` is withdrawals
([graph-network-subgraph#337](https://github.com/graphprotocol/graph-network-subgraph/issues/337)).
This nest indexes the same `Transfer` stream plus `BridgeBurned` and `BridgeMinted`, which carry the
bridge share exactly, and subtracts one from the other.

## Views

Both nests have `grt_supply` and `grt_burns_by_source`. On mainnet `grt_supply` is just `burned` and
`minted`: the Ethereum side of the bridge escrows GRT rather than burning it, so nothing comes out.
On Arbitrum:

- **`grt_supply`** - one row: `gross_burned` / `gross_minted` (what the subgraph reports), the bridge
  share of each, and `burned` / `issued` with the bridge removed. Wei, as strings.
- **`grt_burns_by_source`** - real burns grouped by the burning address (HorizonStaking, L2Curation,
  GraphPayments and the rest).

Lodestar reads both through kittiwake's `/supply` and `/supply-mainnet` mounts for `/api/grt-flow`.

## Scope

Kept apart from graph-allocations-nest because it is the whole GRT transfer stream on both chains,
millions of rows, and nuthatch filters `getLogs` on address and topic0 only. `block_timestamps` is
off: the totals need block numbers only, and fetching a header per block was 98% of the calls.

## Running

```sh
nuthatch dev --dir arbitrum-one --window 16000 --rpc <arbitrum archive RPC>
nuthatch dev --dir mainnet --window 16000 --rpc <mainnet archive RPC>
```

`--window 16000` sits under GraphOps' `getLogs` range cap of 16,384 blocks. Keyed URLs go on the command line, never in
`nuthatch.toml`.
