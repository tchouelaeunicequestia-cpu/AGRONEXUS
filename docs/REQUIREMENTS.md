# Functional & Non-Functional Requirements — AgroNexus

This document specifies the complete functional epics, non-functional requirements, status traceability matrix, and current implementation progress for the **AgroNexus** platform.

> [!NOTE]
> **Implementation Status Legend**:
> - `[IMPLEMENTED]`: Operational in source code and connected across backend & frontend.
> - `[PARTIALLY IMPLEMENTED]`: Backend logic or database model exists, but full workflow/frontend integration is incomplete.
> - `[PROTOTYPE / MOCK]`: Scaffolding or frontend UI exists with canned/mock data or basic guardrail prototypes.
> - `[PENDING]`: Design specification complete, but implementation is not yet started.

---

## 1. Implementation Progress Overview

| Epic / Feature Area | Functional Requirements | Status | Estimated Completion |
|---|---|---|---:|
| **Epic 1: Auth & Identity** | FR1.1 – FR1.4 | Partially Implemented | 60% |
| **Epic 2: Produce Catalog & Spatial Discovery** | FR2.1 – FR2.3 | Partially Implemented | 65% |
| **Epic 3: Sales, Escrow & Payments** | FR3.1 – FR3.4 | Backend Implemented / Frontend Pending | 45% |
| **Epic 4: Transport & Logistics** | FR4.1 – FR4.3 | Scaffolding / Pending | 10% |
| **Epic 5: Storage & IoT Telemetry** | FR5.1 – FR5.3 | Ingestion Implemented / UI Mocked | 50% |
| **Epic 6: RAG AI Assistant** | FR6.1 – FR6.3 | Keyword Guardrail Prototype | 35% |
| **Epic 7: User Profile & Settings** | FR7.1 – FR7.2 | Pending | 0% |
| **Overall Platform Status** | **FR1.1 – FR7.2** | **Working Prototype / MVP Stage** | **~39–45%** |

---

## 2. Functional Requirements (FR) & Current Status

### Epic 1: Authentication & Identity Management
- **FR1.1** `[IMPLEMENTED]`: The system shall support multi-role user registration (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).
- **FR1.2** `[IMPLEMENTED]`: The system shall enforce JWT-based stateless authentication with secure refresh token rotation mechanics (`JwtService.java`, `SecurityConfig.java`, Flutter `auth_provider.dart`).
- **FR1.3** `[PARTIALLY IMPLEMENTED]`: The system shall verify identity credentials. *Status Note*: Administrative approval before elevating user roles is specified in the schema/roles, but registration currently sets accounts as verified immediately.
- **FR1.4** `[PROTOTYPE / MOCK]`: The system shall support live face scan verification metadata logging during onboarding. *Status Note*: Biometric UI flow exists on Flutter frontend (`register_screen.dart`); backend audit logging endpoint for face metadata is pending.

### Epic 2: Spatial Produce Catalog & Discovery
- **FR2.1** `[PARTIALLY IMPLEMENTED]`: Farmers shall be able to create, update, and manage produce listings including price per unit, available quantity, category, and PostGIS location coordinates (`Point, SRID 4326`). *Status Note*: Product creation via `ProductController.java` is implemented; update/delete endpoints and farmer listing query (`/products/my-listings`) are pending.
- **FR2.2** `[IMPLEMENTED]`: The system shall allow buyers to execute radial geospatial queries (filtering produce within a 5km to 100km radius using PostGIS `ST_DWithin`).
- **FR2.3** `[PROTOTYPE / MOCK]`: The system shall compute dynamic distance badges and estimated freight distance for search results. *Status Note*: Spatial distances are queried in database, but dynamic distance badges on cards use estimated mock visual distance indicators.

### Epic 3: Sales, Escrow & Payment Processing
- **FR3.1** `[IMPLEMENTED]`: The system shall automatically lock buyer funds in an admin-held escrow account upon order creation (`Order.java`, `EscrowController.java`).
- **FR3.2** `[IMPLEMENTED]`: The escrow engine (`EscrowEngineService.java`) shall calculate total depository using the formula:  
  - **Freight Delivery**:  
    $$\text{Total Depository} = \text{Item Cost} + \text{Transport Fee} + (2 \times \text{Deposit Buffer})$$  
  - **Direct Buyer Self-Pickup**:  
    $$\text{Total Depository} = \text{Item Cost} + (1 \times \text{Deposit Buffer}) \quad [\text{Transport Fee} = 0.00]$$  
  - **Mobile Money Fee Coverage**: The `Deposit Buffer` incorporates a 1.5% MTN MoMo & Orange Money cashout fee buffer, guaranteeing farmers receive 100% net produce price.
- **FR3.3** `[PARTIALLY IMPLEMENTED]`: The system shall disburse escrow funds upon verified delivery. *Status Note*: Backend disbursement endpoint (`/api/v1/escrow/disburse/{code}`) updates status to `COMPLETED`, but integration with real Mobile Money sandboxes and 85/15 wallet payout automation is pending.
- **FR3.4** `[PENDING]`: The system shall provide an admin arbitration workflow for escrow disputes, backed by IoT storage logs and delivery audit trails.

### Epic 4: Transport & Logistics Dispatch
- **FR4.1** `[PROTOTYPE / MOCK]`: Transporters shall view available delivery jobs filtered by proximity and vehicle freight capacity. *Status Note*: Transporter role and `EscrowStatus` enums exist; transporter dashboard UI is a placeholder.
- **FR4.2** `[PARTIALLY IMPLEMENTED]`: The system shall track order delivery state transitions (`PENDING` $\rightarrow$ `HELD_IN_ESCROW` $\rightarrow$ `DISPATCHED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED` $\rightarrow$ `COMPLETED`). *Status Note*: `EscrowStatus` enum contains all state values, but automated trigger logic is pending.
- **FR4.3** `[PENDING]`: Transporters and buyers shall submit cryptographic or multi-party delivery confirmations upon order handover.

### Epic 5: Storage Conservation & Cyber-Physical IoT Telemetry
- **FR5.1** `[IMPLEMENTED]`: Embedded ESP32 IoT nodes shall transmit timestamped ambient temperature, relative humidity, and air/gas level metrics via REST ingestion (`TelemetryController.java`, `TelemetryLog.java`).
- **FR5.2** `[IMPLEMENTED]`: The system shall evaluate incoming telemetry against safe FAO/USDA crop conservation thresholds and flag alert states.
- **FR5.3** `[PROTOTYPE / MOCK]`: The system shall trigger push/email alerts to storage owners when metrics breach safety limits. *Status Note*: Backend flags alert status; live push/email notifications and farmer dashboard chart connections currently use seeded/mock data.

### Epic 6: Domain-Guarded RAG AI Assistant
- **FR6.1** `[PARTIALLY IMPLEMENTED]`: Users shall query the AI assistant for crop conservation advice, pest management, storage parameters, and market standards.
- **FR6.2** `[PROTOTYPE / MOCK]`: The AI assistant shall pass prompts through a domain guardrail layer (`AiAssistantController.java`) that intercepts and declines non-agricultural queries using rule-based keyword matching.
- **FR6.3** `[PENDING]`: The RAG pipeline shall retrieve top-$k$ relevant text chunks from FAO/USDA/UNECE vector index using `pgvector` cosine similarity and cite official source references. *Status Note*: Vector index and LLM integration are designed in `RAG_AI_PIPELINE.md`, but runtime vector query execution is pending.

### Epic 7: User Profile & Self-Service Settings
- **FR7.1** `[PENDING]`: Users shall manage personal profile details, contact information, notification preferences, and primary delivery addresses.
- **FR7.2** `[PENDING]`: Users shall be able to update non-primary profile details while preserving primary account identifiers and audit histories.

---

## 3. Non-Functional Requirements (NFR) & Verification Targets

- **NFR1 (Performance)**: Spatial radial search queries must return results within $< 250\text{ ms}$ under concurrent load. *Current Target*: PostGIS GiST index configured (`ST_DWithin` baseline measured at 12–64 ms in database benchmarks).
- **NFR2 (Security)**: All API communications must enforce HTTPS/TLS encryption. Passwords must be salted and hashed using BCrypt (`strength = 12`). *Status*: `[IMPLEMENTED]` (BCrypt strength 12 enforced).
- **NFR3 (Scalability)**: Backend microservices must maintain stateless session management to enable horizontal scaling. *Status*: `[IMPLEMENTED]` (Stateless Spring Security + JWT).
- **NFR4 (Availability & Uptime)**: Telemetry ingestion endpoints must maintain $99.9\%$ uptime to ensure zero data gaps in storage monitoring. *Target Metric for Deployment*.
- **NFR5 (AI Accuracy)**: RAG guardrail rejection accuracy for out-of-domain prompts target $> 98\%$, and hallucination rates $< 2\%$. *Status*: Target accuracy benchmark specified for production RAG evaluation.
