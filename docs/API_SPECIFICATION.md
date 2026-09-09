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

### 🔐 2.1 Authentication & Identity Service

#### `POST /api/v1/auth/register`
- **Description**: Registers a new user with a specific role (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).
- **Request Body**:
```json
{
  "fullName": "Eunice Quetsia",
  "email": "eunice@agronexus.io",
  "password": "SecurePassword123!",
  "role": "FARMER",
  "phoneNumber": "+237690000000",
  "latitude": 3.8480,
  "longitude": 11.5021
}
```
- **Response `201 Created`**:
```json
{
  "userId": 1,
  "email": "eunice@agronexus.io",
  "role": "FARMER",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "User registered successfully"
}
```

#### `POST /api/v1/auth/login`
- **Description**: Authenticates user credentials and returns JWT bearer token.

---

### 🌽 2.2 Spatial Produce Catalog Service

#### `POST /api/v1/products`
- **Role Required**: `FARMER` or `ADMIN`
- **Description**: Lists new agricultural produce with location spatial coordinates.
- **Request Body**:
```json
{
  "title": "Fresh Organic Plantains",
  "category": "FRUITS_AND_TUBERS",
  "description": "Premium Grade-A plantains harvested from West Region",
  "pricePerUnit": 450.00,
  "unitType": "kg",
  "availableQuantity": 1500.0,
  "latitude": 3.8480,
  "longitude": 11.5021
}
```

#### `GET /api/v1/products/radial-search`
- **Description**: Queries produce listings within a specified distance radius using PostGIS.
- **Query Parameters**:
  - `lat` (double): Latitude (e.g., `3.8480`)
  - `lon` (double): Longitude (e.g., `11.5021`)
  - `radiusKm` (double): Radius in kilometers (e.g., `50.0`)
  - `category` (string, optional): Produce category filter
- **Response `200 OK`**:
```json
[
  {
    "productId": 101,
    "title": "Fresh Organic Plantains",
    "category": "FRUITS_AND_TUBERS",
    "pricePerUnit": 450.00,
    "availableQuantity": 1500.0,
    "distanceKm": 12.4,
    "farmerName": "Eunice Quetsia",
    "latitude": 3.8480,
    "longitude": 11.5021
  }
]
```

---

### 💳 2.3 Sales & Escrow Financial Engine

#### `POST /api/v1/orders/create`
- **Role Required**: `BUYER`
- **Description**: Places an order and locks total funds in admin-held escrow.
- **Request Body**:
```json
{
  "productId": 101,
  "quantity": 200.0,
  "transportFee": 5000.00,
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
  "depositBuffer": 10000.00,
  "totalEscrowLocked": 115000.00,
  "escrowStatus": "HELD_IN_ESCROW"
}
```

#### `PUT /api/v1/orders/{orderCode}/complete`
- **Role Required**: `BUYER` or `ADMIN`
- **Description**: Verifies delivery completion and triggers 85%/15% escrow fund disbursement.

---

### 🚚 2.4 Transport & Logistics Dispatch

#### `GET /api/v1/transports/available-jobs`
- **Role Required**: `TRANSPORTER`
- **Description**: Returns open delivery jobs filtered by proximity to transporter location.

---

### 🌡️ 2.5 Storage Conservation & IoT Telemetry Service

#### `POST /api/v1/telemetry`
- **Role Required**: `SYSTEM` / IoT ESP32 Hardware Node
- **Description**: Ingests temperature, humidity, and gas metrics from storage units.
- **Request Body**:
```json
{
  "nodeId": "STORAGE_UNIT_01",
  "temperature": 26.5,
  "humidity": 78.2,
  "gasLevel": 420,
  "isAlertTriggered": true
}
```

---

### 🤖 2.6 Guarded RAG AI Assistant

#### `POST /api/v1/ai/query`
- **Role Required**: Any authenticated user
- **Description**: Evaluates user query against domain guardrails, retrieves FAO/USDA vectors, and returns grounded answer with citations.
- **Request Body**:
```json
{
  "query": "What is the optimal storage temperature and humidity for harvested cassava to prevent decay?"
}
```
- **Response `200 OK`**:
```json
{
  "isDomainAllowed": true,
  "answer": "Harvested cassava roots should be stored at temperatures between 10°C and 15°C with a relative humidity of 85% to 90% to delay post-harvest physiological deterioration (PPD).",
  "citations": [
    {
      "sourceAgency": "FAO",
      "document": "FAO Agriculture Report No. 42: Root & Tuber Preservation",
      "relevanceScore": 0.942
    }
  ]
}
```
