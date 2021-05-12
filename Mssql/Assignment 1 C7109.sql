SET NOCOUNT ON  
DECLARE @Number INT, @Fact INT  
SET @Fact=1  
SET @Number = 6; 
WITH Factorial AS 
(  
	SELECT  
	CASE WHEN @Number<0 THEN NULL ELSE 1 
	END N  
	UNION ALL  
	SELECT (N+1)    
	FROM Factorial  
	WHERE N < @Number
)  
SELECT @Fact = @Fact*N 
FROM Factorial
SELECT @Number AS 'Number', @Fact AS 'Factorial' 


CREATE TABLE alteration (
ID TINYINT PRIMARY KEY IDENTITY,
[User_ID] TINYINT,
[Action] VARCHAR(10),
[Date] DATE,
)
INSERT INTO alteration VALUES	(1, 'Start', CAST('1-1-20' AS DATE)),
								(1,	'Cancel', CAST('1-2-20' AS DATE)),
								(2,	'Start', CAST('1-3-20' AS DATE)),
								(2,	'Publish', CAST('1-4-20' AS DATE)),
								(3,	'Start', CAST('1-5-20' AS DATE)),
								(3,	'Cancel', CAST('1-6-20' AS DATE)),
								(1,	'Start', CAST('1-7-20' AS DATE)),
								(1,	'Publish', CAST('1-8-20' AS DATE))


WITH t1 ([User_ID],[Start],[Publish],[Cancel]) AS (
		SELECT 1, SUM(CASE WHEN [User_ID] = 1 AND [Action] = 'Start' THEN 1 ELSE 0 END),
				SUM (CASE WHEN [User_ID] = 1 AND [Action] = 'Publish' THEN 1 ELSE 0 END),
				SUM (case WHEN [User_ID] = 1 AND [Action] = 'Cancel' THEN 1 ELSE 0 END)
		FROM alteration
		UNION ALL
		SELECT 2, SUM(CASE WHEN [User_ID] = 2 AND [Action] = 'Start' THEN 1 ELSE 0 END),
				SUM (CASE WHEN [User_ID] = 2 AND [Action] = 'Publish' THEN 1 ELSE 0 END),
				SUM (CASE WHEN [User_ID] = 2 AND [Action] = 'Cancel' THEN 1 ELSE 0 END)
		FROM alteration
		UNION ALL
		SELECT 3, SUM(CASE WHEN [USER_ID] = 3 AND [Action] = 'Start' THEN 1 ELSE 0 END),
				SUM (CASE WHEN [USER_ID] = 3 AND [Action] = 'Publish' THEN 1 ELSE 0 END),
				SUM (CASE WHEN [USER_ID] = 3 AND [Action] = 'Cancel' THEN 1 ELSE 0 END)
		FROM alteration
), 

t2 ([User_ID], Publish_Rate, [Cancel_Rate]) AS (
		SELECT [User_ID], ((CAST([Publish] AS FLOAT)/[Start])), (CAST([Cancel] AS FLOAT)/[Start])
		FROM t1
)
SELECT * FROM t2