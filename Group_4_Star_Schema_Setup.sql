use Group_Project
GO



--Union final dataset
select *
into dbo.inf_data_upload_final
from dbo.inf_data_upload2
where inf_value<>0
UNION
select *
from dbo.inf_data_upload3
where inf_value<>0


--Create and load data table
--this table holds all unique evaluation dates within our dataset
create table Date_Detail (
	Date_ID varchar(100) NOT NULL,
    Year varchar(100) NOT NULL,
    Month varchar(100) NOT NULL,
    Seasonal_Adj varchar(100) NOT NULL,
    PRIMARY KEY (Date_ID));


INSERT INTO Date_Detail (Date_ID,Year,Month,Seasonal_Adj)
SELECT Distinct 
	CONCAT(YEAR(Evaluation_Date),Month(evaluation_date),period),
	Year(Evaluation_Date),
	Month(Evaluation_Date),
	period
	FROM inf_data_upload_final;

--Create and load item table
--This table holds all unique item groups and subgroups
create table Item (
	Item_ID varchar(100) not null
    ,Item_Group varchar(100) not null
    ,Item_Subgroup varchar(100) null 
    ,Item_Name varchar(100) not null
    ,PRIMARY KEY (Item_ID));
 

Insert Into Item (Item_Id,Item_Group,Item_Subgroup,Item_Name) 
select distinct
	item_code
	,case item_description 
			when 'All items' then 'All'
			when 'Apparel' then 'Apparel'
			when 'Education and communication' then 'Education and communication'
            when 'Food' then 'Food and beverages'
            when 'Food and beverages' then 'Food and beverages'
			when 'Fuels and utilities' then 'Housing'
            when 'Housing' then 'Housing'
			when 'Medical Care' then 'Medical care'
            when 'Motor fuel' then 'Transporation'
            when 'Other goods and services' then 'Other goods'
            when 'Private transportation' then 'Transportation'
            when 'Recreation' then 'Recreation'
            when 'Shelter' then 'Shelter'
            when 'Transportation' then 'Transportation' 
            when 'Medical care commodities' then 'Medical care'
            when 'Medical care services' then 'Medical care'
            when 'Tuition, other school fees, and childcare' then 'Education' end
    , case  WHEN
            item_description in ('All items','Apparel','Education and communication'
            ,'Food and beverages','Housing','Medical Care','Transportation','Recreation'
            ,'Shelter') then NULL else item_description END
	,item_description
from dbo.inf_data_upload_final;


create table Data_Source (
	Source_ID varchar(100) NOT NULL,
    Entity varchar(100) NOT NULL,
    Evaluation datetime NOT NULL,
    PRIMARY KEY (Source_ID));

--create and load data source table
--this table holds id's for each dat source we used
--goal was to incroporate more than just one, but we settled on just BLS
Insert into Data_Source (Source_ID,Entity,Evaluation)
	Select 'BLS','Bureau of Labor Statistics',Getdate();

--create and load location table
--this table holds all unique locations in our dataset 
--includes regions and subregions
create table Location (
	Location_ID varchar(100) NOT NULL,
    Region varchar(100) NOT NULL,
    Subregion varchar(100)  NULL,
    PRIMARY KEY (Location_ID));


INSERT INTO Location (Location_ID,Region,Subregion)
select DISTINCT
area_code,
CASE   WHEN    ltrim(rtrim(area_description)) in (
                'Midwest','Northeast','South','West') then ltrim(rtrim(area_description))
        when    ltrim(rtrim(area_description)) in (
                'New York-Newark-Jersey City, NY-NJ-PA',
                'Philadelphia-Camden-Wilmington, PA-NJ-DE-MD',
                'Boston-Cambridge-Newton, MA-NH',
                'Pittsburgh, PA',
                'New England',
                'Middle Atlantic') then 'Northeast'
        WHEN    ltrim(rtrim(area_description)) in (
                'Chicago-Naperville-Elgin, IL-IN-WI',
                'Detroit-Warren-Dearborn, MI',
                'Minneapolis-St.Paul-Bloomington, MN-WI',
                'St. Louis, MO-IL',
                'Cleveland-Akron, OH',
                'Milwaukee-Racine, WI',
                'Cincinnati-Hamilton, OH-KY-IN',
                'Kansas City, MO-KS') then 'Midwest'
        WHEN    ltrim(rtrim(area_description)) in (
                'Atlanta-Sandy Springs-Roswell, GA',
                'Dallas-Fort Worth-Arlington, TX',
                'Houston-The Woodlands-Sugar Land, TX',
                'Miami-Fort Lauderdale-West Palm Beach, FL',
                'Tampa-St. Petersburg-Clearwater, FL',
                'Washington-Arlington-Alexandria, DC-VA-MD-WV',
                'Baltimore-Columbia-Towson, MD',
                'Washington-Baltimore, DC-MD-VA-WV') then 'South'
        WHEN    ltrim(rtrim(area_description)) in (
                'Urban Alaska',
                'Urban Hawaii',
                'Los Angeles-Long Beach-Anaheim, CA',
                'Riverside-San Bernardino-Ontario, CA',
                'Phoenix-Mesa-Scottsdale, AZ',
                'San Diego-Carlsbad, CA',
                'San Francisco-Oakland-Hayward, CA',
                'Seattle-Tacoma-Bellevue WA',
                'Los Angeles-Riverside-Orange County, CA',
                'Denver-Aurora-Lakewood, CO') then 'West'
                else ltrim(rtrim(area_description)) END,
CASE   WHEN    ltrim(rtrim(area_description)) in (
                'Midwest','Northeast','South','West') then NULL else ltrim(rtrim(area_description)) END

from inf_data_upload_final;


--create and load fact table
--this table holds all inflation index values for each unique dimension in our data
Create table CPI_Fact_Table (
	Date_ID varchar(100) NOT NULL,
    Location_ID varchar(100) NOT NULL,
    Source_ID varchar(100) NOT NULL,
    Item_ID varchar(100) NOT NULL,
    CPI_Value decimal(15,3) NULL,
    FOREIGN KEY (Date_ID) References Date_Detail(Date_ID),
    FOREIGN KEY (Location_ID) References Location(Location_ID),
    FOREIGN KEY (Source_ID) References Data_Source(Source_ID),
    FOREIGN KEY (Item_ID) References Item(Item_ID)
    );


Insert Into  CPI_Fact_Table (Date_ID,Location_ID,Source_ID,Item_ID,CPI_Value)
	Select distinct
    CONCAT(YEAR(Evaluation_Date),Month(evaluation_date),period),
    area_code,
	'BLS',
    item_code,
    inf_value
    from inf_data_upload_final;
        