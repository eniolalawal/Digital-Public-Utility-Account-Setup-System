# Digital Public Utility Account Setup System

A comprehensive blockchain-based utility account management system built on Stacks using Clarity smart contracts.

## Overview

This system manages the complete lifecycle of utility account setup, from initial customer registration through service activation and ongoing billing management.

## System Architecture

### Core Contracts

1. **Customer Registration Contract** (`customer-registration.clar`)
    - Manages new customer onboarding
    - Validates customer information
    - Tracks registration status

2. **Deposit Calculation Contract** (`deposit-calculation.clar`)
    - Calculates security deposits based on credit history
    - Manages deposit requirements and adjustments
    - Handles deposit refund logic

3. **Service Activation Contract** (`service-activation.clar`)
    - Coordinates meter installation scheduling
    - Manages service startup procedures
    - Tracks activation status and completion

4. **Billing Setup Contract** (`billing-setup.clar`)
    - Establishes monthly billing cycles
    - Configures payment methods and preferences
    - Manages billing account creation

5. **Transfer Processing Contract** (`transfer-processing.clar`)
    - Handles account transfers between properties
    - Manages transfer requests and approvals
    - Coordinates service disconnection/reconnection

## Key Features

- **Decentralized Account Management**: All account data stored on-chain
- **Automated Deposit Calculation**: Smart contract-based deposit determination
- **Service Coordination**: Streamlined activation and transfer processes
- **Billing Integration**: Automated billing setup and cycle management
- **Audit Trail**: Complete transaction history for all operations

## Data Types

### Customer Information
- Principal (wallet address)
- Service address
- Contact information
- Credit score category
- Account status

### Service Details
- Meter type and specifications
- Installation scheduling
- Activation dates
- Service parameters

### Financial Information
- Deposit amounts and status
- Billing preferences
- Payment method configuration
- Transfer fees and processing

## Error Codes

- `ERR-NOT-AUTHORIZED` (u100): Caller not authorized for operation
- `ERR-INVALID-INPUT` (u101): Invalid input parameters
- `ERR-ALREADY-EXISTS` (u102): Record already exists
- `ERR-NOT-FOUND` (u103): Record not found
- `ERR-INSUFFICIENT-DEPOSIT` (u104): Deposit amount insufficient
- `ERR-SERVICE-UNAVAILABLE` (u105): Service not available at location
- `ERR-TRANSFER-PENDING` (u106): Transfer already in progress

## Usage

### Customer Registration
\`\`\`clarity
(contract-call? .customer-registration register-customer
"123 Main St"
"John Doe"
"john@email.com"
u750)
\`\`\`

### Deposit Calculation
\`\`\`clarity
(contract-call? .deposit-calculation calculate-deposit
'SP1CUSTOMER...
u750
"residential")
\`\`\`

### Service Activation
\`\`\`clarity
(contract-call? .service-activation schedule-installation
'SP1CUSTOMER...
u20240115
"electric-meter")
\`\`\`

## Testing

Run the test suite:
\`\`\`bash
npm test
\`\`\`
