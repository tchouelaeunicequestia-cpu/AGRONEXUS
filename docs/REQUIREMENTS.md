# Functional & Non-Functional Requirements — AgroNexus

This document specifies the complete functional epics, non-functional requirements, status traceability matrix, and current implementation progress for the **AgroNexus** platform.

> **Status snapshot:** 17 September 2026. This matrix reflects the current backend and Flutter implementation, including the admin account control workflow, live telemetry alerts, and transporter corridor map.

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
| **Epic 1: Auth & Identity** | FR1.1 – FR1.8 | Partially Implemented | 80% |
| **Epic 2: Produce Catalog & Spatial Discovery** | FR2.1 – FR2.3 | Partially Implemented | 65% |
| **Epic 3: Sales, Escrow & Payments** | FR3.1 – FR3.4 | Backend Implemented / Frontend Pending | 45% |
| **Epic 4: Transport & Logistics** | FR4.1 – FR4.3 | Corridor UI Implemented / Dispatch Pending | 35% |
| **Epic 5: Storage & IoT Telemetry** | FR5.1 – FR5.3 | Ingestion & Live Alerts Implemented | 75% |
| **Epic 6: RAG AI Assistant** | FR6.1 – FR6.3 | Keyword Guardrail Prototype | 35% |
| **Epic 7: User Profile & Settings** | FR7.1 – FR7.2 | Pending | 0% |
| **Overall Platform Status** | **FR1.1 – FR7.2** | **Working Prototype / MVP Stage** | **~50%** |

---

## 2. Functional Requirements (FR) & Current Status

### Epic 1: Authentication & Identity Management
- **FR1.1** `[IMPLEMENTED]`: The system shall support multi-role user registration (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).
- **FR1.2** `[IMPLEMENTED]`: The system shall enforce JWT-based stateless authentication with secure refresh token rotation mechanics (`JwtService.java`, `SecurityConfig.java`, Flutter `auth_provider.dart`).
- **FR1.3** `[IMPLEMENTED]`: The system shall verify identity credentials. *Status Note*: Role-gated admin account management supports approval and de-approval through `/api/v1/admin/approve-user/{userId}` and `/api/v1/admin/deapprove-user/{userId}`; administrator accounts cannot be de-approved.
- **FR1.4** `[PROTOTYPE / MOCK]`: The system shall support live face scan verification metadata logging during onboarding. *Status Note*: Biometric UI flow exists on Flutter frontend (`register_screen.dart`); backend audit logging endpoint for face metadata is pending.
- **FR1.5** `[IMPLEMENTED]`: The system shall validate legal name, email, international phone number, national identity number, and password format on the client and server.
- **FR1.6** `[PARTIALLY IMPLEMENTED]`: The system shall verify email and phone ownership using separate expiring, single-use OTP challenges. *Status Note*: Challenge creation, hashing, expiry, attempt limits, verification endpoints, and Flutter OTP collection are implemented; production email/SMS provider delivery remains to be configured.
- **FR1.7** `[IMPLEMENTED]`: The system shall maintain separate `emailVerified`, `phoneVerified`, `identityVerified`, `biometricVerified`, and `isVerified` states. Accounts remain inactive until required checks are complete.
- **FR1.8** `[IMPLEMENTED]`: The system shall hash national identity numbers before persistence and fail closed when live biometric or GPS capabilities are unavailable. Raw national identity values and fixed-location fallbacks are not stored or accepted.

### Epic 2: Spatial Produce Catalog & Discovery
- **FR2.1** `[PARTIALLY IMPLEMENTED]`: Farmers shall be able to create, update, delete, and manage produce listings including price per unit, available quantity, category, and PostGIS location coordinates (`Point, SRID 4326`). *Status Note*: Product creation via `ProductController.java` is implemented; update/delete endpoints and farmer listing query (`/products/my-listings`) are pending.
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
- **FR4.1** `[PARTIALLY IMPLEMENTED]`: Transporters shall view available delivery jobs filtered by proximity and vehicle freight capacity. *Status Note*: The modern transporter dashboard now includes an interactive OpenStreetMap corridor view with farmer depot, live GPS position when available, and buyer hub markers; job filtering and dispatch assignment remain pending.
- **FR4.2** `[PARTIALLY IMPLEMENTED]`: The system shall track order delivery state transitions (`PENDING` $\rightarrow$ `HELD_IN_ESCROW` $\rightarrow$ `DISPATCHED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED` $\rightarrow$ `COMPLETED`). *Status Note*: `EscrowStatus` enum contains all state values and the transporter corridor UI is wired, but automated order transition and live backend vehicle tracking remain pending.
- **FR4.3** `[PENDING]`: Transporters and buyers shall submit cryptographic or multi-party delivery confirmations upon order handover.

### Epic 5: Storage Conservation & Cyber-Physical IoT Telemetry
- **FR5.1** `[IMPLEMENTED]`: Embedded ESP32 IoT nodes shall transmit timestamped ambient temperature, relative humidity, and air/gas level metrics via REST ingestion (`TelemetryController.java`, `TelemetryLog.java`).
- **FR5.2** `[IMPLEMENTED]`: The system shall evaluate incoming telemetry against safe FAO/USDA crop conservation thresholds and flag alert states.
- **FR5.3** `[PARTIALLY IMPLEMENTED]`: The system shall trigger push/email alerts to storage owners when metrics breach safety limits. *Status Note*: Telemetry breaches are now published to the authenticated Server-Sent Events endpoint `/api/v1/telemetry/alerts/stream` and displayed immediately in the Agronomist dashboard. Push/email delivery and farmer dashboard chart connections remain pending.

### Epic 6: Domain-Guarded RAG AI Assistant
- **FR6.1** `[PARTIALLY IMPLEMENTED]`: Users shall query the AI assistant for crop conservation advice, pest management, storage parameters, and market standards.
- **FR6.2** `[PROTOTYPE / MOCK]`: The AI assistant shall pass prompts through a domain guardrail layer (`AiAssistantController.java`) that intercepts and declines non-agricultural queries using rule-based keyword matching.
- **FR6.3** `[PENDING]`: The RAG pipeline shall retrieve top-$k$ relevant text chunks from FAO/USDA/UNECE vector index using `pgvector` cosine similarity and cite official source references. *Status Note*: Vector index and LLM integration are designed in `RAG_AI_PIPELINE.md`, but runtime vector query execution is pending.

### Epic 7: User Profile & Self-Service Settings
- **FR7.1** `[PENDING]`: Users shall manage personal profile details, contact information, notification preferences, and primary delivery addresses.
- **FR7.2** `[PENDING]`: Users shall be able to update non-primary profile details while preserving primary account identifiers and audit histories.

Epic 8: Immersive UI Design, Onboarding & Domain-Guarded AI Assistant
Story 8.1: Visual-First Cross-Platform UI & Card Layout
As a system user across mobile, web, or desktop,

I want to navigate an interface built with fluid responsive grids, edge-to-edge media cards, soft background gradients, and glassmorphism overlays,

So that the platform provides a clean, premium, and professional digital experience.

Acceptance Criteria / What to do:

Implement responsive Flutter layouts that adapt seamlessly across web, mobile, and desktop breakpoints.

Apply custom border-radius tokens, soft drop-shadows, and image overlays to content cards in the produce catalog and dashboards.

Incorporate glassmorphism effects (BackdropFilter blur) on floating navigation bars and modal overlays.

Ensure smooth hover states and transition animations on all interactive buttons and actionable components.

Story 8.2: Lightweight Startup Splash and Progressive Role Onboarding
As a new user launching AgroNexus,

I want to open the application through a fast, non-blocking splash screen that transitions into an intuitive role and preference selection wizard,

So that I can personalize my view and access the marketplace instantly without an immediate, rigid login wall.

Acceptance Criteria / What to do:

Build a lightweight startup/splash screen route that loads instantly without blocking essential UI assets.

Create a multi-step preference wizard component enabling users to specify their functional role context (Farmer, Buyer, Transporter, Agronomist).

Store local preference states temporarily so that the home feed updates prior to formal database account creation.

Provide a visible "Skip" option allowing users to bypass the setup wizard and land directly on the public produce feed.

Story 8.3: Floating AI Assistant Widget & Quick-Action Prompt Chips
As a user navigating the AgroNexus platform,

I want to access a floating AI assistant widget featuring pre-built, tap-to-run prompt chips,

So that I can instantly query storage conservation parameters and market practices without leaving my current screen.

Acceptance Criteria / What to do:

Develop a persistent Floating Action Button (FAB) or docked shell component that toggles the RAG AI chat overlay.

Design a dedicated container for dynamic prompt chips that auto-inject preset agricultural queries into the input text field upon clicking.

Implement asynchronous loading states (such as animated typing indicators or skeleton loaders) while backend vector searches and LLM inferences resolve.

Story 8.4: Domain-Guarded RAG AI Stream with Verified Citations
As a farmer or agricultural stakeholder querying the AI assistant,

I want the system to strictly reject out-of-domain prompts and deliver responses grounded exclusively in authoritative standards (FAO, USDA, UNECE) with expandable citations,

So that I can rely on safe, verified advisory support and avoid crop loss caused by ungrounded hallucinations.

Acceptance Criteria / What to do:

Implement a backend guardrail validation pipeline that intercepts user queries and checks domain scope before running vector similarity searches via pgvector.

Render structured chat responses containing generated advisory text alongside expandable source references pointing to official handbooks.

Display clear rejection states and friendly fallback messages within the chat stream if a user prompt falls outside approved agricultural parameters.
---

## 3. Non-Functional Requirements (NFR) & Verification Targets

- **NFR1 (Performance)**: Spatial radial search queries must return results within $< 250\text{ ms}$ under concurrent load. *Current Target*: PostGIS GiST index configured (`ST_DWithin` baseline measured at 12–64 ms in database benchmarks).
- **NFR2 (Security)**: All API communications must enforce HTTPS/TLS encryption. Passwords must be salted and hashed using BCrypt (`strength = 12`). *Status*: `[IMPLEMENTED]` (BCrypt strength 12 enforced).
- **NFR3 (Scalability)**: Backend microservices must maintain stateless session management to enable horizontal scaling. *Status*: `[IMPLEMENTED]` (Stateless Spring Security + JWT).
- **NFR4 (Availability & Uptime)**: Telemetry ingestion endpoints must maintain $99.9\%$ uptime to ensure zero data gaps in storage monitoring. *Target Metric for Deployment*.
- **NFR5 (AI Accuracy)**: RAG guardrail rejection accuracy for out-of-domain prompts target $> 98\%$, and hallucination rates $< 2\%$. *Status*: Target accuracy benchmark specified for production RAG evaluation.
