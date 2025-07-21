;; Billing Setup Contract
;; Establishes monthly billing cycles and payment methods

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-FOUND (err u103))

;; Data Variables
(define-data-var next-billing-id uint u1)

;; Data Maps
(define-map billing-accounts
  { billing-id: uint }
  {
    customer-principal: principal,
    billing-address: (string-ascii 200),
    billing-cycle: uint,
    payment-method: (string-ascii 20),
    payment-details: (string-ascii 100),
    auto-pay-enabled: bool,
    billing-start-date: uint,
    status: (string-ascii 20)
  }
)

(define-map customer-billing
  { customer-principal: principal }
  { billing-id: uint }
)

(define-map billing-cycles
  { cycle-day: uint }
  { customer-count: uint }
)

;; Public Functions

;; Setup billing account
(define-public (setup-billing-account (customer-principal principal)
                                     (billing-address (string-ascii 200))
                                     (billing-cycle uint)
                                     (payment-method (string-ascii 20))
                                     (payment-details (string-ascii 100))
                                     (auto-pay-enabled bool))
  (let ((billing-id (var-get next-billing-id)))
    (begin
      ;; Validate inputs
      (asserts! (> (len billing-address) u0) ERR-INVALID-INPUT)
      (asserts! (and (>= billing-cycle u1) (<= billing-cycle u28)) ERR-INVALID-INPUT)
      (asserts! (is-valid-payment-method payment-method) ERR-INVALID-INPUT)

      ;; Check if customer already has billing account
      (asserts! (is-none (map-get? customer-billing { customer-principal: customer-principal })) ERR-ALREADY-EXISTS)

      ;; Create billing account
      (map-set billing-accounts
        { billing-id: billing-id }
        {
          customer-principal: customer-principal,
          billing-address: billing-address,
          billing-cycle: billing-cycle,
          payment-method: payment-method,
          payment-details: payment-details,
          auto-pay-enabled: auto-pay-enabled,
          billing-start-date: block-height,
          status: "active"
        }
      )

      ;; Create customer lookup
      (map-set customer-billing
        { customer-principal: customer-principal }
        { billing-id: billing-id }
      )

      ;; Update billing cycle count
      (update-cycle-count billing-cycle true)

      ;; Increment billing ID
      (var-set next-billing-id (+ billing-id u1))

      (ok billing-id)
    )
  )
)

;; Update payment method
(define-public (update-payment-method (customer-principal principal)
                                     (new-payment-method (string-ascii 20))
                                     (new-payment-details (string-ascii 100)))
  (let ((billing-lookup (unwrap! (map-get? customer-billing { customer-principal: customer-principal }) ERR-NOT-FOUND))
        (billing-id (get billing-id billing-lookup))
        (billing-account (unwrap! (map-get? billing-accounts { billing-id: billing-id }) ERR-NOT-FOUND)))
    (begin
      (asserts! (or (is-eq tx-sender customer-principal) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
      (asserts! (is-valid-payment-method new-payment-method) ERR-INVALID-INPUT)

      (map-set billing-accounts
        { billing-id: billing-id }
        (merge billing-account
          {
            payment-method: new-payment-method,
            payment-details: new-payment-details
          }
        )
      )

      (ok true)
    )
  )
)

;; Update billing cycle
(define-public (update-billing-cycle (customer-principal principal) (new-billing-cycle uint))
  (let ((billing-lookup (unwrap! (map-get? customer-billing { customer-principal: customer-principal }) ERR-NOT-FOUND))
        (billing-id (get billing-id billing-lookup))
        (billing-account (unwrap! (map-get? billing-accounts { billing-id: billing-id }) ERR-NOT-FOUND))
        (old-cycle (get billing-cycle billing-account)))
    (begin
      (asserts! (or (is-eq tx-sender customer-principal) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
      (asserts! (and (>= new-billing-cycle u1) (<= new-billing-cycle u28)) ERR-INVALID-INPUT)

      ;; Update billing account
      (map-set billing-accounts
        { billing-id: billing-id }
        (merge billing-account { billing-cycle: new-billing-cycle })
      )

      ;; Update cycle counts
      (update-cycle-count old-cycle false)
      (update-cycle-count new-billing-cycle true)

      (ok true)
    )
  )
)

;; Toggle auto-pay
(define-public (toggle-auto-pay (customer-principal principal))
  (let ((billing-lookup (unwrap! (map-get? customer-billing { customer-principal: customer-principal }) ERR-NOT-FOUND))
        (billing-id (get billing-id billing-lookup))
        (billing-account (unwrap! (map-get? billing-accounts { billing-id: billing-id }) ERR-NOT-FOUND)))
    (begin
      (asserts! (or (is-eq tx-sender customer-principal) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

      (map-set billing-accounts
        { billing-id: billing-id }
        (merge billing-account
          { auto-pay-enabled: (not (get auto-pay-enabled billing-account)) }
        )
      )

      (ok (not (get auto-pay-enabled billing-account)))
    )
  )
)

;; Suspend billing account
(define-public (suspend-billing-account (customer-principal principal))
  (let ((billing-lookup (unwrap! (map-get? customer-billing { customer-principal: customer-principal }) ERR-NOT-FOUND))
        (billing-id (get billing-id billing-lookup))
        (billing-account (unwrap! (map-get? billing-accounts { billing-id: billing-id }) ERR-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

      (map-set billing-accounts
        { billing-id: billing-id }
        (merge billing-account { status: "suspended" })
      )

      (ok true)
    )
  )
)

;; Private Functions

;; Validate payment method
(define-private (is-valid-payment-method (payment-method (string-ascii 20)))
  (or
    (is-eq payment-method "credit-card")
    (is-eq payment-method "bank-account")
    (is-eq payment-method "crypto-wallet")
    (is-eq payment-method "check")
  )
)

;; Update billing cycle count
(define-private (update-cycle-count (cycle-day uint) (increment bool))
  (let ((current-count (default-to u0 (get customer-count (map-get? billing-cycles { cycle-day: cycle-day })))))
    (map-set billing-cycles
      { cycle-day: cycle-day }
      { customer-count: (if increment (+ current-count u1) (- current-count u1)) }
    )
  )
)

;; Read-only Functions

;; Get billing account
(define-read-only (get-billing-account (customer-principal principal))
  (match (map-get? customer-billing { customer-principal: customer-principal })
    billing-lookup
    (map-get? billing-accounts { billing-id: (get billing-id billing-lookup) })
    none
  )
)

;; Get billing account by ID
(define-read-only (get-billing-account-by-id (billing-id uint))
  (map-get? billing-accounts { billing-id: billing-id })
)

;; Get billing cycle distribution
(define-read-only (get-cycle-distribution (cycle-day uint))
  (map-get? billing-cycles { cycle-day: cycle-day })
)

;; Check if billing is active
(define-read-only (is-billing-active (customer-principal principal))
  (match (get-billing-account customer-principal)
    billing-data (is-eq (get status billing-data) "active")
    false
  )
)
