-- Question 1

-- SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY';

SELECT COUNT(*)
FROM trips_clean;

-- Total number of trips in 2016: 3,916,401
-- Total number of trips in 2017: 4,666,765
SELECT YEAR(end_date) as trip_year, COUNT(*)
FROM trips
GROUP BY 1;

-- Total number of trips in 2016 broken down by month
SELECT MONTHNAME(end_date) as trip_year, COUNT(*)
FROM trips
WHERE YEAR(end_date) = 2016
GROUP BY 1;

-- Total number of trips in 2017 broken down by month
SELECT MONTHNAME(end_date) as trip_year, COUNT(*)
FROM trips
WHERE YEAR(end_date) = 2017
GROUP BY 1;

-- average number of trips a day for each month
SELECT trips_year, trips_month, ROUND(AVG(trips_count_per_day)) AS trips_avg_per_month
FROM
(
SELECT YEAR(end_date) as trips_year, MONTHNAME(end_date) as trips_month, DAY(end_date) as trips_day, COUNT(*) AS trips_count_per_day
FROM trips
GROUP BY 1,2,3
) as a
GROUP BY 1, 2;


-- Question 2

-- total number of trips of Members vs Non-members in 2017:
SELECT is_member, COUNT(*) AS number_of_members, COUNT(*)/(SELECT COUNT(*) FROM trips WHERE YEAR(end_date) = 2017) AS fraction_of_members
FROM trips
WHERE YEAR(end_date) = 2017
GROUP BY 1;

-- fraction of members per month for the year of 2017 broken down by month.
SELECT MONTHNAME(end_date),COUNT(*), SUM(is_member)/COUNT(*) as fraction_of_members
FROM trips
WHERE YEAR(end_date) = 2017
GROUP BY 1;


-- Question 4

-- There are many null values in the duration_sec column which I will remove in order to have cleaner data to work with. I will also remove 
-- any trips of 1 minute or less as I don't belive that the bike was actually used is such a short amount of time.
-- On the Bixi website they mention that they charge customers extra for using their bikes for more than 30 minuts. 
-- Thus I will remove all journeys that last longer than 30 minitues.


-- checking how many trips are above 30min
SELECT count(*) 
FROM trips
WHERE MINUTE(duration_sec) > 30;

-- for q6 I have added an extra colunm called round_trips in the trips data set.
ALTER TABLE trips
ADD COLUMN round_trip INTEGER
DEFAULT 0;

UPDATE trips
SET round_trip = 1
WHERE start_station_code = end_station_code;


-- I will create a View called trips_clean where the time spent biking is between 2 and 30 min.
DROP VIEW trips_clean;
CREATE VIEW trips_clean AS
SELECT id, start_date, end_date, start_station_code, end_station_code, round_trip, MINUTE(duration_sec) as duration_min, is_member
FROM trips
WHERE MINUTE(duration_sec) BETWEEN 2 AND 30 AND duration_sec IS NOT NULL;



-- Question 5

--  Average trip time by membership status: 7.34 for members and 10.68 for non-members;
SELECT is_member, AVG(duration_min) AS avg_trip_time
FROM trips_clean
GROUP BY 1;

--  Average trip time by month:
-- The shortest average times are in April, October & November whiles the longest is July. This is most probably due to the weather again.
SELECT MONTHNAME(end_date), AVG(duration_min) AS avg_trip_time
FROM trips_clean
GROUP BY 1;
 
-- Average trip time by day of the week:
-- longer on weekends that week days. Around 7.7 min on week days and 8.6 min on weekends
SELECT DAYOFWEEK(end_date), AVG(duration_min) AS avg_trip_time
FROM trips_clean
GROUP BY 1;


-- Average trip time by start station
-- Casino de Montréal has the longest average trip time with 14.77 min
-- Métro Georges-Vanier (St-Antoine / Canning) has the shortest trip on average with a time of 5.19 min
SELECT name, AVG(duration_min)
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name
ORDER BY 2 DESC;



-- Question 6

-- Fraction of Round Trips by membership status
-- 1.13% of members do round trips vs 3.53% of non members
SELECT is_member, (SUM(round_trip))/COUNT(*)
FROM trips_clean
GROUP BY 1;

-- Fraction of Round Trips by Day of the Week
-- Once again a lot more people do round trips on weekends 2.17% - 2.71% on weekends vs 1.22% - 1.47% on weekdays, 
-- with Monday to Thursday never going above 1.3% average
SELECT DAYOFWEEK(start_date), (SUM(round_trip))/COUNT(*)
FROM trips_clean
GROUP BY 1;



-- Question 8

-- 5 most popular starting stations
SELECT name, COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name
ORDER BY 2 DESC
LIMIT 5;

-- Question 9

-- 5 most poplar ending stations
SELECT name, COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.end_station_code = stations.code
GROUP BY name
ORDER BY 2 DESC
LIMIT 5;



-- Question 10

-- How is the number of Start and end stations distributed throughout the day?
-- Start stations distributions over the day
SELECT
CASE
        WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
        WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
        WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
        ELSE "night"
 END AS "time_of_day", 
 COUNT(*)/(SELECT COUNT(*) FROM trips_clean) AS distribution_time_of_day,
 COUNT(*) AS trips_at_this_time,
 (SELECT COUNT(*) FROM trips_clean) AS total_start_trips
 FROM trips_clean
 GROUP BY 1;
 
 
 -- End stations distributions over the day
SELECT 
CASE
        WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
        WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
        WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
        ELSE "night"
 END AS "time_of_day", COUNT(*)/(SELECT COUNT(*) FROM trips_clean) AS distribution_time_of_day,
 COUNT(*) AS trips_at_this_time,
 (SELECT COUNT(*) FROM trips_clean) 
 FROM trips_clean
 GROUP BY 1;
 
 
-- How is the number of Start and end stations distributed throughout the day for Mackay / de Maisonneuve?
-- to find the start_station_code
SELECT *
FROM stations
WHERE name LIKE '%Mackay%';

-- Mackay / de Maisonneuve distributions over the day as a start station
SELECT
CASE
        WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
        WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
        WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
        ELSE "night"
 END AS "time_of_day", COUNT(*)/(SELECT COUNT(*) FROM trips_clean WHERE start_station_code = 6100) AS distribution_time_of_day,
 COUNT(*) AS trips_at_this_time,
 (SELECT COUNT(*) FROM trips_clean WHERE start_station_code = 6100) 
 FROM trips_clean
 WHERE start_station_code = 6100
 GROUP BY 1;
 
-- Mackay / de Maisonneuve distributions over the day as an end station
SELECT
CASE
        WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
        WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
        WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
        ELSE "night"
 END AS "time_of_day", COUNT(*)/(SELECT COUNT(*) FROM trips_clean WHERE end_station_code = 6100) AS distribution_time_of_day,
 COUNT(*) AS trips_at_this_time,
 (SELECT COUNT(*) FROM trips_clean WHERE end_station_code = 6100) 
 FROM trips_clean
 WHERE end_station_code = 6100
 GROUP BY 1;

-- From the above finding's it it clear that there are more people using the bikes in the evening than in the morning. Where people have more 
-- time in the evening and are more relaxed. Also it is probably warmer in the afternoon and evenings.




-- Question 11

-- Which station has proportionally the least number of member trips?
-- remove all stations with less than 10 starting or ending stations

-- checks the number of start_stations. The smalles number of trips from a given place is 283. So no need to remove anything.
SELECT name, COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY 1
ORDER BY 2 ASC;


-- Once againg the number of trips to the end station is well above 10 at 406 so no need to remove any data.
SELECT name, COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.end_station_code = stations.code
GROUP BY 1
ORDER BY 2 ASC;


-- Asuming that there were trips with less than 10 trips, then we would need to remove then before doing the next task. To remove both 
-- starting and ending stations with less than 10 trips, we need to create a new view with only start and end stations with 10 trips or 
-- more 

-- create a view for all start station with 10 trips or more
DROP VIEW stations_start_10trips;
CREATE VIEW stations_start_10trips AS
SELECT name AS name_start, code AS code_start, COUNT(*) AS number_of_stations_start
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY 1, 2
HAVING COUNT(*) > 10;


-- create a view for end stations with 10 trips or more
DROP VIEW stations_end_10trips;
CREATE VIEW stations_end_10trips AS
SELECT name AS name_end, code AS code_end, COUNT(*) AS number_of_stations_end
FROM trips_clean
JOIN stations ON trips_clean.end_station_code = stations.code
GROUP BY 1, 2
HAVING COUNT(*) > 10;


-- create a view where you only have trips with more than 10 start trips and 10 end trips
DROP VIEW stations_10trips;
CREATE VIEW stations_10trips AS
SELECT name_start AS name, code_start AS code
FROM stations_start_10trips
JOIN stations_end_10trips 
ON stations_start_10trips.name_start = stations_end_10trips.name_end;

SELECT COUNT(*)
FROM stations_10trips;
-- As expected the stations_10trips has the same number of stations as our stations table, as all stations have more than 10 journies. 
-- Using the view 'stations_start_10trips takes future calculations much longer so we will stick with our stations table for now.



-- Starting station with the most trips is Mdu Mont-Royal with 92.23% of people starting from this station being members.
-- starting station with the less % of members starting at this station is 'Quai de la navette fluviale' with 25.15% (just changed DESC to ASC)

SELECT name, SUM(is_member)/COUNT(*) AS proportion_of_start_stations, SUM(is_member), COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name 
ORDER BY 2 ASC
LIMIT 5;


-- Which ending station has proportionally the most number of member trips?
-- Mdu Mont-Royal for most trips and Quai de la nette fluviale is in second place for less likely. So very similar results
SELECT name, SUM(is_member)/COUNT(*) AS proportion_of_end_stations, SUM(is_member), COUNT(*)
FROM trips_clean
JOIN stations ON trips_clean.end_station_code = stations.code
GROUP BY name 
ORDER BY 2 DESC
LIMIT 5;


-- Calculating the average proportionality over all places.
SELECT AVG(proportion_of_start_stations)
FROM
(
SELECT name, SUM(is_member)/COUNT(*) AS proportion_of_start_stations
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name 
ORDER BY 2 DESC
) AS x;




-- Question 12
--  List all stations for which at least 10% of trips starting from them are round trips

-- 12.1 -- counts the number of starting trips per station
SELECT name, COUNT(*) AS number_of_starting_trips
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name
ORDER BY 2 ASC; 


-- 12.2 -- counts for each station, the number of round trips
SELECT name, SUM(round_trip) AS number_of_round_trips
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
GROUP BY name
ORDER BY 2 DESC;


-- 12.3 -- Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station
SELECT name, SUM(round_trip)/COUNT(*) AS proportion_of_round_trip, SUM(round_trip) AS number_of_round_trips, COUNT(*) AS number_of_starting_trips
FROM trips_clean
JOIN stations ON trips_clean.start_station_code = stations.code
WHERE start_station_code = 6100
GROUP BY name
 -- HAVING SUM(round_trip)/COUNT(*) > 0.1
ORDER BY 2 ASC;






