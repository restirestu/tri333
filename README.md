# Tri333 (T333) — Agent-ID-Gated NFT Collection on BNB Chain

Tri333 is a live ERC-721 collection of 3,333 NFTs on BNB Chain whose free
distribution is gated entirely by **Binance Agent ID**. Agent ID is not an
add-on here — it is the eligibility identity for the entire free phase.

**Submitted to the Binance Agent ID Hackathon (submission period
2026-11-18 – 2026-12-09 UTC).**

## How Agent ID is integrated

The gate lives in the smart contract itself (`contracts/Tri333.sol`):

- The contract stores the official SPACE ID Agent ID registry
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, an ERC-721) as
  `agentIdRegistry`.
- On every free mint, the contract checks `agentIdRegistry.balanceOf(msg.sender) > 0`.
  Wallets without an Agent ID cannot mint in the free phase — the check is
  enforced on-chain, not by a website or an allowlist file.
- Each Agent ID holder may free-mint up to **2** NFTs from a free pool of
  **2,222**. Once the free pool is fully minted, the paid phase
  (1,111 NFTs at a flat 0.00005 BNB) unlocks automatically.
- Result so far: **1,353 NFTs minted, all through the Agent-ID-gated free
  phase**, with 869 free slots still open for Agent ID holders.

For users, a single non-transferable Agent ID becomes instant access — no
allowlist registration, no screenshots, no manual review. For the ecosystem,
Tri333 demonstrates Agent ID as a reusable, Sybil-resistant access
credential for on-chain distribution: eligibility is tied to a verified
identity instead of easily farmed wallet addresses.

## Contract

| | |
|---|---|
| Network | BNB Chain (BSC) |
| Contract | `0x157D860e30b6c6d4dC0abe3bD6e66e659A9d524f` |
| BscScan | https://bscscan.com/address/0x157D860e30b6c6d4dC0abe3bD6e66e659A9d524f |
| Verification | Sourcify exact match (creation + runtime), verified and open-source |
| Standard | ERC-721 + ERC-2981 royalties (5%) |
| Supply | 3,333 (free pool 2,222 Agent-ID-gated · paid 1,111 @ 0.00005 BNB) |
| Token | None — Tri333 is a standalone NFT collection |

## Links

- Mint site (live): https://tri333-mint-4.netlify.app
- X: https://x.com/Hokiseries

## Build notes

Solidity ^0.8.20, OpenZeppelin (ERC721, ERC2981, Ownable, ReentrancyGuard).
The deployed bytecode matches this source (Sourcify exact match).
