/*
Covid 19 Data Exploration 
Skills: Joins, CTE, Temp Table, Creating Views, Aggregate functions, Windows functions
*/

/******* EXPLORE DATA AT THE COUNTRY LEVEL *******/
-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if a person contract covid in each country.
SELECT 
    location, 
    date,
    total_cases, 
    new_cases,
    total_deaths,
    population,
    (total_deaths / total_cases) * 100 AS case_death_ratio
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL
ORDER BY location, date


-- Total Cases vs Population
SELECT 
    location, 
    date,
    new_cases,
    total_deaths,
    total_cases, 
    population,
    (total_cases / population) * 100 AS infection_per_capita
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL
ORDER BY location, date


-- Countries with the highest infection rate compare to its population
SELECT
    location,
    population,
    MAX(total_cases) as higest_infection_count,
    MAX(total_cases / population) * 100 AS highest_infection_rate
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Coutries with the highest death rate compare to its population
SELECT
    location,
    population,
    MAX(total_deaths) AS highest_death_count,
    MAX(total_deaths / population) * 100 AS highest_death_rate
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


/******* EXPLORE DATA AT THE CONTINENT LEVEL *******/
-- Highest infection and death rate per continent
SELECT
    location AS continent,
    population,
    MAX(total_cases) AS highest_case_count,
    MAX(total_deaths) AS highest_death_count,
    MAX(total_cases/population) AS highest_infection_rate,
    MAX(total_deaths/population) AS highest_death_rate
FROM Portfolio.dbo.death
WHERE continent IS NULL AND location IN ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America')
GROUP BY location, population
ORDER BY 6 DESC

-- Another way to get the highest infection and death rate per continent
WITH continent_population AS (
    SELECT DISTINCT location, population
    FROM Portfolio.dbo.death
    WHERE continent IS NULL AND location IN ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America') 
)
SELECT
    d.continent,
    c.population AS total_pop_cont,
    SUM(total_cases) AS total_cases_cont,
    SUM(total_deaths) AS total_deaths_cont,
    SUM(total_cases)/c.population AS highest_infection_rate,
    SUM(total_deaths)/c.population AS highest_death_rate
FROM Portfolio.dbo.death d JOIN continent_population c 
    ON d.continent = c.[location]
WHERE d.continent IS NOT NULL AND DATE = '2022-04-17'
GROUP BY d.continent, c.population
ORDER BY 6


-- Create a temp table that shows continent population
DROP TABLE IF EXISTS #continent_population
CREATE TABLE #continent_population (
    continent_name NVARCHAR(255),
    population NUMERIC
)
INSERT INTO #continent_population
SELECT DISTINCT location, population
FROM Portfolio.dbo.death
WHERE continent IS NULL AND location IN ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America') 

SELECT *
FROM #continent_population



/******* EXPLORE DATA AT THE GLOBAL LEVEL *******/
SELECT
    total_cases,
    total_deaths,
    total_deaths/total_cases AS deaths_per_cases
FROM Portfolio.dbo.death
WHERE continent IS NULL AND [location] LIKE '%World' AND date='2022-04-17'

--OR--

SELECT
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths)/SUM(new_cases)) * 100 AS death_per_cases
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL



/******* EXPLORE VACCINATION DATA *******/
-- Windows function: rolling up new vaccinations to count the total vaccinations
SELECT
    continent,
    location,
    date,
    new_vaccinations,
    total_vaccinations,
    SUM(new_vaccinations) OVER(PARTITION BY location ORDER BY date) AS total_vaccination_by_day
FROM Portfolio.dbo.vaccination
WHERE continent IS NOT NULL
ORDER BY 1, 2, 3
/*
Personal note: In theory, rolling up all numbers in the new_vaccinations column should match with the final number in the total_vaccinations column, but it does not match, because there are missing records in the new vaccinations column.
The missing data should be handled if we want to use the new vaccinations to get the total vaccinations. 
After checking the raw data, we can confirm that the number in the total_vaccinations column is correct as it mattched withthe sum of the total people_vaccinated and peopel_fully_vaccinated.
*/


-- Vaccinations per capita and the death rate
SELECT
    v.continent,
    v.location, 
    d.population,
    v.gdp_per_capita,
    MAX(d.total_cases) AS total_cases,
    MAX(d.total_deaths) AS total_deaths,
    MAX(v.total_vaccinations) AS total_vaccination,
    MAX(v.total_vaccinations / d.population) AS vaccinations_per_capita,
    MAX(d.total_deaths / d.population) * 100 AS death_rate
FROM Portfolio.dbo.vaccination v JOIN Portfolio.dbo.death d
    ON v.location = d.location AND v.date = d.date
WHERE v.continent IS NOT NULL
GROUP BY v.continent, v.location, d.population, v.gdp_per_capita
ORDER BY 9 DESC



-- Create Views
-- View of basic info related to Covid
CREATE VIEW basic_convid_v AS
SELECT
    v.continent,
    v.location, 
    v.date, 
    d.population,
    v.population_density,
    d.total_cases,
    d.new_cases,
    d.total_deaths,
    d.new_deaths,
    v.total_vaccinations,
    v.total_boosters,
    v.people_vaccinated,
    v.people_fully_vaccinated,
    v.gdp_per_capita,
    v.hospital_beds_per_thousand

FROM Portfolio.dbo.vaccination v JOIN Portfolio.dbo.death d
    ON v.location = d.location AND v.date = d.date
WHERE v.continent IS NOT NULL


-- View of Case and Death Rate Per Capita (country level)
CREATE VIEW case_death_country_v AS
SELECT 
    location, 
    date,
    total_cases, 
    new_cases,
    total_deaths,
    population,
    (total_deaths / total_cases) * 100 AS case_death_ratio
FROM Portfolio.dbo.death
WHERE continent IS NOT NULL



-- View of Case and Death Rate Per Capita (continent level)
CREATE VIEW case_death_continent_v AS
WITH continent_population AS (
    SELECT DISTINCT location, population
    FROM Portfolio.dbo.death
    WHERE continent IS NULL AND location IN ('Africa', 'Asia', 'Europe', 'North America', 'Oceania', 'South America') 
)
SELECT
    d.continent,
    c.population AS total_pop_cont,
    SUM(total_cases) AS total_cases_cont,
    SUM(total_deaths) AS total_deaths_cont,
    SUM(total_cases)/c.population AS highest_infection_rate,
    SUM(total_deaths)/c.population AS highest_death_rate
FROM Portfolio.dbo.death d JOIN continent_population c 
    ON d.continent = c.[location]
WHERE d.continent IS NOT NULL AND DATE = '2022-04-17'
GROUP BY d.continent, c.population



-- View of Vaccination Per Capita
CREATE VIEW vaccination_per_capita AS
SELECT
    v.continent,
    v.location, 
    d.population,
    v.gdp_per_capita,
    MAX(d.total_cases) AS total_cases,
    MAX(d.total_deaths) AS total_deaths,
    MAX(v.total_vaccinations) AS total_vaccination,
    MAX(v.total_vaccinations / d.population) AS vaccinations_per_capita,
    MAX(d.total_deaths / d.population) * 100 AS death_rate
FROM Portfolio.dbo.vaccination v JOIN Portfolio.dbo.death d
    ON v.location = d.location AND v.date = d.date
WHERE v.continent IS NOT NULL
GROUP BY v.continent, v.location, d.population, v.gdp_per_capita
