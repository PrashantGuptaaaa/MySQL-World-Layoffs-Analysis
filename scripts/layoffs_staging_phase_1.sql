-- Data Cleaning

/*Query 1 to see all data was imported correctly */
SELECT * FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data (Spelling Errors, Configure Data Correctly)
-- 3. Look at Null/Blank Values
-- 4. Remove Any Columns when Necessary

-- Create Table that will manipulate the raw data without affecting the raw dataset
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Verifying the columns matched and to see if data was transferred over
SELECT * FROM layoffs_staging;

-- Duplicating the data from layoffs to
-- layoffs_staging
INSERT layoffs_staging
SELECT * FROM layoffs;

-- Created another column "row_num", where if > 1, then there are duplicates
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Creating a CTE (Common Table Expression)
-- We use the CTE as way to filter those Rows of data containing more than 1 data entry of the same company
WITH duplicate_cte AS
(
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

/* Then we will query every Company that resulted based upon our filter
   from the CTE we created
   we will use a simple query to extract all info contained for those specific
   companies that were resulted from the CTE with the filter.
   
   SELECT * FROM layoffs_staging
   WHERE company = "X_company";
   
   To verify those data entries being duplicated or not.
*/
SELECT * FROM layoffs_staging
WHERE company = 'Cazoo';

/* Now we will create another Table "layoffs_staging2" where it is
   the exact same, but you will also add the row_num into the table,
   making it easier to delete the duplicates from earlier.
   We are going to copy "layoffs_staging by right-clicking the table
   and then clicking to copy the clipboard and clicking create statement
*/
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verifying that the new table worked
SELECT * FROM layoffs_staging2;

-- Inserting data from layoffs_staging and adding a new column "row_num"
INSERT INTO layoffs_staging2
SELECT * ,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Verify that row_num is working properly in new table
SELECT * FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicates
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- ------------------------------------------------------------------------------------ DUPLICATE DELETE DONE ----------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------- START TO STANDARDIZE DATA -----------------------------------------------------------------------------------

-- We want to structure/standardize the data
-- Here you can see that some companies are entered with a space at the beginning
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Now we will update the table to get rid of those spaces
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Verify Update TRIM
SELECT company
FROM layoffs_staging2
ORDER BY 1;

-- Looking at Industry to see if any errors were inputted in this column
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- Looking at Crypto Specific indutry to see how other companies formatted in dataset
-- Which ever Crypto written standard is most populated will be standard in this table
SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Now updating Table where Crypto Companies are now labeled correctly
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Verify Crypto Label
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- Looking at Countries to view errors, 'United States' and 'United States.'
SELECT DISTINCT (country)
FROM layoffs_staging2
ORDER BY 1;

-- Updating label for country United States
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Observing Date column and converting it from STR to Date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') AS New_Date
FROM layoffs_staging2;

-- Updating date to corrected format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Verifying date column is now formatted properly
SELECT `date` FROM layoffs_staging2;

-- Altering table so the format of date column is fixed in table
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verifying Date column is working in Dataset
SELECT * FROM layoffs_staging2;

-- ------------------------------------------------------------------------------------ STANDARDIZE DELETE DONE ----------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------- START TO CLEAR NULLS/BLANKS ----------------------------------------------------------------------------------

-- FINDING NULLS in column total_laid_off
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL;

-- Finding companies where their Industry where is Null/Blank
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Verify if company had industry labeled before
SELECT * FROM layoffs_staging2
WHERE company = 'Juul';

-- Creating a Join on the table itself to see if industry is filled
SELECT * FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Creating a Join on the table itself to see if industry is filled
SELECT t1.company, t1.industry, t2.company, t2.industry 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Converting Blank industry to Nulls
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Add Industry to appropriate company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- ------------------------------------------------------------------------------------ NULLS/BLANKS DONE ----------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------- NOW DELETE ENTRIES/ROWS --- ----------------------------------------------------------------------------------

-- Finding data entries where both total and percent laid off is blank/null
SELECT * FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- Delete Rows where both the total and percent laid off is null/blank
DELETE
FROM layoffs_staging2
WHERE (total_laid_off IS NULL OR total_laid_off = '')
AND (percentage_laid_off IS NULL OR percentage_laid_off = '');

-- Checking if all data entries are now Valid
SELECT * FROM layoffs_staging2;

-- Drop row_num column from Table
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Finished Check everything
SELECT * FROM layoffs_staging2;