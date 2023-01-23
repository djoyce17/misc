--I created a cte for each column because it is more readable and i found this to be the easiest format to 
--made any potential edits to the query in the future

–-calculating the total appointments that took place within 28 days of moving to var pricing model
Select 
Practice_id
count(*) as 
From database.appointments a
Join database.practices p
On a.practice_id = p.practice_id
And datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) <= 28
And a.datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) <= 28
WHERE 1=1
AND not is_cancelled
Group by 1

–calculating the new patient appointments that took place within 28 days of moving to var price model
Select 
Practice_id
count(*) as 
From database.appointments a
Join database.practices p
On a.practice_id = p.practice_id
And datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) <= 28
And a.datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) <= 28
WHERE 1=1
AND not is_cancelled
And is_new_patient
Group by 1


–calculating the new patient appointments that were created and cancelled within 28 days of moving to var price model
Select 
Practice_id
count(*) as 
From database.appointments a
Join database.practices p
On a.practice_id = p.practice_id
And datediff(‘day’, p.variable_pricing_activation_time_utc, a.created_at) <= 28
And a.datediff(‘day’, p.variable_pricing_activation_time_utc, a.appointment_time_utc) <= 28
WHERE 1=1
AND is_cancelled
And is_new_patient
Group by 1


--calculating the number of times the practice added/decreased their spend cap within 28 days of moving to var
select practice_id
	 count(*)
from database.spend_caps sc
Join database.practices p
On sc.practice_id = p.practice_id
And datediff(‘day’, p.variable_pricing_activation_time_utc, sc.start_date) <= 28
And datediff(‘day’, p.variable_pricing_activation_time_utc, sc.end_date) <= 28
where 1=1
and start_cap_amount <> end_cap_amount


--calculating the number of times the practice added/decreased their spend lock within 28 days of moving to var
select practice_id
	 count(*)
from database.spend_caps sc
Join database.practices p
On sc.practice_id = p.practice_id
And datediff(‘day’, p.variable_pricing_activation_time_utc, sc.start_date) <= 28
And datediff(‘day’, p.variable_pricing_activation_time_utc, sc.end_date) <= 28
where 1=1
and start_lock_amount <> end_lock_amount


select practice_id,
       date_trunc(‘day’, practice_activation_time_utc) as practice_activation_date_utc,
       date_trunc(‘day’, variable_pricing_activation_time_utc) as variable_pricing_activation_date_utc,
	 date_add('day', 28, variable_pricing_activation_date_utc) as days_28_post_flip
from database.practices
