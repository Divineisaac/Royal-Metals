;; Precious Metal Digital Asset Registry Smart Contract
;; Comprehensive tokenization platform for physical precious metals with vault custody, 
;; auditing capabilities, price tracking, and transfer management system

(define-constant contract-administrator tx-sender)

;; Error constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-RESOURCE-NOT-FOUND (err u101))
(define-constant ERR-DUPLICATE-ENTRY (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-INSUFFICIENT-TOKEN-BALANCE (err u104))
(define-constant ERR-UNSUPPORTED-METAL-TYPE (err u105))
(define-constant ERR-VAULT-NOT-AUTHORIZED (err u106))
(define-constant ERR-CERTIFICATE-EXPIRED (err u107))
(define-constant ERR-INVALID-PURITY-LEVEL (err u108))
(define-constant ERR-TRANSFER-OPERATION-FAILED (err u109))
(define-constant ERR-INVALID-PRICE-DATA (err u110))
(define-constant ERR-MALFORMED-INPUT-DATA (err u111))

;; Supported precious metal type identifiers
(define-constant precious-metal-gold u1)
(define-constant precious-metal-silver u2)
(define-constant precious-metal-platinum u3)
(define-constant precious-metal-palladium u4)

;; Global contract state variables
(define-data-var next-available-token-identifier uint u1)
(define-data-var platform-operations-suspended bool false)
(define-data-var cumulative-metal-weight-tokenized uint u0)

;; Core token registry mapping token identifiers to comprehensive metadata
(define-map digital-asset-registry
  { asset-identifier: uint }
  {
    current-owner-address: principal,
    underlying-metal-type: uint,
    physical-weight-in-grams: uint,
    metal-purity-basis-points: uint,
    authenticity-certificate-hash: (buff 32),
    storage-vault-location: (string-ascii 50),
    tokenization-block-height: uint,
    last-verification-block-height: uint,
    current-market-value-cents: uint
  }
)

;; Token ownership tracking for efficient balance queries
(define-map asset-ownership-records
  { owner-principal: principal, asset-identifier: uint }
  { ownership-quantity: uint }
)

;; Real-time precious metal market pricing data
(define-map current-market-prices
  { metal-category: uint }
  {
    price-per-gram-in-cents: uint,
    price-update-block-height: uint
  }
)

;; Authorized secure storage facility registry
(define-map certified-storage-facilities
  { facility-operator-address: principal }
  {
    facility-name: (string-ascii 50),
    geographical-location: (string-ascii 100),
    authorization-status: bool,
    maximum-storage-capacity-grams: uint,
    current-metal-holdings-grams: uint
  }
)

;; Certified third-party auditor registry
(define-map accredited-verification-auditors
  { auditor-principal-address: principal }
  {
    auditor-organization-name: (string-ascii 50),
    professional-certification-details: (string-ascii 100),
    active-authorization-status: bool
  }
)

;; Token transfer restriction management system
(define-map asset-transfer-limitations
  { restricted-asset-identifier: uint }
  {
    transfer-restriction-active: bool,
    restriction-justification: (string-ascii 100)
  }
)

;; Input validation helper functions for data integrity
(define-private (validate-principal-address (principal-to-check principal))
  (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78))
)

(define-private (validate-short-text-field (text-input (string-ascii 50)))
  (> (len text-input) u0)
)

(define-private (validate-extended-text-field (text-input (string-ascii 100)))
  (> (len text-input) u0)
)

(define-private (validate-restriction-reason (reason-text (string-ascii 100)))
  (> (len reason-text) u0)
)

(define-private (validate-certificate-hash-format (certificate-hash (buff 32)))
  (is-eq (len certificate-hash) u32)
)

(define-private (validate-asset-identifier-exists (asset-id uint))
  (and (> asset-id u0) (< asset-id (var-get next-available-token-identifier)))
)

;; Public read-only functions for querying contract state

(define-read-only (retrieve-asset-details (asset-identifier uint))
  (map-get? digital-asset-registry { asset-identifier: asset-identifier })
)

(define-read-only (get-owner-asset-balance (owner-address principal) (asset-identifier uint))
  (default-to u0 (get ownership-quantity (map-get? asset-ownership-records { owner-principal: owner-address, asset-identifier: asset-identifier })))
)

(define-read-only (fetch-current-metal-price (metal-type uint))
  (map-get? current-market-prices { metal-category: metal-type })
)

(define-read-only (get-storage-facility-details (facility-address principal))
  (map-get? certified-storage-facilities { facility-operator-address: facility-address })
)

(define-read-only (retrieve-auditor-credentials (auditor-address principal))
  (map-get? accredited-verification-auditors { auditor-principal-address: auditor-address })
)

(define-read-only (check-asset-transfer-restrictions (asset-identifier uint))
  (default-to false (get transfer-restriction-active (map-get? asset-transfer-limitations { restricted-asset-identifier: asset-identifier })))
)

(define-read-only (get-platform-statistics)
  {
    total-assets-created: (- (var-get next-available-token-identifier) u1),
    total-metal-weight-tokenized: (var-get cumulative-metal-weight-tokenized),
    platform-currently-paused: (var-get platform-operations-suspended)
  }
)

(define-read-only (calculate-asset-current-value (asset-identifier uint))
  (match (retrieve-asset-details asset-identifier)
    asset-metadata
    (match (fetch-current-metal-price (get underlying-metal-type asset-metadata))
      pricing-data
      (let (
        (metal-weight (get physical-weight-in-grams asset-metadata))
        (purity-level (get metal-purity-basis-points asset-metadata))
        (per-gram-price (get price-per-gram-in-cents pricing-data))
      )
        (ok (/ (* (* metal-weight per-gram-price) purity-level) u10000))
      )
      ERR-RESOURCE-NOT-FOUND
    )
    ERR-RESOURCE-NOT-FOUND
  )
)

(define-read-only (verify-supported-metal-type (metal-type uint))
  (or 
    (is-eq metal-type precious-metal-gold)
    (or
      (is-eq metal-type precious-metal-silver)
      (or
        (is-eq metal-type precious-metal-platinum)
        (is-eq metal-type precious-metal-palladium)
      )
    )
  )
)

;; Internal helper functions for contract operations

(define-private (verify-contract-administrator-privileges)
  (is-eq tx-sender contract-administrator)
)

(define-private (verify-authorized-storage-facility (facility-address principal))
  (default-to false (get authorization-status (map-get? certified-storage-facilities { facility-operator-address: facility-address })))
)

(define-private (verify-accredited-auditor-status (auditor-address principal))
  (default-to false (get active-authorization-status (map-get? accredited-verification-auditors { auditor-principal-address: auditor-address })))
)

(define-private (adjust-facility-metal-holdings (facility-address principal) (weight-adjustment int))
  (match (map-get? certified-storage-facilities { facility-operator-address: facility-address })
    facility-data
    (let (
      (existing-holdings (get current-metal-holdings-grams facility-data))
      (updated-holdings (if (> weight-adjustment 0)
                     (+ existing-holdings (to-uint weight-adjustment))
                     (- existing-holdings (to-uint (- weight-adjustment)))))
    )
      (map-set certified-storage-facilities
        { facility-operator-address: facility-address }
        (merge facility-data { current-metal-holdings-grams: updated-holdings })
      )
      (ok true)
    )
    ERR-RESOURCE-NOT-FOUND
  )
)

;; Administrative control functions

(define-public (suspend-platform-operations)
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-operations-suspended true)
    (ok true)
  )
)

(define-public (resume-platform-operations)
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-operations-suspended false)
    (ok true)
  )
)

(define-public (register-authorized-storage-facility (facility-address principal) (facility-name (string-ascii 50)) (location (string-ascii 100)) (storage-capacity uint))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address facility-address) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-short-text-field facility-name) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-extended-text-field location) ERR-MALFORMED-INPUT-DATA)
    (asserts! (> storage-capacity u0) ERR-INVALID-AMOUNT)
    (map-set certified-storage-facilities
      { facility-operator-address: facility-address }
      {
        facility-name: facility-name,
        geographical-location: location,
        authorization-status: true,
        maximum-storage-capacity-grams: storage-capacity,
        current-metal-holdings-grams: u0
      }
    )
    (ok true)
  )
)

(define-public (revoke-storage-facility-authorization (facility-address principal))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address facility-address) ERR-MALFORMED-INPUT-DATA)
    (match (map-get? certified-storage-facilities { facility-operator-address: facility-address })
      facility-data
      (begin
        (map-set certified-storage-facilities
          { facility-operator-address: facility-address }
          (merge facility-data { authorization-status: false })
        )
        (ok true)
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)

(define-public (accredit-verification-auditor (auditor-address principal) (organization-name (string-ascii 50)) (certification-details (string-ascii 100)))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address auditor-address) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-short-text-field organization-name) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-extended-text-field certification-details) ERR-MALFORMED-INPUT-DATA)
    (map-set accredited-verification-auditors
      { auditor-principal-address: auditor-address }
      {
        auditor-organization-name: organization-name,
        professional-certification-details: certification-details,
        active-authorization-status: true
      }
    )
    (ok true)
  )
)

(define-public (update-precious-metal-market-price (metal-type uint) (price-per-gram-cents uint))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-supported-metal-type metal-type) ERR-UNSUPPORTED-METAL-TYPE)
    (asserts! (> price-per-gram-cents u0) ERR-INVALID-PRICE-DATA)
    (map-set current-market-prices
      { metal-category: metal-type }
      {
        price-per-gram-in-cents: price-per-gram-cents,
        price-update-block-height: block-height
      }
    )
    (ok true)
  )
)

;; Core tokenization and asset management functions

(define-public (create-digital-asset-token 
  (token-recipient-address principal)
  (underlying-metal-type uint)
  (physical-weight-grams uint)
  (purity-basis-points uint)
  (authenticity-certificate-hash (buff 32))
  (storage-vault-location (string-ascii 50))
)
  (let (
    (new-asset-identifier (var-get next-available-token-identifier))
  )
    (asserts! (not (var-get platform-operations-suspended)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (verify-authorized-storage-facility tx-sender) ERR-VAULT-NOT-AUTHORIZED)
    (asserts! (validate-principal-address token-recipient-address) ERR-MALFORMED-INPUT-DATA)
    (asserts! (verify-supported-metal-type underlying-metal-type) ERR-UNSUPPORTED-METAL-TYPE)
    (asserts! (> physical-weight-grams u0) ERR-INVALID-AMOUNT)
    (asserts! (and (> purity-basis-points u0) (<= purity-basis-points u10000)) ERR-INVALID-PURITY-LEVEL)
    (asserts! (validate-certificate-hash-format authenticity-certificate-hash) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-short-text-field storage-vault-location) ERR-MALFORMED-INPUT-DATA)
    
    (match (fetch-current-metal-price underlying-metal-type)
      price-information
      (let (
        (calculated-market-value (/ (* (* physical-weight-grams (get price-per-gram-in-cents price-information)) purity-basis-points) u10000))
      )
        (map-set digital-asset-registry
          { asset-identifier: new-asset-identifier }
          {
            current-owner-address: token-recipient-address,
            underlying-metal-type: underlying-metal-type,
            physical-weight-in-grams: physical-weight-grams,
            metal-purity-basis-points: purity-basis-points,
            authenticity-certificate-hash: authenticity-certificate-hash,
            storage-vault-location: storage-vault-location,
            tokenization-block-height: block-height,
            last-verification-block-height: block-height,
            current-market-value-cents: calculated-market-value
          }
        )
        
        (map-set asset-ownership-records
          { owner-principal: token-recipient-address, asset-identifier: new-asset-identifier }
          { ownership-quantity: u1 }
        )
        
        (try! (adjust-facility-metal-holdings tx-sender (to-int physical-weight-grams)))
        
        (var-set next-available-token-identifier (+ new-asset-identifier u1))
        (var-set cumulative-metal-weight-tokenized (+ (var-get cumulative-metal-weight-tokenized) physical-weight-grams))
        
        (print {
          event: "digital-asset-created",
          asset-identifier: new-asset-identifier,
          recipient: token-recipient-address,
          metal-type: underlying-metal-type,
          weight-grams: physical-weight-grams,
          issuing-vault: tx-sender
        })
        
        (ok new-asset-identifier)
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)

(define-public (execute-asset-transfer (asset-identifier uint) (current-owner principal) (new-recipient principal))
  (let (
    (owner-current-balance (get-owner-asset-balance current-owner asset-identifier))
  )
    (asserts! (not (var-get platform-operations-suspended)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq tx-sender current-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-principal-address new-recipient) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (asserts! (> owner-current-balance u0) ERR-INSUFFICIENT-TOKEN-BALANCE)
    (asserts! (not (check-asset-transfer-restrictions asset-identifier)) ERR-TRANSFER-OPERATION-FAILED)
    
    (match (retrieve-asset-details asset-identifier)
      asset-metadata
      (begin
        (map-delete asset-ownership-records { owner-principal: current-owner, asset-identifier: asset-identifier })
        
        (map-set asset-ownership-records
          { owner-principal: new-recipient, asset-identifier: asset-identifier }
          { ownership-quantity: u1 }
        )
        
        (map-set digital-asset-registry
          { asset-identifier: asset-identifier }
          (merge asset-metadata { current-owner-address: new-recipient })
        )
        
        (print {
          event: "asset-ownership-transferred",
          asset-identifier: asset-identifier,
          previous-owner: current-owner,
          new-owner: new-recipient
        })
        
        (ok true)
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)

(define-public (destroy-digital-asset-token (asset-identifier uint))
  (begin
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (match (retrieve-asset-details asset-identifier)
      asset-metadata
      (let (
        (asset-owner (get current-owner-address asset-metadata))
        (physical-weight (get physical-weight-in-grams asset-metadata))
      )
        (asserts! (not (var-get platform-operations-suspended)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (or (is-eq tx-sender asset-owner) (verify-authorized-storage-facility tx-sender)) ERR-UNAUTHORIZED-ACCESS)
        
        (map-delete asset-ownership-records { owner-principal: asset-owner, asset-identifier: asset-identifier })
        (map-delete digital-asset-registry { asset-identifier: asset-identifier })
        
        (var-set cumulative-metal-weight-tokenized (- (var-get cumulative-metal-weight-tokenized) physical-weight))
        
        (print {
          event: "digital-asset-destroyed",
          asset-identifier: asset-identifier,
          previous-owner: asset-owner,
          reclaimed-weight: physical-weight
        })
        
        (ok true)
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)

(define-public (perform-asset-verification-audit (asset-identifier uint) (updated-certificate-hash (buff 32)))
  (begin
    (asserts! (verify-accredited-auditor-status tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-certificate-hash-format updated-certificate-hash) ERR-MALFORMED-INPUT-DATA)
    (match (retrieve-asset-details asset-identifier)
      asset-metadata
      (begin
        (map-set digital-asset-registry
          { asset-identifier: asset-identifier }
          (merge asset-metadata {
            authenticity-certificate-hash: updated-certificate-hash,
            last-verification-block-height: block-height
          })
        )
        
        (print {
          event: "asset-verification-completed",
          asset-identifier: asset-identifier,
          auditing-organization: tx-sender,
          verification-block: block-height
        })
        
        (ok true)
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)

(define-public (impose-asset-transfer-restriction (asset-identifier uint) (restriction-justification (string-ascii 100)))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (asserts! (validate-restriction-reason restriction-justification) ERR-MALFORMED-INPUT-DATA)
    (asserts! (is-some (retrieve-asset-details asset-identifier)) ERR-RESOURCE-NOT-FOUND)
    
    (map-set asset-transfer-limitations
      { restricted-asset-identifier: asset-identifier }
      {
        transfer-restriction-active: true,
        restriction-justification: restriction-justification
      }
    )
    
    (print {
      event: "asset-transfer-restricted",
      asset-identifier: asset-identifier,
      restriction-reason: restriction-justification
    })
    
    (ok true)
  )
)

(define-public (remove-asset-transfer-restriction (asset-identifier uint))
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (asserts! (is-some (retrieve-asset-details asset-identifier)) ERR-RESOURCE-NOT-FOUND)
    
    (map-delete asset-transfer-limitations { restricted-asset-identifier: asset-identifier })
    
    (print {
      event: "asset-transfer-restriction-lifted",
      asset-identifier: asset-identifier
    })
    
    (ok true)
  )
)

;; Batch processing functions for operational efficiency

(define-public (batch-create-digital-assets 
  (recipient-addresses (list 10 principal))
  (metal-types (list 10 uint))
  (physical-weights (list 10 uint))
  (purity-levels (list 10 uint))
  (certificate-hashes (list 10 (buff 32)))
  (vault-locations (list 10 (string-ascii 50)))
)
  (let (
    (batch-results (map process-single-token-creation
                 recipient-addresses
                 metal-types
                 physical-weights
                 purity-levels
                 certificate-hashes
                 vault-locations))
  )
    (ok batch-results)
  )
)

(define-private (process-single-token-creation
  (recipient-address principal)
  (metal-type uint)
  (weight-grams uint)
  (purity-level uint)
  (certificate-hash (buff 32))
  (vault-location (string-ascii 50))
)
  (create-digital-asset-token recipient-address metal-type weight-grams purity-level certificate-hash vault-location)
)

;; Emergency response and maintenance functions

(define-public (activate-emergency-suspension)
  (begin
    (asserts! (verify-contract-administrator-privileges) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-operations-suspended true)
    (print { event: "emergency-platform-suspension", suspension-block: block-height })
    (ok true)
  )
)

(define-public (refresh-asset-market-valuation (asset-identifier uint))
  (begin
    (asserts! (validate-asset-identifier-exists asset-identifier) ERR-MALFORMED-INPUT-DATA)
    (match (retrieve-asset-details asset-identifier)
      asset-metadata
      (match (fetch-current-metal-price (get underlying-metal-type asset-metadata))
        pricing-data
        (let (
          (metal-weight (get physical-weight-in-grams asset-metadata))
          (purity-level (get metal-purity-basis-points asset-metadata))
          (current-price-per-gram (get price-per-gram-in-cents pricing-data))
          (recalculated-market-value (/ (* (* metal-weight current-price-per-gram) purity-level) u10000))
        )
          (map-set digital-asset-registry
            { asset-identifier: asset-identifier }
            (merge asset-metadata { current-market-value-cents: recalculated-market-value })
          )
          (ok recalculated-market-value)
        )
        ERR-RESOURCE-NOT-FOUND
      )
      ERR-RESOURCE-NOT-FOUND
    )
  )
)