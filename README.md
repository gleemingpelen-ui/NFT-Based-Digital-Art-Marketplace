# 🎨 NFT-Based Digital Art Marketplace

A decentralized marketplace smart contract for minting, buying, selling, and trading digital art NFTs on the Stacks blockchain. This contract supports royalties, platform fees, listings, and offers.

## ✨ Features

- **🖼️ NFT Minting**: Artists can mint unique digital art with customizable royalty percentages
- **💰 Marketplace Listings**: List NFTs for sale at fixed prices
- **🤝 Offer System**: Make and accept offers on any NFT
- **👑 Creator Royalties**: Automatic royalty distribution on secondary sales (up to 10%)
- **💳 Platform Fees**: Configurable platform fee (default 2.5%)
- **🔄 Transfers**: Direct NFT transfers between users
- **📊 Metadata Storage**: On-chain storage of NFT metadata including creator, URI, and name

## 📋 Contract Overview

**Contract Name**: `NFT-Based-Digital-Art-Marketplace.clar`

**NFT Token**: `digital-art`

**Default Platform Fee**: 2.5% (250 basis points)

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd NFT-Based-Digital-Art-Marketplace
clarinet check
```

## 📖 Usage

### Minting an NFT

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace mint 
  "ipfs://Qm..." 
  u"My Artwork" 
  u500)
```

Parameters:
- `uri`: IPFS or HTTP link to artwork (max 256 characters)
- `name`: Name of the artwork (max 50 characters)
- `royalty-percentage`: Royalty in basis points (500 = 5%, max 1000 = 10%)

### Listing for Sale

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace list-for-sale 
  u1 
  u1000000)
```

Parameters:
- `token-id`: ID of the NFT to list
- `price`: Price in microSTX (1 STX = 1,000,000 microSTX)

### Buying an NFT

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace buy u1)
```

This automatically:
- Transfers STX from buyer to seller
- Pays royalty to creator
- Collects platform fee
- Transfers NFT to buyer

### Making an Offer

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace make-offer 
  u1 
  u800000)
```

### Accepting an Offer

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace accept-offer 
  u1 
  'SP2...)
```

Parameters:
- `token-id`: NFT ID
- `buyer`: Principal address of the buyer who made the offer

### Updating Listing Price

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace update-listing-price 
  u1 
  u1200000)
```

### Unlisting an NFT

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace unlist u1)
```

### Canceling an Offer

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace cancel-offer u1)
```

### Direct Transfer

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace transfer 
  u1 
  tx-sender 
  'SP2...)
```

## 🔍 Read-Only Functions

### Get Token Metadata

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-token-metadata u1)
```

Returns creator, URI, name, and minting block height.

### Get Owner

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-owner u1)
```

### Get Listing Details

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-listing u1)
```

Returns price, seller, and listing block height.

### Get Offer Details

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-offer u1 'SP2...)
```

### Get Royalty Info

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-royalty-info u1)
```

Returns recipient and percentage.

### Get Platform Fee

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-platform-fee)
```

### Get Total Fees Collected

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-total-fees-collected)
```

### Get Last Token ID

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace get-last-token-id)
```

## 🔐 Admin Functions

### Set Platform Fee

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace set-platform-fee u300)
```

Only callable by contract owner. Max 10% (1000 basis points).

### Withdraw Collected Fees

```clarity
(contract-call? .NFT-Based-Digital-Art-Marketplace withdraw-fees 
  u10000000 
  'SP2...)
```

Only callable by contract owner.

## 💡 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Only contract owner can call this function |
| u101 | `err-not-token-owner` | Caller is not the token owner |
| u102 | `err-not-found` | Token or data not found |
| u103 | `err-listing-not-found` | Listing does not exist |
| u104 | `err-not-for-sale` | Token is not listed for sale |
| u105 | `err-insufficient-payment` | Payment amount is insufficient |
| u106 | `err-already-listed` | Token is already listed |
| u107 | `err-unauthorized` | Unauthorized action |
| u108 | `err-self-transfer` | Cannot transfer to self |
| u109 | `err-invalid-price` | Invalid price value |

## 🧪 Testing

```bash
clarinet test
```

## 📝 Contract Details

- **Total Lines**: 243
- **Data Maps**: 4 (token-metadata, listings, offers, royalties)
- **Public Functions**: 11
- **Read-Only Functions**: 9
- **Constants**: 11

## 🛡️ Security Considerations

- All ownership checks are enforced
- Royalty and platform fees are capped at 10%
- Self-transfers are prevented
- Listings are automatically removed on transfer/sale
- Price validation ensures non-zero amounts

## 📄 License

MIT

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Built with ❤️ on Stacks
