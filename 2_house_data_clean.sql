/*
Cleaning Data in SQL Queries
Data: pj2_house_data.csv
*/
--------------------------------------------------------------------------------------------------------------------------
-- Update Column Names
sp_rename 'house_data.Date_of_Sale_dd_mm_yyyy', 'SaleDate', 'COLUMN';
sp_rename 'house_data.Description_of_Property', 'Descriptions', 'COLUMN';

--------------------------------------------------------------------------------------------------------------------------
-- Change the data type of SaleDate from String to Date and store it to SaleDateClean
ALTER TABLE house_data
ADD SaleDateClean Date

Update house_data
SET SaleDateClean = CONVERT(DATE, CONCAT(SUBSTRING(SaleDate, 7, 4), '-', SUBSTRING(SaleDate, 4, 2), '-', LEFT(SaleDate, 2)))

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
ALTER TABLE house_data
ADD AddressSplit1 NVARCHAR(255), AddressSplit2 NVARCHAR(255), AddressSplit3 NVARCHAR(255)

UPDATE house_data
SET AddressSplit1 = TRIM(PARSENAME(REPLACE(Address, ',', '.'), 3)),
    AddressSplit2 = TRIM(PARSENAME(REPLACE(Address, ',', '.'), 2)),
    AddressSplit3 = TRIM(PARSENAME(REPLACE(Address, ',', '.'), 1));

--------------------------------------------------------------------------------------------------------------------------
-- Populate Postal Code
-- Postal code in Dublin has a pattern with Dublin + Number and AddressSplit3 column has the postal code information.
-- Populate postal code for Dublin Area with AddressSplit3 column if it is null.

UPDATE house_data
SET Postal_code = ISNULL(Postal_code, AddressSplit3)
FROM house_data
WHERE Postal_Code IS NULL AND AddressSplit3 LIKE '%Dublin [0-9]%'

--------------------------------------------------------------------------------------------------------------------------
-- Unify County Names in AddressSplit3
UPDATE house_data
SET AddressSplit3 = CASE WHEN TRIM(AddressSplit3) = 'COUNTY SLIGO' THEN 'SLIGO'
        WHEN TRIM(AddressSplit3) = 'COUNTYT SLIGO' THEN 'SLIGO'
        WHEN TRIM(AddressSplit3) = ' CO SLIGO' THEN 'SLIGO'
        WHEN TRIM(AddressSplit3) = 'COUNTY CORK' THEN 'CORK'
        WHEN TRIM(AddressSplit3) = 'CO CORK' THEN 'CORK'
        WHEN TRIM(AddressSplit3) = 'CO DUBLIN' THEN 'DUBLIN'
        WHEN TRIM(AddressSplit3) = 'COUNTY DUBLIN' THEN 'DUBLIN'
        WHEN TRIM(AddressSplit3) = 'COUNTY GALWAY' THEN 'GALWAY'
        WHEN TRIM(AddressSplit3) = 'CO GALWAY' THEN 'GALWAY'
        ELSE UPPER(TRIM(AddressSplit3))
        END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Euro mark in the Price column and Convert the data type from string to float
ALTER TABLE house_data
ADD PriceClean FLOAT

UPDATE house_data
-- the first convert is getting the price before the period, the sencond convert is getting the decimal points and add both.
SET PriceClean = CONVERT(float, SUBSTRING(REPLACE(Price, ',', ''), 2, CHARINDEX('.', REPLACE(Price, ',', ''))-2)) + CONVERT(float, RIGHT(Price, 2)) / 100

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Split Descriptions
ALTER TABLE house_data
ADD AptTypes NVARCHAR(50)

UPDATE house_data
SET AptTypes = PARSENAME(REPLACE(Descriptions, '/','.'), 2)

UPDATE house_data
SET AptTypes = CASE WHEN AptTypes = 'Second-Hand Dwelling house' THEN 'Second-Hand'
        WHEN AptTypes = 'New Dwelling house' THEN 'New'
        ELSE TRIM(AptTypes)
        END

---------------------------------------------------------------------------------------------------------

-- Create a view with necessary columns
CREATE VIEW ireland_apt_price_v AS
SELECT County,
    SaleDateClean,
    AddressSplit1,
    AddressSplit2,
    AddressSplit3,
    AptTypes,
    PriceClean,
    Not_Full_Market_Price,
    VAT_Exclusive
FROM [Portfolio].[dbo].[house_data]
