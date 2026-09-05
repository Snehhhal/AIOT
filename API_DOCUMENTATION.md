# PoleGuard — RESTful API Specification (v1)

Base URL: `http://127.0.0.1:8000/api/v1`  
Interactive Swagger Documentation: `http://127.0.0.1:8000/docs`  
Alternative ReDoc Documentation: `http://127.0.0.1:8000/redoc`

---

## 1. Authentication & Account Management (`/auth`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/auth/register` | No | Registers new user. Staff roles require `staff_auth_code`. |
| `POST` | `/auth/login` | No | Authenticates user; returns JWT Bearer access token. |
| `GET` | `/auth/me` | Bearer Token | Returns current authenticated user profile. |
| `POST` | `/auth/forgot-password` | No | Generates 6-digit password reset token. |
| `POST` | `/auth/reset-password` | No | Verifies token and updates user password in database. |

---

## 2. Utility Poles & GPS Discovery (`/poles`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/poles` | No | Lists all registered utility poles. |
| `GET` | `/poles/nearby` | No | Calculates Haversine distance from `latitude`/`longitude`; returns poles sorted by proximity. |
| `GET` | `/poles/{pole_id}` | No | Returns detailed pole metadata and current telemetry. |
| `GET` | `/poles/{pole_id}/history` | No | Returns 24-hour historical sensor telemetry points for trend charts. |
| `GET` | `/poles/{pole_id}/health-risk` | No | Returns composite health score and CRI risk rating. |
| `POST` | `/poles` | Admin | Registers a new utility pole in the database. |

---

## 3. Photo Uploads (`/uploads`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/uploads/image` | Optional | Multipart form-data image upload (JPEG/PNG/WebP, $\le 10$MB). Returns static URL `/uploads/{filename}`. |

---

## 4. Hazard Reports (`/hazard-reports`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/hazard-reports` | Optional | Submits citizen report with location, pole ID, description, and photo URL. |
| `GET` | `/hazard-reports` | No | Lists submitted reports with optional `status` and `pole_id` filters. |
| `GET` | `/hazard-reports/{id}` | No | Retrieves report details, timeline, and photo URL. |
| `PATCH` | `/hazard-reports/{id}/status`| Staff | Updates report lifecycle (`UNDER_REVIEW`, `VERIFIED`, `IN_PROGRESS`, `RESOLVED`). |
| `POST` | `/hazard-reports/{id}/assign`| Engineer/Admin | Assigns report to a field technician. |

---

## 5. Incidents & Work Orders (`/incidents`, `/work-orders`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/incidents` | No | Lists operational incidents with optional `status` and `severity` filters. |
| `GET` | `/incidents/escalations` | Authority/Admin| Lists unresolved CRITICAL/EMERGENCY incidents exceeding SLA. |
| `POST` | `/incidents/{id}/acknowledge`| Technician/Admin | Acknowledges receipt of dispatched incident. |
| `POST` | `/incidents/{id}/status` | Technician/Admin | Updates status (`IN_PROGRESS`, `RESOLVED`) and appends field notes. |
| `POST` | `/incidents/{id}/assign` | Engineer/Admin | Dispatches incident to a technician and generates tracked work order. |
| `GET` | `/work-orders` | No | Lists maintenance work orders. |
| `POST` | `/authority/grid-cutoff` | Authority/Admin| Executes emergency remote power grid isolation for a hazardous pole. |

---

## 6. Safety Assistant (`/assistant`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/assistant/chat` | No | Queries ChromaDB RAG vector store for safety guidance (CEA 2010 regulations). |

---

## 7. Admin Control & System Audit (`/admin`)

| Method | Path | Auth Required | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/admin/users` | Admin | Lists all platform users, roles, and active status. |
| `POST` | `/admin/users/{id}/toggle-active`| Admin | Enables or disables login access for a target user. |
| `GET` | `/admin/audit-logs` | Admin | Retrieves security and operational audit trail. |
| `GET` | `/admin/system-config` | Admin | Returns system configuration and safety thresholds. |
