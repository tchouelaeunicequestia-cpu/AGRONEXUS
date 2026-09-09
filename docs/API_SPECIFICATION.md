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
- **Description**: Places an order and locks total funds in admin-held escrow. Supports both Freight Delivery and Direct Buyer Self-Pickup, with 1.5% MTN MoMo / Orange Money cashout fee coverage.
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
  "escrowStatus": "HELD_IN_ESCROW"
}
```

#### `PUT /api/v1/orders/{orderCode}/complete`
- **Role Required**: `BUYER` or `ADMIN`
- **Description**: Verifies delivery completion and triggers escrow fund disbursement (85% Farmer / 15% Transporter, or 100% Farmer for Self-Pickup).
