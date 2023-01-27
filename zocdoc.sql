--I created a cte for each column because I find this to be more readable and easy to make changes to

--calculating Total appointments created and took place within 28 days of when the practice moved to the variable pricing model
WITH 
appts AS
(
	SELECT 
		practice_id
		, COUNT(*) AS appts_28_days_post_flip
	FROM database.appointments a
	JOIN database.practices p
	ON a.practice_id = p.practice_id
	WHERE 1=1
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) BETWEEN 0 AND 28
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) BETWEEN 0 AND 28
	AND NOT is_cancelled
	GROUP BY 1
)
,

--calculating New patient appointments created and took place within 28 days of when the practice moved to the variable pricing model
new_appts AS
(
	SELECT 
		practice_id
		, COUNT(*) AS appts_new_patients_28_days_post_flip
	FROM database.appointments a
	JOIN database.practices p
	ON a.practice_id = p.practice_id
	WHERE 1=1
	AND NOT is_cancelled
	AND is_new_patient
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) BETWEEN 0 AND 28
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) BETWEEN 0 AND 28
	GROUP BY 1
)
,

--calculating the new patient appointments that were created and cancelled within 28 days of moving to var price model
canc AS
(
	SELECT 
		practice_id
		, COUNT(*) AS appts_new_patient_cancelled_28_days_post_flip
	FROM database.appointments a
	JOIN database.practices p
	ON a.practice_id = p.practice_id
	WHERE 1=1
	AND is_cancelled
	AND is_new_patient
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) BETWEEN 0 AND 28
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) BETWEEN 0 AND 28
	GROUP BY 1
)
,

--calculating the number of times the practice added/decreased their spend cap within 28 days of moving to var
cap AS
(
	SELECT 
		practice_id
		, COUNT(*) AS negative_spend_cap_changes_28_days
	FROM database.spend_caps sc
	JOIN database.practices p
	ON sc.practice_id = p.practice_id
	WHERE 1=1
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sc.start_date) BETWEEN 0 AND 28
	AND 
	(
		datediff(‘day’, p.variable_pricing_activation_time_utc, sc.end_date) BETWEEN 0 AND 28
		OR end_date IS NULL --this captures the most recent field where the end date is null
	)
	AND start_cap_amount <> end_cap_amount --i was not sure if a new row was added if a customer enters the same cap amount as the previous period so i erred on the side of caution
	GROUP BY 1
)
,

--calculating the number of times the practice added/decreased their spend lock within 28 days of moving to var
lock AS
(
	SELECT 
		practice_id
		, COUNT(*) AS spend_locks_28_days
	FROM database.spend_locks sl
	JOIN database.practices p
	ON sl.practice_id = p.practice_id
	WHERE 1=1
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sl.start_date) <= 28
	AND 
	(
		datediff(‘day’, p.variable_pricing_activation_time_utc, sl.end_date) <= 28
		OR end_date IS NULL --this captures the most recent field where the end date is null
	)
	GROUP BY 1
)

SELECT 
	practice_id								AS practice_id
	, date_trunc(‘day’, practice_activation_time_utc) 			AS practice_activation_date_utc,
	, date_trunc(‘day’, variable_pricing_activation_time_utc) 		AS variable_pricing_activation_date_utc,
	, date_add('day', 28, variable_pricing_activation_date_utc) 		AS days_28_post_flip
	, appts.appts_28_days_post_flip 					AS appts_28_days_post_flip
	, new_appts.appts_new_patients_28_days_post_flip 			AS appts_new_patients_28_days_post_flip
	, canc.appts_new_patient_cancelled_28_days_post_flip 			AS appts_new_patient_cancelled_28_days_post_flip
	, cap.negative_spend_cap_changes_28_days				AS negative_spend_cap_changes_28_days
	, lock.spend_locks_28_days						AS spend_locks_28_days
FROM database.practices pr
LEFT JOIN appts
ON pr.practice_id = appts.practice_id
LEFT JOIN new_appts
ON pr.practice_id = new_appts.practice_id
LEFT JOIN canc
ON pr.practice_id = canc.practice_id
LEFT JOIN cap
ON pr.practice_id = cap.practice_id
LEFT JOIN lock
ON pr.practice_id = lock.practice_id
