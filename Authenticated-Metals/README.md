# Precious Metal Digital Asset Registry Smart Contract

A comprehensive tokenization platform for physical precious metals with vault custody, auditing capabilities, price tracking, and transfer management system built on the Stacks blockchain.

## Overview

This smart contract provides a complete infrastructure for tokenizing physical precious metals (gold, silver, platinum, palladium) while maintaining custody in authorized storage facilities. The platform includes real-time price tracking, third-party auditing, and comprehensive transfer management.

## Features

- **Multi-Metal Support**: Gold, Silver, Platinum, and Palladium tokenization
- **Vault Integration**: Authorized storage facility management
- **Real-Time Pricing**: Market price tracking and automatic valuation updates
- **Third-Party Auditing**: Accredited auditor verification system
- **Transfer Controls**: Configurable transfer restrictions and permissions
- **Batch Operations**: Efficient bulk token creation
- **Emergency Controls**: Administrative suspension capabilities

## Supported Metal Types

| Metal Type | Identifier | Description |
|------------|------------|-------------|
| Gold | `u1` | precious-metal-gold |
| Silver | `u2` | precious-metal-silver |
| Platinum | `u3` | precious-metal-platinum |
| Palladium | `u4` | precious-metal-palladium |

## Core Data Structures

### Digital Asset Registry
Each tokenized asset contains:
- Current owner address
- Underlying metal type
- Physical weight in grams
- Metal purity (basis points, max 10000)
- Authenticity certificate hash
- Storage vault location
- Creation and verification timestamps
- Current market value

### Storage Facilities
Authorized vaults maintain:
- Facility name and location
- Authorization status
- Storage capacity and current holdings
- Operator address

### Market Pricing
Real-time price data includes:
- Price per gram in cents
- Last update block height
- Metal type identifier

## Key Functions

### Administrative Functions

#### `suspend-platform-operations()`
Temporarily halts all platform operations (admin only)

#### `resume-platform-operations()`
Resumes normal platform operations (admin only)

#### `register-authorized-storage-facility(facility-address, facility-name, location, storage-capacity)`
Registers a new authorized storage facility (admin only)

#### `update-precious-metal-market-price(metal-type, price-per-gram-cents)`
Updates market pricing data for specified metal type (admin only)

#### `accredit-verification-auditor(auditor-address, organization-name, certification-details)`
Adds a new accredited third-party auditor (admin only)

### Core Operations

#### `create-digital-asset-token(recipient-address, metal-type, weight-grams, purity-basis-points, certificate-hash, vault-location)`
Creates a new digital asset token representing physical metal
- Only callable by authorized storage facilities
- Automatically calculates market value
- Updates facility holdings
- Returns new asset identifier

#### `execute-asset-transfer(asset-identifier, current-owner, new-recipient)`
Transfers ownership of a digital asset
- Must be called by current owner
- Checks for transfer restrictions
- Updates ownership records

#### `destroy-digital-asset-token(asset-identifier)`
Destroys a digital asset token (typically when physical metal is withdrawn)
- Callable by asset owner or authorized facility
- Updates total tokenized weight

#### `perform-asset-verification-audit(asset-identifier, updated-certificate-hash)`
Performs third-party verification audit
- Only callable by accredited auditors
- Updates certificate hash and verification timestamp

### Query Functions

#### `retrieve-asset-details(asset-identifier)`
Returns complete asset metadata

#### `get-owner-asset-balance(owner-address, asset-identifier)`
Returns ownership quantity for specific asset

#### `calculate-asset-current-value(asset-identifier)`
Calculates current market value based on weight, purity, and current prices

#### `get-platform-statistics()`
Returns platform-wide statistics including total assets and tokenized weight

#### `check-asset-transfer-restrictions(asset-identifier)`
Checks if an asset has active transfer restrictions

### Transfer Management

#### `impose-asset-transfer-restriction(asset-identifier, restriction-justification)`
Imposes transfer restrictions on specific asset (admin only)

#### `remove-asset-transfer-restriction(asset-identifier)`
Removes existing transfer restrictions (admin only)

### Batch Operations

#### `batch-create-digital-assets(...)`
Creates multiple digital assets in a single transaction (up to 10 assets)

### Emergency Functions

#### `activate-emergency-suspension()`
Immediately suspends all platform operations (admin only)

#### `refresh-asset-market-valuation(asset-identifier)`
Updates market valuation for specific asset based on current prices

## Error Constants

| Error Code | Constant | Description |
|------------|----------|-------------|
| u100 | ERR-UNAUTHORIZED-ACCESS | Insufficient permissions |
| u101 | ERR-RESOURCE-NOT-FOUND | Requested resource does not exist |
| u102 | ERR-DUPLICATE-ENTRY | Duplicate entry attempted |
| u103 | ERR-INVALID-AMOUNT | Invalid amount specified |
| u104 | ERR-INSUFFICIENT-TOKEN-BALANCE | Insufficient token balance |
| u105 | ERR-UNSUPPORTED-METAL-TYPE | Metal type not supported |
| u106 | ERR-VAULT-NOT-AUTHORIZED | Storage facility not authorized |
| u107 | ERR-CERTIFICATE-EXPIRED | Authenticity certificate expired |
| u108 | ERR-INVALID-PURITY-LEVEL | Invalid purity level specified |
| u109 | ERR-TRANSFER-OPERATION-FAILED | Transfer operation failed |
| u110 | ERR-INVALID-PRICE-DATA | Invalid price data provided |
| u111 | ERR-MALFORMED-INPUT-DATA | Input data format invalid |

## Usage Examples

### Creating a Digital Asset
```clarity
(create-digital-asset-token 
  'SP1HJMZ6QY1J8KF8ZQ5Z5HJMZ6QY1J8KF8ZQ5Z5
  precious-metal-gold
  u1000  ; 1000 grams
  u9999  ; 99.99% purity
  0x1234567890abcdef1234567890abcdef12345678  ; certificate hash
  "Vault-NYC-001"
)
```

### Transferring an Asset
```clarity
(execute-asset-transfer 
  u1     ; asset identifier
  'SP1HJMZ6QY1J8KF8ZQ5Z5HJMZ6QY1J8KF8ZQ5Z5  ; current owner
  'SP2HJMZ6QY1J8KF8ZQ5Z5HJMZ6QY1J8KF8ZQ5Z5  ; new recipient
)
```

### Querying Asset Details
```clarity
(retrieve-asset-details u1)
```

### Checking Current Value
```clarity
(calculate-asset-current-value u1)
```

## Security Features

- **Role-based Access Control**: Admin, storage facilities, and auditors have specific permissions
- **Input Validation**: Comprehensive validation for all inputs
- **Transfer Restrictions**: Configurable restrictions for compliance requirements
- **Emergency Suspension**: Immediate platform halt capability
- **Audit Trail**: Complete event logging for all operations

## Integration Requirements

### For Storage Facilities
1. Register facility with administrator
2. Obtain authorization status
3. Implement secure metal storage protocols
4. Maintain accurate weight and purity records

### For Auditors
1. Obtain accreditation from administrator
2. Implement verification procedures
3. Generate certificate hashes for authenticity
4. Perform regular audit cycles

### For Users
1. Receive tokens from authorized facilities
2. Use standard transfer functions for ownership changes
3. Monitor market valuations
4. Comply with any transfer restrictions

## Deployment Considerations

- Contract administrator has significant control over platform operations
- Market price updates require regular maintenance
- Storage facility authorization is critical for security
- Regular auditing ensures asset authenticity
- Emergency procedures should be well-documented