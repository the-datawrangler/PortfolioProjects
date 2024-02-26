--check table column data type
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CovidDeaths' 
AND COLUMN_NAME = 'total_cases';

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Select Data that will be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths(cast converts the data type of the two columns into floats from nvarchar)
--(CONVERT() can also be used for the same only difference being the data type to be converted into starts in the brackets)
-- Shows the percentage likelihood of dying in Kenya if you contracted Covid
SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
Where location = 'Kenya'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of the population in Kenya got Covid
SELECT location, date, total_cases, population, (cast(total_cases as float)/population)*100 CovidInfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Kenya' --(think of how to visualize the data including every country in tableau in the future)
ORDER BY 1,2


-- Looking at countries with highest infection rate compared to populattion
-- use the cast on the MAX aggregate as well to get the accurate result
SELECT location, population, MAX(cast(total_cases as float)) HighestInfectedCount, MAX((cast(total_cases as float)/population))*100 PopulationPercentageInfected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'Andorra' 
GROUP BY location, population
ORDER BY PopulationPercentageInfected DESC

--Showing countries with Highest Death Count per population

SELECT location, MAX(cast(total_deaths as int)) TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --To show only countries without the grouping of the countries as in the data
GROUP BY location
ORDER BY TotalDeathCount DESC

--Showing continents with Highest Death Count per population

SELECT location, MAX(cast(total_deaths as int)) TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL --To show only countries without the grouping of the countries as in the data
GROUP BY location
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT SUM(new_cases) total_cases, SUM(cast(new_deaths as int)) total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3


----Using CTE(to use the RollingVaccinations and get % rolling vaccinations)

WITH PopvsVac (Continent, location, Date, Population, New_vaccinations, RollingVaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) RollingVaccinations --(RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3
)
Select *, (RollingVaccinations/population)*100
From PopvsVac


----Same example using Temp Table

DROP Table if exists #PercentPopVaccinated --Its best to add this drop table if you plan to make any alterations to the temp table to prevent any errors
Create Table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinations numeric
)



Insert into #PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) RollingVaccinations --(RollingVaccinations/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3

Select *, (RollingVaccinations/population)*100
From #PercentPopVaccinated

-- Creating View to store data for later visualizations(You can create multiple views for later visualizations)

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) RollingVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2,3

Select *
From PercentPopulationVaccinated