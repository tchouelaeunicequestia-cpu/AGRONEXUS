# AgroNexus Documentation Hub

Welcome to the official documentation repository for **AgroNexus: An Integrated Agricultural Management and Information Platform**.

AgroNexus is a comprehensive AgTech ecosystem designed to address post-harvest agricultural value chain inefficiencies in Central Africa and broader regional markets. The platform combines spatial e-commerce, automated escrow payments, cyber-physical IoT telemetry for storage monitoring, verified agronomy advisory, and domain-guarded Retrieval-Augmented Generation (RAG) AI grounded in international agricultural standards (FAO, USDA, UNECE).

---

## 📚 Documentation Index

| File | Description |
| :--- | :--- |
| 📄 [PROJECT_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/PROJECT_SPECIFICATION.md) | Project background, problem statement, research questions, objectives, scope & delimitations. |
| 🏗️ [SYSTEM_ARCHITECTURE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/SYSTEM_ARCHITECTURE.md) | Architectural layers, UML use cases, data flow diagrams (DFD Level-1), component models, and RBAC authorization matrix. |
| 📋 [REQUIREMENTS.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/REQUIREMENTS.md) | Functional epics (Epics 1–7), Non-Functional Requirements (NFR1–NFR4), and Requirements Traceability Matrix. |
| 🗄️ [DATABASE_SCHEMA.sql](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/DATABASE_SCHEMA.sql) | Production SQL database schema including PostGIS spatial coordinates (`GEOMETRY(Point, 4326)`), pgvector (`vector(1536)`), GiST/HNSW indexes, and constraints. |
| 🔌 [IOT_HARDWARE_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/IOT_HARDWARE_SPECIFICATION.md) | ESP32 cyber-physical hardware setup, sensor pinouts (DHT22, MQ-135), C++ firmware implementation, and telemetry payload formats. |
| 🤖 [RAG_AI_PIPELINE.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/RAG_AI_PIPELINE.md) | Domain-guarded RAG AI pipeline, vector embedding ingestion, HNSW cosine search, guardrail execution flow, and FAO/USDA citation rules. |
| 🌐 [API_SPECIFICATION.md](file:///c:/Users/lenovo%20p14s/Music/AGRONEXUS/docs/API_SPECIFICATION.md) | Complete REST API endpoints specification, JWT authentication flow, escrow state machine transitions, and DTO contracts. |

---

## 👥 Project Information

- **Project Title**: AgroNexus — An Integrated Agricultural Management and Information Platform
- **Institution**: The ICT University, Yaoundé Campus, Cameroon
- **Department**: Software Engineering and Artificial Intelligence
- **Degree**: Bachelor of Science (B.Sc.) in Software Engineering and Artificial Intelligence
- **Author**: Eunice Françoise Tchouela Quetsia (Registration No: ICTU20248912)
- **Degree Level & Group**: Level 2, Group 2
- **Academic Year**: August 2026
