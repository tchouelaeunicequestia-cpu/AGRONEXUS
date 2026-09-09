# Functional & Non-Functional Requirements — AgroNexus

This document specifies the complete functional epics, non-functional requirements, and traceability matrix for the **AgroNexus** platform.

---

## 1. Functional Requirements (FR)

The system functional requirements are structured into seven core Epics:

### Epic 1: Authentication & Identity Management
- **FR1.1**: The system shall support multi-role user registration (`FARMER`, `BUYER`, `TRANSPORTER`, `AGRONOMIST`, `ADMIN`).
- **FR1.2**: The system shall enforce JWT-based stateless authentication with secure refresh token mechanics.
- **FR1.3**: The system shall verify identity credentials and require administrative approval before elevating user roles.
- **FR1.4**: The system shall support live face scan verification metadata logging for enhanced security during user onboarding.

### Epic 2: Spatial Produce Catalog & Discovery
- **FR2.1**: Farmers shall be able to create, update, and manage produce listings including price per unit, available quantity, category, and PostGIS location coordinates (`Point, 4326`).
- **FR2.2**: The system shall allow buyers and users to execute radial geospatial queries (e.g., filter produce within a 5km to 100km radius from current GPS location).
- **FR2.3**: The system shall compute dynamic distance badges and estimated freight distance for search results.

### Epic 3: Sales, Escrow & Payment Processing
- **FR3.1**: The system shall automatically lock buyer funds in an admin-held escrow account upon order creation.
- **FR3.2**: The escrow engine shall calculate total depository using the formula:  
  - **Freight Delivery**:  
    $$\text{Total Depository} = \text{Item Cost} + \text{Transport Fee} + (2 \times \text{Deposit Buffer})$$  
  - **Direct Buyer Self-Pickup**:  
    $$\text{Total Depository} = \text{Item Cost} + (1 \times \text{Deposit Buffer}) \quad [\text{Transport Fee} = 0.00]$$  
  - **Mobile Money Fee Coverage**: The `Deposit Buffer` automatically incorporates a 1.5% MTN MoMo & Orange Money cashout fee buffer, guaranteeing farmers receive 100% net produce price.
- **FR3.3**: The system shall disburse escrow funds upon verified delivery: 85% to Farmer and 15% to Transporter (or 100% to Farmer for Self-Pickup).
- **FR3.4**: The system shall provide an admin arbitration workflow for escrow disputes, backed by IoT storage logs and delivery audit trails.

### Epic 4: Transport & Logistics Dispatch
- **FR4.1**: Transporters shall view available delivery jobs filtered by proximity and vehicle freight capacity.
- **FR4.2**: The system shall track order delivery state transitions (`PENDING` $\rightarrow$ `HELD_IN_ESCROW` $\rightarrow$ `DISPATCHED` $\rightarrow$ `IN_TRANSIT` $\rightarrow$ `DELIVERED` $\rightarrow$ `COMPLETED`, or `READY_FOR_PICKUP` $\rightarrow$ `SELF_PICKUP_COMPLETED`).
- **FR4.3**: Transporters and buyers shall submit cryptographic or multi-party delivery confirmations upon order handover.

### Epic 5: Storage Conservation & Cyber-Physical IoT Telemetry
- **FR5.1**: Embedded ESP32 IoT nodes shall continuously transmit timestamped ambient temperature, relative humidity, and air/gas level metrics.
- **FR5.2**: The system shall evaluate incoming telemetry against safe FAO/USDA crop conservation thresholds.
- **FR5.3**: The system shall trigger immediate push/email alerts to storage owners when environmental metrics breach safety limits (e.g., temperature $> 25^\circ\text{C}$ or high gas accumulation).

### Epic 6: Domain-Guarded RAG AI Assistant
- **FR6.1**: Users shall query the AI assistant for crop conservation advice, pest management, storage parameters, and market standards.
- **FR6.2**: The AI assistant shall pass all prompts through a domain guardrail layer that intercepts and declines non-agricultural queries.
- **FR6.3**: The RAG pipeline shall retrieve top-$k$ relevant text chunks from FAO/USDA/UNECE vector index using cosine similarity and cite official source references in all advice.

### Epic 7: User Profile & Self-Service Settings
- **FR7.1**: Users shall manage personal profile details, contact information, notification preferences, and primary delivery addresses.
- **FR7.2**: Users shall be able to update non-primary profile details while preserving primary account identifiers and audit histories.

---

## 2. Non-Functional Requirements (NFR)

- **NFR1 (Performance)**: Spatial radial search queries must return results within $< 250\text{ ms}$ under a concurrent load of 1,000 requests.
- **NFR2 (Security)**: All API communications must enforce HTTPS/TLS 1.3 encryption. Passwords must be salted and hashed using BCrypt (`strength = 12`).
- **NFR3 (Scalability)**: Backend microservices must maintain stateless session management to enable seamless horizontal scaling.
- **NFR4 (Availability & Uptime)**: Telemetry ingestion endpoints must maintain $99.9\%$ uptime to ensure zero data gaps in storage monitoring.
- **NFR5 (AI Accuracy)**: RAG guardrail rejection accuracy for out-of-domain prompts must exceed $98\%$, and hallucination rates must stay under $2\%$.
