# 🔐 Multi-Signature Wallet Smart Contract

A secure multi-signature wallet implementation in Clarity for the Stacks blockchain. This contract requires multiple signatures from authorized owners to execute transactions, providing enhanced security for shared funds management.

## 🚀 Features

- **Multi-signature security**: Requires multiple owner signatures to execute transactions
- **Owner management**: Add/remove wallet owners dynamically
- **Configurable threshold**: Set required number of signatures for transaction execution
- **Transaction proposals**: Owners can propose transactions for group approval
- **Signature management**: Sign, revoke signatures, and track approval status
- **Balance tracking**: Monitor wallet balance and transaction history

## 📋 Contract Functions

### 🔧 Setup Functions
- `initialize-wallet` - Set up initial owners and signature threshold
- `add-owner` - Add new wallet owner (contract owner only)
- `remove-owner` - Remove existing owner (contract owner only)
- `update-required-signatures` - Change signature threshold

### 💰 Wallet Operations
- `deposit` - Add STX to the wallet
- `propose-transaction` - Create new transaction proposal
- `sign-transaction` - Sign pending transaction
- `execute-transaction` - Execute fully signed transaction
- `revoke-signature` - Remove your signature from transaction

### 📊 Read-Only Functions
- `get-wallet-balance` - Check current wallet balance
- `get-transaction` - Get transaction details
- `is-owner` - Check if address is wallet owner
- `has-signed` - Check if owner signed specific transaction
- `get-required-signatures` - Get current signature threshold

## 🛠️ Usage Instructions

### 1️⃣ Deploy Contract
Deploy the contract to Stacks blockchain using Clarinet or Stacks CLI.

### 2️⃣ Initialize Wallet
```clarity
(contract-call? .multi-sig-wallet initialize-wallet 
  (list 'ST1OWNER1 'ST2OWNER2 'ST3OWNER3) 
  u2)
```

### 3️⃣ Deposit Funds
```clarity
(contract-call? .multi-sig-wallet deposit u1000000)
```

### 4️⃣ Propose Transaction
```clarity
(contract-call? .multi-sig-wallet propose-transaction 
  'ST1RECIPIENT 
  u500000)
```

### 5️⃣ Sign Transaction
```clarity
(contract-call? .multi-sig-wallet sign-transaction u0)
```

### 6️⃣ Execute Transaction
```clarity
(contract-call? .multi-sig-wallet execute-transaction u0)
```

## 🔒 Security Features

- ✅ Owner-only transaction proposals
- ✅ Signature threshold enforcement  
- ✅ Double-signature prevention
- ✅ Balance validation before execution
- ✅ Transaction replay protection
- ✅ Role-based access control

## 🧪 Testing

Use Clarinet to test the contract:

```bash
clarinet test
```

## 📝 Error Codes

- `u100` - Not authorized
- `u101` - Already signed
- `u102` - Transaction not found
- `u103` - Insufficient signatures
- `u104` - Transaction already executed
- `u105` - Invalid amount
- `u106` - Invalid recipient
- `u107` - Wallet empty
- `u108` - Invalid threshold
- `u109` - Owner exists
- `u110` - Owner not found

## 🎯 Use Cases

- 🏢 **Corporate Treasury**: Manage company funds with executive approval
- 👥 **DAO Governance**: Execute community-approved transactions
- 💼 **Joint Accounts**: Shared financial management for partnerships
- 🛡️ **Enhanced Security**: Protect large amounts with multi-party control

## 🔮 Future Enhancements

- Time-locked transactions
- Emergency recovery mechanisms
- Transaction batching
- Integration with other DeFi protocols
- Mobile wallet integration

---

Built with ❤️ using Clarity and Stacks blockchain technology
```

**Git Commit Message:**
```
feat: implement multi-signature wallet MVP with owner management and transaction approval system
```

**GitHub Pull Request Title:**
```
🔐 Add Multi-Signature Wallet Smart Contract MVP
```

**GitHub Pull Request Description:**
```
## 🚀 Multi-Signature Wallet Implementation

This PR introduces a complete multi-signature wallet smart contract that enables secure shared fund management through role-based access control.

### ✨ Features Added
- Multi-owner wallet with configurable signature thresholds
- Transaction proposal and approval workflow
- Owner management (add/remove owners)
- Signature tracking and revocation capabilities
- Comprehensive error handling and security validations
- Balance management and deposit functionality

### 🔧 Technical Implementation
- **150+ lines** of clean, production-ready Clarity code
- **11 error constants** for comprehensive error handling
- **Role-based access control** with owner verification
- **Transaction state management** with execution tracking
- **Signature aggregation** with threshold enforcement

### 🧪 Contract Functions
- Setup: `initialize-wallet`, `add-owner`, `remove-owner`
- Operations: `deposit`, `propose-transaction`, `sign-transaction`, `execute-transaction`
- Utilities: Balance checking, signature verification, transaction queries

### 📚 Documentation
- Complete README with usage instructions and examples
- Function documentation with parameter descriptions
- Error code reference and security feature overview
- Testing guidelines and deployment instructions

This implementation teaches core blockchain concepts including multi-signature security, role-based permissions, and decentralized governance patterns.

