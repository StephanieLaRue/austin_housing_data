-- insert existing zpids to records with missing values
UPDATE austin_housing
SET zpid = 29473281
WHERE Address = '2206 S 3Rd St, Austin, 78704';

UPDATE austin_housing
SET zpid = 29392029
WHERE Address = '2000 Chestnut Ave, Austin, 78722';

UPDATE austin_housing
SET zpid = 29390174
WHERE Address = '3110 E 12Th St, Austin, 78702';

-- separate address column into street, city, and zip
ALTER TABLE austin_housing
ADD Street VARCHAR(255), City VARCHAR(255), Zip INT;

DECLARE @city_zip varchar(255);
UPDATE austin_housing
    SET @city_zip = SUBSTRING(Address,CHARINDEX(',', Address)+2,CHARINDEX(',', Address)),
	Street = SUBSTRING(Address,1,CHARINDEX(',', Address)-1),
	City = SUBSTRING(@city_zip,1,CHARINDEX(',',@city_zip)-1),
	Zip = SUBSTRING(@city_zip,CHARINDEX(',',@city_zip)+1,LEN(@city_zip));

-- clean up latest sale dates
UPDATE austin_housing
SET latest_saledate = CAST(latest_saledate as Date);

-- separate latest sale date year into a separate column
ALTER TABLE austin_housing
ADD latest_saledate_year INT;

UPDATE austin_housing
	SET latest_saledate_year = YEAR(latest_saledate);

-- remove empty columns
ALTER TABLE austin_housing
DROP COLUMN numOfStudents, numOfTeachers;

-- latestpricesource to N/A when missing value
UPDATE austin_housing
	SET latestpricesource =
    CASE 
		WHEN latestpricesource IS NULL THEN 'N/A'
        ELSE latestpricesource
	END;

-- update missing values in hasgarage field based on number of garage spaces 
UPDATE austin_housing
	SET hasGarage = 
    CASE 
		WHEN hasGarage IS NULL AND garageSpaces > 0 THEN 'TRUE'
        ELSE 'FALSE'
	END
WHERE hasGarage IS NULL;

-- remove duplicates with same addresses
WITH cte AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY 
		Address
	ORDER BY Zpid
	) row_nums
FROM austin_housing
)
DELETE 
FROM cte
WHERE row_nums > 1;