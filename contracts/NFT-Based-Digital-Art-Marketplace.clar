(define-non-fungible-token digital-art uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-not-found (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-not-for-sale (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-already-listed (err u106))
(define-constant err-unauthorized (err u107))
(define-constant err-self-transfer (err u108))
(define-constant err-invalid-price (err u109))

(define-data-var last-token-id uint u0)
(define-data-var platform-fee-percentage uint u250)
(define-data-var total-fees-collected uint u0)

(define-map token-metadata
  uint
  {
    creator: principal,
    uri: (string-ascii 256),
    name: (string-utf8 50),
    minted-at: uint
  }
)

(define-map listings
  uint
  {
    price: uint,
    seller: principal,
    listed-at: uint
  }
)

(define-map offers
  { token-id: uint, buyer: principal }
  {
    amount: uint,
    offered-at: uint
  }
)

(define-map royalties
  uint
  {
    recipient: principal,
    percentage: uint
  }
)

(define-public (mint (uri (string-ascii 256)) (name (string-utf8 50)) (royalty-percentage uint))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (<= royalty-percentage u1000) err-invalid-price)
    (try! (nft-mint? digital-art token-id tx-sender))
    (map-set token-metadata token-id {
      creator: tx-sender,
      uri: uri,
      name: name,
      minted-at: stacks-block-height
    })
    (map-set royalties token-id {
      recipient: tx-sender,
      percentage: royalty-percentage
    })
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (not (is-eq sender recipient)) err-self-transfer)
    (map-delete listings token-id)
    (try! (nft-transfer? digital-art token-id sender recipient))
    (ok true)
  )
)

(define-public (list-for-sale (token-id uint) (price uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? digital-art token-id) err-not-found))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (is-none (map-get? listings token-id)) err-already-listed)
    (map-set listings token-id {
      price: price,
      seller: tx-sender,
      listed-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (unlist (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings token-id) err-listing-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (map-delete listings token-id)
    (ok true)
  )
)

(define-public (buy (token-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings token-id) err-not-for-sale))
      (price (get price listing))
      (seller (get seller listing))
      (royalty-info (unwrap! (map-get? royalties token-id) err-not-found))
      (royalty-amount (/ (* price (get percentage royalty-info)) u10000))
      (platform-fee (/ (* price (var-get platform-fee-percentage)) u10000))
      (seller-amount (- (- price royalty-amount) platform-fee))
    )
    (asserts! (not (is-eq tx-sender seller)) err-self-transfer)
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? seller-amount tx-sender seller)))
    (try! (as-contract (stx-transfer? royalty-amount tx-sender (get recipient royalty-info))))
    (var-set total-fees-collected (+ (var-get total-fees-collected) platform-fee))
    (try! (nft-transfer? digital-art token-id seller tx-sender))
    (map-delete listings token-id)
    (ok true)
  )
)

(define-public (make-offer (token-id uint) (amount uint))
  (begin
    (asserts! (is-some (nft-get-owner? digital-art token-id)) err-not-found)
    (asserts! (> amount u0) err-invalid-price)
    (map-set offers { token-id: token-id, buyer: tx-sender } {
      amount: amount,
      offered-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (accept-offer (token-id uint) (buyer principal))
  (let
    (
      (owner (unwrap! (nft-get-owner? digital-art token-id) err-not-found))
      (offer (unwrap! (map-get? offers { token-id: token-id, buyer: buyer }) err-not-found))
      (amount (get amount offer))
      (royalty-info (unwrap! (map-get? royalties token-id) err-not-found))
      (royalty-amount (/ (* amount (get percentage royalty-info)) u10000))
      (platform-fee (/ (* amount (var-get platform-fee-percentage)) u10000))
      (seller-amount (- (- amount royalty-amount) platform-fee))
    )
    (asserts! (is-eq tx-sender owner) err-not-token-owner)
    (asserts! (not (is-eq tx-sender buyer)) err-self-transfer)
    (try! (stx-transfer? amount buyer (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? seller-amount tx-sender owner)))
    (try! (as-contract (stx-transfer? royalty-amount tx-sender (get recipient royalty-info))))
    (var-set total-fees-collected (+ (var-get total-fees-collected) platform-fee))
    (try! (nft-transfer? digital-art token-id owner buyer))
    (map-delete listings token-id)
    (map-delete offers { token-id: token-id, buyer: buyer })
    (ok true)
  )
)

(define-public (cancel-offer (token-id uint))
  (begin
    (asserts! (is-some (map-get? offers { token-id: token-id, buyer: tx-sender })) err-not-found)
    (map-delete offers { token-id: token-id, buyer: tx-sender })
    (ok true)
  )
)

(define-public (update-listing-price (token-id uint) (new-price uint))
  (let
    (
      (listing (unwrap! (map-get? listings token-id) err-listing-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (> new-price u0) err-invalid-price)
    (map-set listings token-id (merge listing { price: new-price }))
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-price)
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

(define-public (withdraw-fees (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    (ok true)
  )
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some (get uri (unwrap! (map-get? token-metadata token-id) err-not-found))))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? digital-art token-id))
)

(define-read-only (get-token-metadata (token-id uint))
  (ok (map-get? token-metadata token-id))
)

(define-read-only (get-listing (token-id uint))
  (ok (map-get? listings token-id))
)

(define-read-only (get-offer (token-id uint) (buyer principal))
  (ok (map-get? offers { token-id: token-id, buyer: buyer }))
)

(define-read-only (get-royalty-info (token-id uint))
  (ok (map-get? royalties token-id))
)

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee-percentage))
)

(define-read-only (get-total-fees-collected)
  (ok (var-get total-fees-collected))
)

