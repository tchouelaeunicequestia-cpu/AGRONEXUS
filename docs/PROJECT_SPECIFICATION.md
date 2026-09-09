# Project Specification — AgroNexus

**Project Title**: AgroNexus: An Integrated Agricultural Management and Information Platform  
**Author**: Eunice Françoise Tchouela Quetsia (Registration No: ICTU20248912)  
**Institution**: The ICT University, Yaoundé Campus, Cameroon  
**Department**: Department of Software Engineering and Artificial Intelligence  
**Degree**: Bachelor of Science (B.Sc.) in Software Engineering and Artificial Intelligence  
**Date**: August 2026  

---

## 1. Introduction & Background

Agriculture is the fundamental economic driver across sub-Saharan Africa, sustaining livelihoods, employment, and food security for over 60% of the population. However, regional agricultural value chains suffer from severe structural post-harvest inefficiencies:
- Fragmented market access and price information asymmetry between smallholders and commercial buyers.
- High post-harvest crop spoilage due to unmonitored storage conditions (temperature, humidity, ethylene/ammonia gas decay indicators).
- Financial transaction insecurity and freight logistics disconnects between unfamiliar trading partners.
- Information noise and generic/hallucinated advice when seeking agricultural extension guidance.

**AgroNexus** is engineered as an integrated, multi-platform agricultural management and information ecosystem combining Flutter cross-platform client interfaces, Spring Boot 3.x backend microservices, PostgreSQL with PostGIS & pgvector, embedded ESP32 IoT telemetry nodes, and a domain-guarded Retrieval-Augmented Generation (RAG) AI assistant.

---

## 2. Problem Statement

The post-harvest agricultural value chain in regional markets suffers from four primary structural breakdowns:
1. **Market Fragmentation & Spatial Isolation**: Smallholder producers lack direct, real-time access to regional buyers, leading to over-reliance on middlemen who exploit price information asymmetry.
2. **Post-Harvest Crop Spoilage & Environmental Neglect**: Lack of real-time storage telemetry (temperature, relative humidity, decay gas levels) causes large quantities of harvested produce to spoil before reaching buyers.
3. **Transaction Insecurity & Logistics Disconnect**: Direct digital trading between unfamiliar partners is hindered by trust deficits, payment default risks, and uncoordinated transportation dispatch.
4. **Information Noise & Ungrounded Guidance**: Agricultural actors seeking technical guidance on crop preservation and market standards receive generic or hallucinated online advice lacking authoritative backing.

---

## 3. Research Questions

- **RQ1**: How can a unified, multi-platform software architecture be designed to connect agricultural producers, buyers, transporters, agronomists, and system administrators within a single real-time ecosystem?
- **RQ2**: How can financial escrow mechanisms and spatial proximity indexing be structured to ensure transparent, risk-free marketplace transactions and optimized logistics matching?
- **RQ3**: How can IoT microcontrollers and environmental sensors be integrated to provide actionable, real-time storage condition telemetry for post-harvest loss mitigation?
- **RQ4**: How can a Retrieval-Augmented Generation (RAG) AI assistant be restricted through domain guardrails to deliver strictly authoritative, expert-verified agricultural advice?

---

## 4. Objectives of the Study

### 4.1 Main Objective
To design, develop, and evaluate AgroNexus, an integrated multi-platform agricultural management and information ecosystem unifying direct marketplace trading, secure escrow payments, logistics dispatching, cyber-physical storage telemetry, and domain-bounded AI decision support.

### 4.2 Specific Objectives
1. Model user workflows and system architecture encompassing six primary roles (`Farmer`, `Buyer`, `Transporter`, `Agronomist`, `Admin`, `System`).
2. Build a cross-platform client (Web, Mobile, Desktop) delivering responsive UI/UX for produce discovery, spatial radial filtering, order processing, and account management.
3. Engineer a robust microservices-ready backend API enforcing role-based access control (RBAC), token authentication, and strict financial escrow rules.
4. Integrate cyber-physical IoT hardware nodes (ESP32) for continuous environmental data collection and storage alert triggers.
5. Implement a domain-guarded RAG AI model vector-indexed with international agricultural standards (FAO, USDA, UNECE) to eliminate AI hallucinations and provide verified advisory assistance.

---

## 5. Scope & Delimitations

### Scope
- Multi-platform client implementation using Flutter (targeting Web, Mobile, and Desktop).
- RESTful backend services using Java Spring Boot 3.x and PostgreSQL with PostGIS + pgvector extensions.
- Implementation of 7 functional epics: Authentication/Identity, Distance-Filtered Catalog, Sales & Escrow Checkout, Transport Dispatch, Storage Conservation & IoT Telemetry, RAG AI Assistant, and User Self-Service Settings.
- Hardware simulation and embedded C++ integration using ESP32 nodes over MQTT/HTTP.

### Delimitations
- **Payments**: Financial payment integration simulates Mobile Money and card transactions via automated sandbox APIs rather than live bank settlement systems.
- **Hardware Deployment**: Hardware testing utilizes prototype sensor rigs (ESP32, DHT22, MQ-135) and simulated environmental chambers rather than industrial-scale commercial warehouses.
- **Jurisdiction**: Agricultural regulatory standards in the RAG knowledge base prioritize sub-Saharan Africa, FAO, USDA, and UNECE guidelines.
