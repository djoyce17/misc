--I created a cte for each column because I find this to be more readable and easy to make changes to

–-calculating the total appointments that took place within 28 days of moving to var pricing model
WITH 
appts AS
(
	SELECT 
		practice_id
		COUNT(*) AS appts_28_days_post_flip
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

–calculating the new patient appointments that took place within 28 days of moving to var price model
new_appts AS
(
	SELECT 
		practice_id
		COUNT(*) AS appts_new_patients_28_days_post_flip
	FROM database.appointments a
	JOIN database.practices p
	ON a.practice_id = p.practice_id
	WHERE 1=1
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) BETWEEN 0 AND 28
	AND a.datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) BETWEEN 0 AND 28
	AND NOT is_cancelled
	AND is_new_patient
	GROUP BY 1
)
,

–calculating the new patient appointments that were created and cancelled within 28 days of moving to var price model
canc AS
(
	SELECT 
		practice_id
		COUNT(*) AS appts_new_patient_cancelled_28_days_post_flip
	FROM database.appointments a
	JOIN database.practices p
	ON a.practice_id = p.practice_id
	And datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) <= 28
	And a.datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) <= 28
	WHERE 1=1
	AND is_cancelled
	And is_new_patient
	GROUP BY 1
)
,

--calculating the number of times the practice added/decreased their spend cap within 28 days of moving to var
cap AS
(
	SELECT 
		practice_id
		COUNT(*) AS negative_spend_cap_changes_28_days
	FROM database.spend_caps sc
	JOIN database.practices p
	ON sc.practice_id = p.practice_id
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sc.start_date) <= 28
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sc.end_date) <= 28
	WHERE 1=1
	AND start_cap_amount <> end_cap_amount
	GROUP BY 1
)
,

--calculating the number of times the practice added/decreased their spend lock within 28 days of moving to var
lock AS
(
	SELECT 
		practice_id
		COUNT(*) AS spend_locks_28_days
	FROM database.spend_caps sc
	JOIN database.practices p
	ON sc.practice_id = p.practice_id
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sc.start_date) <= 28
	AND datediff(‘day’, p.variable_pricing_activation_time_utc, sc.end_date) <= 28
	WHERE 1=1
	AND start_lock_amount <> end_lock_amount
	GROUP BY 1
)

SELECT 
	practice_id,
	date_trunc(‘day’, practice_activation_time_utc) AS practice_activation_date_utc,
	date_trunc(‘day’, variable_pricing_activation_time_utc) AS variable_pricing_activation_date_utc,
	date_add('day', 28, variable_pricing_activation_date_utc) AS days_28_post_flip
FROM database.practices
