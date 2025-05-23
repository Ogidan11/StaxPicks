;; WagerWise: A Prediction Market Smart Contract

;; Define data maps
(define-map markets
  { market-id: uint }
  {
    creator: principal,
    description: (string-utf8 256),
    options: (list 10 (string-utf8 64)),
    end-block: uint,
    total-bets: uint,
    is-settled: bool,
    winning-option: (optional uint)
  }
)

;; Track bets with claimed amount
(define-map bets
  { market-id: uint, better: principal, option: uint }
  { 
    amount: uint,
    claimed-amount: uint  ;; Track how much has been claimed
  }
)

;; Track total amount bet per option
(define-map option-totals
  { market-id: uint, option: uint }
  { total-amount: uint }
)

;; Define data variables
(define-data-var market-nonce uint u0)

;; Error constants
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-ALREADY-SETTLED (err u409))
(define-constant ERR-MARKET-ACTIVE (err u400))
(define-constant ERR-INVALID-INPUT (err u422))
(define-constant ERR-INSUFFICIENT-BALANCE (err u423))
(define-constant ERR-ALREADY-CLAIMED (err u424))

;; Helper functions for input validation
(define-private (validate-string (input (string-utf8 256)))
  (< u0 (len input))
)

(define-private (validate-options (options (list 10 (string-utf8 64))))
  (and (< u0 (len options)) (<= (len options) u10))
)

(define-private (validate-end-block (end-block uint))
  (> end-block block-height)
)

(define-private (validate-market-id (market-id uint))
  (and 
    (>= market-id u0) 
    (< market-id (var-get market-nonce))
  )
)

;; Helper function to update option totals
(define-private (update-option-total (market-id uint) (option uint) (amount uint))
  (let
    (
      (current-total (default-to { total-amount: u0 } 
        (map-get? option-totals { market-id: market-id, option: option })))
    )
    (map-set option-totals
      { market-id: market-id, option: option }
      { total-amount: (+ (get total-amount current-total) amount) }
    )
  )
)



;; Calculate total winnings for a bet
(define-read-only (calculate-winnings (market-id uint) (option uint) (bet-amount uint))
  (let
    (
      (market (unwrap! (map-get? markets { market-id: market-id }) ERR-NOT-FOUND))
      (option-total (unwrap! (map-get? option-totals { market-id: market-id, option: option }) ERR-NOT-FOUND))
    )
    (ok (/ (* (get total-bets market) bet-amount) (get total-amount option-total)))
  )
)

;; Claim partial winnings
(define-public (claim-partial-winnings (market-id uint) (option uint) (amount-to-claim uint))
  (begin
    (asserts! (validate-market-id market-id) ERR-INVALID-INPUT)
    (let
      (
        (market (unwrap! (map-get? markets { market-id: market-id }) ERR-NOT-FOUND))
        (bet (unwrap! (map-get? bets { market-id: market-id, better: tx-sender, option: option }) ERR-NOT-FOUND))
        (winning-option (unwrap! (get winning-option market) ERR-NOT-FOUND))
      )
      (asserts! (get is-settled market) ERR-MARKET-ACTIVE)
      (asserts! (is-eq option winning-option) ERR-UNAUTHORIZED)
      (asserts! (<= (+ (get claimed-amount bet) amount-to-claim) (get amount bet)) ERR-INSUFFICIENT-BALANCE)

      (let
        (
          (total-bets (get total-bets market))
          (winning-amount (unwrap! (calculate-winnings market-id option amount-to-claim) ERR-INVALID-INPUT))
        )
        ;; Transfer winnings
        (try! (as-contract (stx-transfer? winning-amount tx-sender tx-sender)))

        ;; Update claimed amount
        (map-set bets
          { market-id: market-id, better: tx-sender, option: option }
          { 
            amount: (get amount bet),
            claimed-amount: (+ (get claimed-amount bet) amount-to-claim)
          }
        )

        ;; If fully claimed, delete the bet
        (if (is-eq (+ (get claimed-amount bet) amount-to-claim) (get amount bet))
          (map-delete bets { market-id: market-id, better: tx-sender, option: option })
          true
        )

        (ok winning-amount)
      )
    )
  )
)

;; Claim all remaining winnings
(define-public (claim-all-winnings (market-id uint) (option uint))
  (let
    (
      (bet (unwrap! (map-get? bets { market-id: market-id, better: tx-sender, option: option }) ERR-NOT-FOUND))
      (unclaimed-amount (- (get amount bet) (get claimed-amount bet)))
    )
    (asserts! (> unclaimed-amount u0) ERR-ALREADY-CLAIMED)
    (claim-partial-winnings market-id option unclaimed-amount)
  )
)

