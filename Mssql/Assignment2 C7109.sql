--1. Changes in net worth

--From the following table of transactions between two users, write a query to return 
-- the change in net worth for each user, ordered by decreasing net change.

WITH tr (sender, receiver, amount, transaction_date) AS
(
	SELECT *
	FROM
		(
			VALUES	(5, 2, 10, CAST('2-12-20' AS DATE)),  
					(1, 3, 15, CAST('2-13-20' AS DATE)),  
					(2, 1, 20, CAST('2-13-20' AS DATE)),  
					(2, 3, 25, CAST('2-14-20' AS DATE)),  
					(3, 1, 20, CAST('2-15-20' AS DATE)),  
					(3, 2, 15, CAST('2-15-20' AS DATE)),  
					(1, 4, 5 , CAST('2-16-20' AS DATE))
			)  AS Table_1 (sender, receiver, amount, transaction_date)

)
SELECT	COALESCE([user_id], [user_id2]) AS [User],
		(COALESCE(credit,0) - COALESCE(debit,0)) AS Net_Change
FROM ((	
		SELECT tr.sender [user_id], sum(tr.amount) 
		FROM tr 
		GROUP BY tr.sender
		) AS table_debit ([user_id], debit) 
FULL JOIN (
		SELECT tr.receiver [user_id], SUM(tr.amount) 
		FROM tr 
		GROUP BY tr.receiver
		) AS table_credit ([user_id2], credit)
ON table_debit.[user_id] = table_credit.[user_id2])

--QUESTION-2
--Create above tables (attendance, students) with “with” clause,
WITH attendance (student_id, school_date, attendance) AS
(
	SELECT *
	FROM
		(
			VALUES	(1, CAST('4-3-20' AS DATE), 0),
					(2, CAST('4-3-20' AS DATE), 1),
					(3, CAST('4-3-20' AS DATE), 1),
					(1, CAST('4-4-20' AS DATE), 1),
					(2, CAST('4-4-20' AS DATE), 1),
					(3, CAST('4-4-20' AS DATE), 1),
					(1, CAST('4-5-20' AS DATE), 0),
					(2, CAST('4-5-20' AS DATE), 1),
					(3, CAST('4-5-20' AS DATE), 1),
					(4, CAST('4-5-20' AS DATE), 1)
			)  AS Table_1 (student_id, school_date, attendance)

),
students (student_id, school_date, attendance, student_id2, school_id, grade_level, date_of_birth) as (		
	SELECT *
	FROM attendance
	INNER JOIN(
		VALUES	(1, 2, 5, CAST('4-3-12' AS DATE)),
				(2, 1, 4, CAST('4-4-13' AS DATE)),
				(3, 1, 3, CAST('4-5-14' AS DATE)),
				(4, 2, 4, CAST('4-3-13' AS DATE))
		) 
		AS Table_2 (student_id, school_id, grade_level, date_of_birth)
		ON attendance.student_id = Table_2.student_id 
			AND (DAY(attendance.school_date) = DAY(Table_2.date_of_birth) 
			AND MONTH(attendance.school_date) = MONTH(Table_2.date_of_birth))

)
SELECT CAST(ROUND(1.0*SUM(attendance)/COUNT(*), 2) AS FLOAT) AS Birthday_attendance
FROM students
