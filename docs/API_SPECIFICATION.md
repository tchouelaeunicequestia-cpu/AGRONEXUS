# REST API Specification — AgroNexus

This document defines the RESTful backend endpoints, authentication headers, request/response DTO schemas, HTTP status codes, and implementation status for the **AgroNexus** backend microservices.

---

## 1. Authentication & Security Headers

All endpoints (except public `/api/v1/auth/*`) require a Bearer JSON Web Token (JWT) in the Authorization header:

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

## 2. Implemented API Endpoints Reference

### 🔐 2.1 Authentication (`AuthController.java`)

#### `POST /api/v1/auth/register`
- **Access**: Public
- **Description**: Validates and creates a pending user account, stores only a hash of the national ID, records biometric evidence status, and issues email and phone verification challenges.
- **Success Response**: Returns a `message` explaining that email and phone verification must be completed before sign-in; roles requiring approval also mention administrative vetting.
- **Request Body**:
```json
{
  "fullName": "Eunice Tchouela",
  "email": "user@example.com",
  "password": "StrongPassword123",
  "phoneNumber": "+237600000000",
  "nationalId": "CNI-123456",
  "biometricVerified": true,
  "role": "FARMER",
  "latitude": 3.848,
  "longitude": 11.5021
}
```

#### `POST /api/v1/auth/login`
- **Access**: Public
- **Description**: Authenticates user credentials and returns JWT access token, refresh token, and a user-facing success `message`.

#### `POST /api/v1/auth/refresh`
- **Access**: Public
- **Description**: Exchanges a valid refresh token for a new JWT access token.

#### `POST /api/v1/auth/verify`
- **Access**: Public
- **Description**: Verifies one email or phone OTP. Codes expire after ten minutes, are single-use, and are limited to five attempts.
- **Request Body**:
```json
{
  "email": "user@example.com",
  "channel": "EMAIL",
  "code": "123456"
}
```

#### `POST /api/v1/auth/resend-verification`
- **Access**: Public
- **Description**: Issues a replacement email or phone verification challenge. Production delivery requires a configured email/SMS provider.
- **Request Body**:
```json
{
  "email": "user@example.com",
  "channel": "PHONE"
}
```

---

### 🌽 2.2 Produce Catalog & Spatial Search (`ProductController.java`)

#### `POST /api/v1/products`
- **Access**: `FARMER`, `ADMIN`
- **Description**: Creates a new produce listing with PostGIS location coordinates (`Point`, SRID 4326).
- **Request Body**:
```json
{
  "farmerId": 1,
  "title": "Fresh Yellow Maize",
  "category": "Grains",
  "description": "High yield yellow corn harvested in Mbalmayo",
  "pricePerUnit": 450.00,
  "unitType": "kg",
  "availableQuantity": 500.0,
  "latitude": 3.5167,
  "longitude": 11.5000,
  "imageUrl": "https://example.com/maize.jpg"
}
```

#### `GET /api/v1/products/nearby`
- **Access**: Authenticated users (`BUYER`, `FARMER`, etc.)
- **Query Parameters**:
  - `latitude` (double, required): Buyer GPS latitude.
  - `longitude` (double, required): Buyer GPS longitude.
  - `radiusMeters` (double, default 50000): Radial search distance in meters.
- **Description**: PostGIS `ST_DWithin` spatial query returning produce listings within specified radius.

*Planned / Pending Endpoint*: `GET /api/v1/products/my-listings` (Farmers query their own products).

---

### 💳 2.3 Sales & Escrow Financial Engine (`EscrowController.java`)

#### `POST /api/v1/escrow/order`
- **Access**: `BUYER`, `ADMIN`
- **Description**: Creates an order, calculates a transparent platform service fee equal to 5% of the item cost, and generates an order notification. Self-pickup locks immediately; freight delivery waits for transporter quote approval.
- **Official Escrow Wallets**:
  - **Orange Money Escrow Wallet**: `+237694002750`
  - **MTN Mobile Money Escrow Wallet**: `+237651305141`
- **Request Body**:
```json
{
  "buyerId": 2,
  "productId": 1,
  "quantity": 200.0,
  "transportFee": 5000.00,
  "isSelfPickup": false,
  "deliveryAddress": "Bastos, Yaoundé, Cameroon"
}
```

For freight delivery, the order is created as `TRANSPORT_QUOTE_PENDING` and no funds
are locked yet. A transporter submits a quote through
`POST /api/v1/escrow/order/{orderCode}/quote`; the buyer then approves it through
`POST /api/v1/escrow/order/{orderCode}/approve-quote`. Only after approval does
the order transition to `HELD_IN_ESCROW` with its final escrow total.

Dashboard quote queues:

- `GET /api/v1/transporter/quote-requests` returns delivery orders waiting for a
  transporter quote.
- `GET /api/v1/escrow/buyer/orders` returns the authenticated buyer's quoted
  orders awaiting approval.

#### `POST /api/v1/escrow/disburse/{orderCode}`
- **Access**: `BUYER`, `ADMIN`
- **Description**: Updates order escrow status to `COMPLETED` and prepares fund disbursement (85% Farmer / 15% Transporter or 100% Farmer for Self-Pickup).

---

### 🌡️ 2.4 IoT Telemetry Ingestion (`TelemetryController.java`)

#### `POST /api/v1/telemetry/log`
- **Access**: Public / Device Node
- **Description**: Ingests sensor data (temperature, humidity, gas level), checks safety thresholds, and stores telemetry log.

#### `GET /api/v1/telemetry/node/{nodeId}/latest`
- **Access**: Authenticated users
- **Description**: Retrieves latest 50 telemetry readings for a specific storage node.

---

### 🤖 2.5 Domain-Guarded AI Assistant (`AiAssistantController.java`)

#### `POST /api/v1/ai/query`
- **Access**: Authenticated users
- **Description**: Passes user query through agricultural keyword guardrails and returns grounded advice or rejection message.
