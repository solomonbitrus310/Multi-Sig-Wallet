(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-SIGNED (err u101))
(define-constant ERR-TRANSACTION-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-SIGNATURES (err u103))
(define-constant ERR-TRANSACTION-ALREADY-EXECUTED (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INVALID-RECIPIENT (err u106))
(define-constant ERR-WALLET-EMPTY (err u107))
(define-constant ERR-INVALID-THRESHOLD (err u108))
(define-constant ERR-OWNER-EXISTS (err u109))
(define-constant ERR-OWNER-NOT-FOUND (err u110))
(define-constant ERR-TRANSACTION-EXPIRED (err u111))

(define-data-var contract-owner principal tx-sender)
(define-data-var required-signatures uint u2)
(define-data-var transaction-nonce uint u0)
(define-data-var transaction-expiry-duration uint u144)

(define-map owners
    principal
    bool
)
(define-map transactions
    uint
    {
        to: principal,
        amount: uint,
        executed: bool,
        signatures: uint,
        created-by: principal,
    }
)
(define-map transaction-signatures
    {
        tx-id: uint,
        signer: principal,
    }
    bool
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-required-signatures)
    (var-get required-signatures)
)

(define-read-only (get-transaction-nonce)
    (var-get transaction-nonce)
)

(define-read-only (is-owner (user principal))
    (default-to false (map-get? owners user))
)

(define-read-only (get-transaction (tx-id uint))
    (map-get? transactions tx-id)
)

(define-read-only (has-signed
        (tx-id uint)
        (signer principal)
    )
    (default-to false
        (map-get? transaction-signatures {
            tx-id: tx-id,
            signer: signer,
        })
    )
)

(define-read-only (get-wallet-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (count-owners)
    (len (filter is-owner-helper
        (list
            tx-sender
            'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
            'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
            'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
            'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
            'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND
            'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB
            'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0
            'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
            'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP
        )))
)

(define-private (is-owner-helper (user principal))
    (is-owner user)
)

(define-public (initialize-wallet
        (initial-owners (list 10 principal))
        (threshold uint)
    )
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (and (> threshold u0) (<= threshold (len initial-owners)))
            ERR-INVALID-THRESHOLD
        )
        (var-set required-signatures threshold)
        (map add-owner-helper initial-owners)
        (ok true)
    )
)

(define-private (add-owner-helper (owner principal))
    (map-set owners owner true)
)

(define-public (add-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-owner new-owner)) ERR-OWNER-EXISTS)
        (map-set owners new-owner true)
        (ok true)
    )
)

(define-public (remove-owner (owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (is-owner owner) ERR-OWNER-NOT-FOUND)
        (map-delete owners owner)
        (ok true)
    )
)

(define-public (update-required-signatures (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (and (> new-threshold u0) (<= new-threshold (count-owners)))
            ERR-INVALID-THRESHOLD
        )
        (var-set required-signatures new-threshold)
        (ok true)
    )
)

(define-public (deposit (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (stx-transfer? amount tx-sender (as-contract tx-sender))
    )
)

(define-public (propose-transaction
        (to principal)
        (amount uint)
    )
    (let ((tx-id (var-get transaction-nonce)))
        (begin
            (asserts! (is-owner tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (> amount u0) ERR-INVALID-AMOUNT)
            (asserts! (not (is-eq to (as-contract tx-sender)))
                ERR-INVALID-RECIPIENT
            )
            (asserts! (>= (get-wallet-balance) amount) ERR-WALLET-EMPTY)
            (map-set transactions tx-id {
                to: to,
                amount: amount,
                executed: false,
                signatures: u1,
                created-by: tx-sender,
            })
            (map-set transaction-signatures {
                tx-id: tx-id,
                signer: tx-sender,
            }
                true
            )
            (var-set transaction-nonce (+ tx-id u1))
            (ok tx-id)
        )
    )
)

(define-public (sign-transaction (tx-id uint))
    (let ((transaction (unwrap! (get-transaction tx-id) ERR-TRANSACTION-NOT-FOUND)))
        (begin
            (asserts! (is-owner tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (get executed transaction))
                ERR-TRANSACTION-ALREADY-EXECUTED
            )
            (asserts! (not (has-signed tx-id tx-sender)) ERR-ALREADY-SIGNED)
            (map-set transaction-signatures {
                tx-id: tx-id,
                signer: tx-sender,
            }
                true
            )
            (map-set transactions tx-id
                (merge transaction { signatures: (+ (get signatures transaction) u1) })
            )
            (ok true)
        )
    )
)

(define-public (execute-transaction (tx-id uint))
    (let ((transaction (unwrap! (get-transaction tx-id) ERR-TRANSACTION-NOT-FOUND)))
        (begin
            (asserts! (is-owner tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (get executed transaction))
                ERR-TRANSACTION-ALREADY-EXECUTED
            )
            (asserts!
                (>= (get signatures transaction) (var-get required-signatures))
                ERR-INSUFFICIENT-SIGNATURES
            )
            (asserts! (>= (get-wallet-balance) (get amount transaction))
                ERR-WALLET-EMPTY
            )
            (try! (as-contract (stx-transfer? (get amount transaction) tx-sender
                (get to transaction)
            )))
            (map-set transactions tx-id (merge transaction { executed: true }))
            (ok true)
        )
    )
)

(define-public (revoke-signature (tx-id uint))
    (let ((transaction (unwrap! (get-transaction tx-id) ERR-TRANSACTION-NOT-FOUND)))
        (begin
            (asserts! (is-owner tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (get executed transaction))
                ERR-TRANSACTION-ALREADY-EXECUTED
            )
            (asserts! (has-signed tx-id tx-sender) ERR-ALREADY-SIGNED)
            (map-delete transaction-signatures {
                tx-id: tx-id,
                signer: tx-sender,
            })
            (map-set transactions tx-id
                (merge transaction { signatures: (- (get signatures transaction) u1) })
            )
            (ok true)
        )
    )
)

(define-constant ERR-WALLET-NOT-FOUND (err u101))
(define-constant ERR-DEPLOYMENT-FAILED (err u103))
(define-constant ERR-WALLET-EXISTS (err u104))

(define-data-var factory-owner principal tx-sender)
(define-data-var wallet-counter uint u0)
(define-data-var deployment-fee uint u1000)

(define-map wallets
    uint
    {
        contract-address: principal,
        creator: principal,
        owners: (list 10 principal),
        threshold: uint,
        created-at: uint,
    }
)

(define-map wallet-by-creator
    {
        creator: principal,
        index: uint,
    }
    uint
)
(define-map user-wallet-count
    principal
    uint
)

(define-read-only (get-factory-owner)
    (var-get factory-owner)
)

(define-read-only (get-wallet-counter)
    (var-get wallet-counter)
)

(define-read-only (get-deployment-fee)
    (var-get deployment-fee)
)

(define-read-only (get-wallet-info (wallet-id uint))
    (map-get? wallets wallet-id)
)

(define-read-only (get-user-wallet-count (user principal))
    (default-to u0 (map-get? user-wallet-count user))
)

(define-read-only (get-user-wallet-id
        (user principal)
        (index uint)
    )
    (map-get? wallet-by-creator {
        creator: user,
        index: index,
    })
)

(define-read-only (get-all-wallets-for-user (user principal))
    (let ((count (get-user-wallet-count user)))
        (map get-wallet-id-helper (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9))
    )
)

(define-private (get-wallet-id-helper (index uint))
    (get-user-wallet-id tx-sender index)
)

(define-public (set-deployment-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender (var-get factory-owner)) ERR-NOT-AUTHORIZED)
        (var-set deployment-fee new-fee)
        (ok true)
    )
)

(define-public (create-wallet
        (wallet-owners (list 10 principal))
        (threshold uint)
    )
    (let (
            (wallet-id (var-get wallet-counter))
            (creator tx-sender)
            (fee (var-get deployment-fee))
            (user-count (get-user-wallet-count creator))
        )
        (begin
            (asserts! (and (> threshold u0) (<= threshold (len wallet-owners)))
                ERR-INVALID-THRESHOLD
            )
            (asserts! (>= (stx-get-balance tx-sender) fee) ERR-DEPLOYMENT-FAILED)
            (try! (stx-transfer? fee tx-sender (var-get factory-owner)))
            (map-set wallets wallet-id {
                contract-address: (as-contract tx-sender),
                creator: creator,
                owners: wallet-owners,
                threshold: threshold,
                created-at: stacks-block-height,
            })
            (map-set wallet-by-creator {
                creator: creator,
                index: user-count,
            }
                wallet-id
            )
            (map-set user-wallet-count creator (+ user-count u1))
            (var-set wallet-counter (+ wallet-id u1))
            (ok wallet-id)
        )
    )
)

(define-public (register-existing-wallet
        (wallet-address principal)
        (wallet-owners (list 10 principal))
        (threshold uint)
    )
    (let (
            (wallet-id (var-get wallet-counter))
            (creator tx-sender)
            (user-count (get-user-wallet-count creator))
        )
        (begin
            (asserts! (and (> threshold u0) (<= threshold (len wallet-owners)))
                ERR-INVALID-THRESHOLD
            )
            (map-set wallets wallet-id {
                contract-address: wallet-address,
                creator: creator,
                owners: wallet-owners,
                threshold: threshold,
                created-at: stacks-block-height,
            })
            (map-set wallet-by-creator {
                creator: creator,
                index: user-count,
            }
                wallet-id
            )
            (map-set user-wallet-count creator (+ user-count u1))
            (var-set wallet-counter (+ wallet-id u1))
            (ok wallet-id)
        )
    )
)

(define-public (get-wallet-template (template-type uint))
    (if (is-eq template-type u1)
        (ok {
            name: "Basic 2-of-3",
            description: "Standard multi-sig wallet requiring 2 signatures from 3 owners",
            threshold: u2,
            max-owners: u3,
        })
        (if (is-eq template-type u2)
            (ok {
                name: "Corporate 3-of-5",
                description: "Enterprise wallet requiring 3 signatures from 5 owners",
                threshold: u3,
                max-owners: u5,
            })
            (ok {
                name: "Personal 1-of-2",
                description: "Simple shared wallet requiring 1 signature from 2 owners",
                threshold: u1,
                max-owners: u2,
            })
        )
    )
)

(define-public (withdraw-fees)
    (let ((balance (stx-get-balance (as-contract tx-sender))))
        (begin
            (asserts! (is-eq tx-sender (var-get factory-owner))
                ERR-NOT-AUTHORIZED
            )
            (asserts! (> balance u0) ERR-DEPLOYMENT-FAILED)
            (as-contract (stx-transfer? balance tx-sender (var-get factory-owner)))
        )
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get factory-owner)) ERR-NOT-AUTHORIZED)
        (var-set factory-owner new-owner)
        (ok true)
    )
)
