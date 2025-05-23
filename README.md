---

#  StaxPicks: A Prediction Market Smart Contract

**StaxPicks** is a decentralized prediction market built using the Clarity smart contract language on the Stacks blockchain. This contract allows users to create markets, place bets, and claim winnings based on the outcome of real-world events.

## 🧾 Features

* **Create Prediction Markets**: Users can create markets with multiple options and a specified end block.
* **Bet Placement**: Users can place STX-based bets on any available option before the market closes.
* **Market Settlement**: Creators settle the market with the correct outcome after the event.
* **Winnings Calculation**: Winnings are proportionally distributed among winners based on their bet sizes.
* **Partial/Full Claim**: Users can claim their winnings partially or fully, anytime after market settlement.
* **Immutable Ledger**: Uses Stacks smart contract maps for permanent and transparent record keeping.

---

## ⚙️ Contract Architecture

### ✅ Data Maps

* **`markets`**: Stores market details such as creator, description, options, and resolution status.
* **`bets`**: Tracks bets per user per market per option.
* **`option-totals`**: Records total STX bet on each option per market.

### ✅ Data Variables

* **`market-nonce`**: Auto-incrementing ID for new markets.

### ✅ Constants

Error codes for validation:

* `ERR-NOT-FOUND`, `ERR-UNAUTHORIZED`, `ERR-ALREADY-SETTLED`, `ERR-MARKET-ACTIVE`, `ERR-INVALID-INPUT`, `ERR-INSUFFICIENT-BALANCE`, `ERR-ALREADY-CLAIMED`

---

## 🛠️ Functions

### 🏗️ Market Management

#### `create-market`

Creates a new prediction market.

```clojure
(create-market description options end-block)
```

#### `settle-market`

Allows the creator to settle the market with the winning option.

```clojure
(settle-market market-id winning-option)
```

### 🎲 Betting

#### `place-bet`

Place a bet on a specific option in a market.

```clojure
(place-bet market-id option amount)
```

### 💸 Claiming Winnings

#### `claim-partial-winnings`

Claim part of your winnings.

```clojure
(claim-partial-winnings market-id option amount-to-claim)
```

#### `claim-all-winnings`

Claim all unclaimed winnings.

```clojure
(claim-all-winnings market-id option)
```

### 🔍 Read-Only Utilities

* `get-market`
* `get-bet`
* `get-option-total`
* `get-unclaimed-amount`
* `calculate-winnings`

---

## 🔐 Access Controls

* Only the market **creator** can call `settle-market`.
* Users can only claim winnings on markets that have been settled, and only for options they bet on.

---

## ✅ Validation & Safety

* Markets cannot be created with empty descriptions or invalid option lists.
* Betting is only allowed before the market's end-block.
* Claims are only processed if the bet matches the winning option and hasn't been fully claimed.

---

## 📊 Payout Logic

Winnings are distributed proportionally:

```
user_winnings = (user_bet_amount / total_bet_on_option) * total_bets
```

---

## 🚀 Deployment

Deploy the contract to the Stacks blockchain using Clarity tools such as:

* Clarinet ([https://github.com/hirosystems/clarinet](https://github.com/hirosystems/clarinet))
* Stacks CLI
* Hiro Web IDE

---

## 📘 Example Use Case

1. Alice creates a market: "Will BTC reach \$100k by Dec 2025?"
2. Bob bets 100 STX on "Yes", Charlie bets 50 STX on "No".
3. On Jan 1, 2026, Alice settles the market with the result "Yes".
4. Bob claims his winnings (100 / 100) \* 150 = 150 STX.
5. Charlie gets nothing.

---
