# Rideau Canal Skateway — Real-time Monitoring System

**CST8916 Final Project** | Real-time ice condition monitoring for Ottawa's historic Rideau Canal Skateway, built on Azure.

---

## Student Information
- **Name:** Usama Iqbal
- **Student ID:** 040777763
- **Course:** CST8916 - Winter 2026

---

## System Architecture

```
IoT Sensors (Python Simulator)
        │  JSON every 10s
        ▼
  Azure IoT Hub
        │
        ▼
Azure Stream Analytics  ─── 5-min tumbling windows ───┐
        │                                              │
        ▼                                              ▼
 Azure Cosmos DB                              Azure Blob Storage
 (SensorAggregations)                         (historical-data)
        │
        ▼
  Web Dashboard
 (Azure App Service)
```

See `architecture/architecture-diagram.png` for the full diagram.

---

## Repositories

| Component | Repository |
|---|---|
| Sensor Simulation | [rideau-canal-sensor-simulation](https://github.com/uiqbal12/rideau-canal-sensor-simulation) |
| Web Dashboard | [rideau-canal-dashboard](https://github.com/uiqbal12/rideau-canal-dashboard) |
| This documentation | [rideau-canal-monitoring](https://github.com/uiqbal12/rideau-canal-monitoring) |

---

## How It Works

### 1. IoT Sensor Simulation
Three Python threads simulate sensor devices at Dow's Lake, Fifth Avenue, and NAC. Each thread sends a JSON payload to Azure IoT Hub every 10 seconds containing ice thickness, surface temperature, snow accumulation, and external temperature.

### 2. Stream Analytics Processing
Azure Stream Analytics ingests the IoT Hub stream and applies 5-minute tumbling windows grouped by location. For each window it calculates average, min, and max values for all sensor fields, a reading count, and a safety status (Safe / Caution / Unsafe) based on ice thickness and surface temperature thresholds. Results are written simultaneously to Cosmos DB (for dashboard queries) and Blob Storage (for historical archival).

### 3. Data Storage
Cosmos DB stores the latest aggregation windows in the `RideauCanalDB` database, `SensorAggregations` container, partitioned by `/location`. Blob Storage archives all raw IoT events as line-separated JSON files under `aggregations/{date}/{time}`.

### 4. Web Dashboard
A Node.js/Express server queries Cosmos DB and exposes two REST endpoints consumed by a vanilla JavaScript frontend. The dashboard displays three location cards with live safety badges, a system-wide status indicator, and Chart.js trend lines for ice thickness and surface temperature over the last hour. The page auto-refreshes every 30 seconds.

---

## Safety Status Logic

| Status | Condition |
|---|---|
| **Safe** | Avg ice ≥ 30 cm AND avg surface temp ≤ −2 °C |
| **Caution** | Avg ice ≥ 25 cm AND avg surface temp ≤ 0 °C |
| **Unsafe** | All other conditions |

---

## Azure Services Used

| Service | Purpose | Tier Used |
|---|---|---|
| IoT Hub | Device-to-cloud message ingestion | Free (F1) |
| Stream Analytics | Real-time windowed aggregations | Standard S1 |
| Cosmos DB | Low-latency NoSQL storage for dashboard | Serverless |
| Blob Storage | Historical data archival | LRS Standard |
| App Service | Web dashboard hosting | Free (F1) |

---

## Screenshots

| # | Description |
|---|---|
| [01-iot-hub-devices.png](screenshots/01-iot-hub-devices.png) | IoT Hub — three registered devices |
| [02-iot-hub-metrics.png](screenshots/02-iot-hub-metrics.png) | IoT Hub — incoming messages metrics |
| [03-stream-analytics-query.png](screenshots/03-stream-analytics-query.png) | Stream Analytics — SQL query |
| [04-stream-analytics-running.png](screenshots/04-stream-analytics-running.png) | Stream Analytics — job running |
| [05-cosmos-db-data.png](screenshots/05-cosmos-db-data.png) | Cosmos DB — aggregation documents |
| [06-blob-storage-files.png](screenshots/06-blob-storage-files.png) | Blob Storage — archived JSON files |
| [07-dashboard-local.png](screenshots/07-dashboard-local.png) | Dashboard running locally |
| [08-dashboard-azure.png](screenshots/08-dashboard-azure.png) | Dashboard deployed on Azure |

---

## Stream Analytics Query

See [`stream-analytics/query.sql`](stream-analytics/query.sql) for the full query.

---


## AI Tools Disclosure

Claude tool was used for code generation and code understanding throughout different components as needed. 

## Running the Project

### Step 1 — Start the sensor simulator
```bash
cd rideau-canal-sensor-simulation
pip install -r requirements.txt
cp .env.example .env   # add IoT Hub connection strings
python sensor_simulator.py
```

### Step 2 — Start the dashboard locally
```bash
cd rideau-canal-dashboard
npm install
cp .env.example .env   # add Cosmos DB connection string
npm start
# open http://localhost:3000
```
