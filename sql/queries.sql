-- ============================================================
-- Uber Trip Analysis — key SQL queries (SQLite)
-- Dataset: 20,000 trips, 6 cities, 2024–2025
-- ============================================================

-- 1. Network KPIs
SELECT SUM(CASE WHEN status='Completed' THEN 1 ELSE 0 END) completed_trips,
       COUNT(*) total_trips,
       SUM(fare) revenue,
       ROUND(AVG(CASE WHEN status='Completed' THEN fare END),0) avg_fare,
       ROUND(AVG(CASE WHEN status='Completed' THEN distance_km END),1) avg_distance,
       ROUND(100.0*SUM(CASE WHEN status!='Completed' THEN 1 ELSE 0 END)/COUNT(*),1) cancel_rate,
       ROUND(AVG(CASE WHEN status='Completed' THEN driver_rating END),2) avg_rating
FROM trips;

-- 2. Demand & revenue by hour of day (the demand curve)
SELECT hour, COUNT(*) trips,
       SUM(CASE WHEN status='Completed' THEN fare ELSE 0 END) revenue,
       ROUND(AVG(surge_multiplier),2) avg_surge,
       ROUND(100.0*SUM(CASE WHEN status!='Completed' THEN 1 ELSE 0 END)/COUNT(*),1) cancel_rate
FROM trips GROUP BY hour ORDER BY hour;

-- 3. Peak vs off-peak cancellation comparison
SELECT CASE WHEN hour IN (8,9,18,19) THEN 'Peak' ELSE 'Off-peak' END AS period,
       COUNT(*) trips,
       ROUND(100.0*SUM(CASE WHEN status!='Completed' THEN 1 ELSE 0 END)/COUNT(*),1) cancel_rate,
       ROUND(AVG(CASE WHEN status='Completed' THEN fare END),0) avg_fare
FROM trips GROUP BY period;

-- 4. Vehicle economics
SELECT vehicle_type, COUNT(*) trips, SUM(fare) revenue,
       ROUND(AVG(CASE WHEN status='Completed' THEN fare END),0) avg_fare,
       ROUND(AVG(CASE WHEN status='Completed' THEN distance_km END),1) avg_km,
       ROUND(AVG(CASE WHEN status='Completed' THEN driver_rating END),2) avg_rating
FROM trips GROUP BY vehicle_type ORDER BY revenue DESC;

-- 5. Surge pricing impact
SELECT CASE WHEN surge_multiplier > 1 THEN 'Surged' ELSE 'Normal' END AS grp,
       COUNT(*) trips,
       ROUND(AVG(CASE WHEN status='Completed' THEN fare END),0) avg_fare,
       ROUND(100.0*SUM(CASE WHEN status!='Completed' THEN 1 ELSE 0 END)/COUNT(*),1) cancel_rate
FROM trips GROUP BY grp;

-- 6. City performance
SELECT city, COUNT(*) trips, SUM(fare) revenue,
       ROUND(100.0*SUM(CASE WHEN status!='Completed' THEN 1 ELSE 0 END)/COUNT(*),1) cancel_rate
FROM trips GROUP BY city ORDER BY revenue DESC;

-- 7. Monthly revenue trend
SELECT substr(date,1,7) AS ym, COUNT(*) trips, SUM(fare) revenue
FROM trips WHERE status='Completed' GROUP BY ym ORDER BY ym;

-- 8. Cancellation funnel: who cancels, driver or rider?
SELECT status, COUNT(*) trips,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM trips),1) share_pct
FROM trips GROUP BY status;

-- 9. Payment preference among completed trips
SELECT payment, COUNT(*) trips, SUM(fare) revenue,
       ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM trips WHERE status='Completed'),1) share_pct
FROM trips WHERE status='Completed' GROUP BY payment;

-- 10. Wait-time impact on rating (service quality check)
SELECT CASE WHEN wait_time_min <= 2 THEN '0-2 min'
            WHEN wait_time_min <= 5 THEN '3-5 min'
            ELSE '6+ min' END AS wait_band,
       COUNT(*) trips,
       ROUND(AVG(driver_rating),2) avg_rating
FROM trips WHERE status='Completed' GROUP BY wait_band;
