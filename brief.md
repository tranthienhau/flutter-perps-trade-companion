# Dispatch - Source Brief

## Title
Dispatch - trading companion for crypto perpetuals

## Description
Dispatch is a mobile companion app for a leveraged crypto perpetuals exchange. A trader signs in with Apple or Google, picks BTC, ETH or SOL, chooses Long or Short, enters now or when a price is hit, sets a bet size, leverage and an optional take profit / stop loss pair, and taps Post trade. The first post asks for a wallet once: one signature proves ownership and one grants a 30-day, trade-only session key, so later trades and closes go out without a wallet pop-up. Waiting orders and completed results live in one Orders list, and open trades show live profit and loss with a one-tap close. Half of the app's builder fee is shared back to traders every week in USDC.

## Store links
Not yet published (POC).

## Platform
Both - iOS and Android from one Flutter codebase.

## Category
Finance - trading.

## Features
- Sign in with Apple or Google only - no email, password or phone number
- Full trade screen before any wallet is connected
- Markets BTC, ETH, SOL with live reference prices and per-market max leverage
- Long or Short, Now or When price hits (trigger orders)
- Bet size chips, leverage slider, position size and estimated liquidation
- Take profit / stop loss with a price-or-percent keypad editor
- Visual price scale: liquidation, stop loss, entry or trigger, current price, take profit
- Wallet connect as bottom sheets: MetaMask, Coinbase Wallet, Rainbow, Trust Wallet, WalletConnect
- Two signatures: ownership proof, then an EIP-712 permission for a 30-day trade-only session key
- Expiry handling: warning at 5 days left, blocking re-sign when expired or when a new trade's exits could outlive the key
- Orders: waiting trigger orders with distance to price and cancel, completed results
- Positions: live P&L, entry, mark, size, liquidation, TP/SL tags, close without a wallet pop-up
- Settings: account, wallet and permission status, renew, disconnect, notification toggles
- Weekly rewards: estimated USDC share, volume, margin risked, rank, payout history
- Signer service: per-user agent keys with envelope encryption, action allowlist, hash-chained audit log, weekly payout job

## Tech stack
- Flutter + Dart, Riverpod for state
- Inter + Familjen Grotesk bundled fonts, tabular numerals
- EIP-712 typed-data encoding and keccak256 (pointycastle)
- integration_test screenshot harness and hands-free demo autopilot
- Node 20 signer service with ethers v6, AES-256-GCM envelope encryption, node:test

## Industry
Fintech - crypto derivatives.

## Metrics
Unpublished POC, no store ratings or downloads. Scope: 18 captured screens covering sign-in, wallet connect, permission, trade building, orders, positions, settings, rewards and expiry states. 6 Flutter unit tests and 8 backend tests.

## Research notes
- Verified: EIP-712 encoder output checked against the spec's `Person` type-hash vector; backend signatures verify against the agent address on the same domain; forged registration signatures are rejected; tampered audit entries fail verification.
- Mocked: reference prices (seeded random walk), wallet app signatures, the exchange POST and live state feed, Google/Apple auth, push notifications, USDC payout transfers.
- Future expansion: real WalletConnect v2 session, Firebase auth and FCM push, exchange integration against the live state feed, KMS-backed master key, managed-container deploy with CI for staging and production, Play internal testing and TestFlight builds.
