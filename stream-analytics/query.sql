-- ─────────────────────────────────────────────────────────────────────────────
-- Rideau Canal Skateway — Stream Analytics Query
-- Input alias:  iothub-input  (your IoT Hub)
-- Output alias: cosmos-output (Cosmos DB → SensorAggregations)
-- Output alias: blob-output   (Blob Storage → historical-data)
-- ─────────────────────────────────────────────────────────────────────────────

-- Output 1: Aggregated 5-minute windows → Cosmos DB
SELECT
    location,
    System.Timestamp()                          AS windowEnd,
    AVG(iceThickness)                           AS avgIceThickness,
    MIN(iceThickness)                           AS minIceThickness,
    MAX(iceThickness)                           AS maxIceThickness,
    AVG(surfaceTemperature)                     AS avgSurfaceTemp,
    MIN(surfaceTemperature)                     AS minSurfaceTemp,
    MAX(surfaceTemperature)                     AS maxSurfaceTemp,
    MAX(snowAccumulation)                       AS maxSnowAccumulation,
    AVG(externalTemperature)                    AS avgExternalTemp,
    COUNT(*)                                    AS readingCount,
    CASE
        WHEN AVG(iceThickness) >= 30 AND AVG(surfaceTemperature) <= -2 THEN 'Safe'
        WHEN AVG(iceThickness) >= 25 AND AVG(surfaceTemperature) <=  0 THEN 'Caution'
        ELSE 'Unsafe'
    END                                         AS safetyStatus,
    CONCAT(
        location, '-',
        CAST(System.Timestamp() AS nvarchar(max))
    )                                           AS id
INTO   [cosmos-output]
FROM   [iothub-input] TIMESTAMP BY timestamp
GROUP BY
    location,
    TumblingWindow(minute, 5)

-- Output 2: Raw events → Blob Storage (historical archive)
SELECT
    location,
    timestamp,
    iceThickness,
    surfaceTemperature,
    snowAccumulation,
    externalTemperature
INTO   [blob-output]
FROM   [iothub-input] TIMESTAMP BY timestamp