-- Exploratory Data Analysis with World Layoffs

SELECT * FROM layoffs_staging2;

-- Find the date range for the entire dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
/* March 11th, 2020 until March 6th, 2023*/

-- Search for company with the max layoffs
SELECT company, total_laid_off
FROM layoffs_staging2
WHERE total_laid_off = (SELECT MAX(total_laid_off) FROM layoffs_staging2);
/* Google had the max amount of layoffs totaling 12,000! */

-- Search for companies that shutdown entirely
SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1;
/* 116 Companies shutdown according to our dataset. */

-- Search for the company that shutdown and had the most layoffs
SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1
AND total_laid_off = 
(SELECT MAX(total_laid_off) FROM layoffs_staging2
WHERE percentage_laid_off = 1);
/* Katerra went under, laying off 2,434 employees!*/

-- Find the company with the most raised funds that shutdown 
SELECT company, funds_raised_millions, total_laid_off, percentage_laid_off, `date`, location
FROM layoffs_staging2
WHERE percentage_laid_off = 1
AND funds_raised_millions = 
(SELECT MAX(funds_raised_millions) FROM layoffs_staging2
WHERE percentage_laid_off = 1);
/* BritishVolt had 2.6 Billion Dollars in funding, but went under. */

-- Group total layoffs with each company in the dataset
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
/* Displaying all companies with their total layoffs over the years. */

-- What were the total layoffs based on industry in Descending Order?
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
/* Consumer with 45,812 being the most, and Manufacturing with 20 being the least */

-- Which Country had the most layoffs?
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
/* US with 256,559 layoffs */

-- Search for each year's total layoffs
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
/* 2023 (up til March 6th) - 125,677 layoffs
   2022 - 160,661 layoffs
   2021 - 15,823 layoffs
   2020 (Since March 11th) - 80,998 layoffs */
   
-- Find the Average percentage of layoffs based on industries
SELECT industry, ROUND(AVG(percentage_laid_off), 2) AS Percent_laid_off_AVG
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
/* Aerospace laid off, on average, 57% being the largest */

-- Search for layoffs for each month throughout 2020 - 2023
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY SUBSTRING(`date`, 1, 7)
ORDER BY `MONTH` ASC;
/* Displaying each of of each year of the total layoffs*/

-- Display the Rolling Total for layoffs monthly
WITH Rolling_Total AS 
(
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS Total_Laid_Off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY SUBSTRING(`date`, 1, 7)
ORDER BY `MONTH` ASC
)
SELECT `MONTH`, Total_Laid_Off, SUM(Total_Laid_Off) OVER(ORDER BY `MONTH`) AS Rolling_Total
FROM Rolling_Total;
/* Displays the Rolling Total Monthly */

-- Rank top 5 Companies by the total laid off by each year.
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
)
SELECT * FROM Company_Year_Rank
WHERE Ranking <= 5;
/* Shows Top 5 Companies that laid off the most each year. */

-- Rank the Locationas with the most Layoffs, over the years, based in the United States
WITH US_Locations_LO (US_City, `Year`, Yearly_Lay_Off) AS
(
SELECT location, YEAR(`date`) AS `Year`,  SUM(total_laid_off) AS Yearly_Lay_Off
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
AND country LIKE 'United States%'
GROUP BY location, YEAR(`date`)
)
SELECT *, 
DENSE_RANK() OVER(PARTITION BY `Year` ORDER BY Yearly_Lay_Off DESC) AS Ranking 
FROM US_Locations_LO;
