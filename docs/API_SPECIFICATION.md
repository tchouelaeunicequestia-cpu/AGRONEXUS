# REST API Specification — AgroNexus

This document defines the RESTful backend endpoints, authentication headers, request/response DTO schemas, and HTTP status codes for the **AgroNexus** microservices API.

---

## 1. Authentication & Security Headers

All endpoints (except public `/api/v1/auth/*`) require a Bearer JSON Web Token (JWT) in the Authorization header:

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

## 2. API Endpoints Reference

### 💳 2.3 Sales & Escrow Financial Engine

#### `POST /api/v1/orders/create`
- **Role Required**: `BUYER`
- **Description**: Places an order, routes payments to official Mobile Money Escrow Wallets, and dispatches automated admin alerts containing the **Farmer's direct phone number**.
- **Official Escrow Wallets**:
  - **Orange Money Escrow Wallet**: `+237694002750`
  - **MTN Mobile Money Escrow Wallet**: `+237651305141`
- **Request Body**:
```json
{
  "productId": 101,
  "quantity": 200.0,
  "transportFee": 5000.00,
  "isSelfPickup": false,
  "deliveryAddress": "Bastos, Yaoundé, Cameroon",
  "destLatitude": 3.8700,
  "destLongitude": 11.5200
}
```
- **Response `201 Created`**:
```json
{
  "orderCode": "ORD-2026-98214",
  "itemCost": 90000.00,
  "transportFee": 5000.00,
  "depositBuffer": 6350.00,
  "totalEscrowLocked": 107700.00,
  "isSelfPickup": false,
  "orangeMoneyEscrowWallet": "+237694002750",
  "mtnMomoEscrowWallet": "+237651305141",
  "adminNotificationText": "🔔 [AGRONEXUS ESCROW ALERT]\nOrder Code: ORD-2026-98214\nTotal Escrow Locked: 107700.00 XAF\nBuyer: [Buyer Name] (Phone: +237690000002)\nFarmer: [Farmer Name] (Phone: +237690000001)\nProduce: [Product Name] ([Quantity] kg)\nMode: FREIGHT DELIVERY",
  "escrowStatus": "HELD_IN_ESCROW"
}
```

#### `PUT /api/v1/orders/{orderCode}/complete`
- **Role Required**: `BUYER` or `ADMIN`
- **Description**: Verifies delivery completion and triggers escrow fund disbursement (85% Farmer / 15% Transporter, or 100% Farmer for Self-Pickup).
