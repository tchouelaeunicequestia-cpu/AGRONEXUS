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
- **Description**: Registers a new user account with role selection (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).

#### `POST /api/v1/auth/login`
- **Access**: Public
- **Description**: Authenticates user credentials and returns JWT access token & refresh token.

#### `POST /api/v1/auth/refresh-token`
- **Access**: Public
- **Description**: Exchanges a valid refresh token for a new JWT access token.

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
- **Description**: Creates an escrow order, calculates deposit buffer (including 1.5% MoMo fee coverage), locks funds, and generates admin notification text.
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
