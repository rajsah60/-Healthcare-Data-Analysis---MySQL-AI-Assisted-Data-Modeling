create database hospital_db;

use hospital_db;

create table doctors (
doctor_id varchar(10) primary key,
first_name varchar(50),
last_name varchar(50),
specialization varchar(50),
phone_number varchar(15),
years_experience int,
hospital_branch varchar(50),
email varchar(100)
);

create table patients (
patient_id varchar(10) primary key,
first_name varchar(50),
last_name varchar(50),
gender char(1),
date_of_birth date,
contact_number varchar(15),
address varchar(100),
registration_date date,
insurance_provider varchar(50),
insurance_number varchar(50),
email varchar(100)
);


create table appointments (
appointment_id varchar(10) primary key,
patient_id varchar(10),
doctor_id varchar(10),
appointment_date date,
appointment_time time,
reason_for_visit varchar(50),
status  varchar(20),
foreign key (patient_id) references patients(patient_id),
foreign key (doctor_id) references doctors (doctor_id)
);


create table treatments (
treatment_id varchar(10) primary key,
appointment_id varchar(10),
treatment_type varchar(50),
description varchar(100),
cost decimal(10,2),
treatment_date date,
foreign key (appointment_id) references appointments (appointment_id)
);


create table billing (
bill_id varchar(10) primary key,
patient_id varchar(10),
treatment_id varchar(10),
bill_date date,
amount decimal(10,2),
payment_method varchar(20),
payment_status varchar(20),
foreign key (patient_id) references patients (patient_id),
foreign key (treatment_id) references treatments (treatment_id)
);


select * from doctors;
select * from patients;
select * from treatments;
select * from appointments;
select * from billing;


-- --------- ----------------------------------- ---------------------------------------------------------------------------

-- 1. List all patients registered after 2022-01-01.

		select * from patients 
        where registration_date > '2022-01-01';
        
-- 2. Find all appointments with status Cancelled.

		select * from appointments
        where status = 'cancelled';
        
-- 3. Show all doctors with more than 20 years of experience.

		select * from doctors
        where years_experience > 20;
        
-- 4. Show the full name of the patient and the appointment date/time for every appointment.
	
		select concat(p.first_name,' ',p.last_name) as full_name, 
				a.appointment_date, a.appointment_time
                from patients as p
                join appointments as a
                on p.patient_id = a.patient_id;
		
-- 5. List each doctor's name along with the specialization and the number of appointments they have.

				select d.first_name, d.last_name, d.specialization, 
					    count(appointment_id) as total_appointment
                        from doctors as d
                        left join appointments as a
                        on d.doctor_id = a.doctor_id
                        group by  d.first_name, d.last_name, d.specialization;
				
-- 6. For every treatment, show the treatment type, cost, and the patient's name who received it.

			select t.treatment_type, t.cost, p.first_name, p.last_name
            from treatments as t
            join billing as b 
            on t.treatment_id = b.treatment_id
            join patients as p
			on b.patient_id = p.patient_id;
            
            
-- 7. how much revenue each doctor has generated through their patients' bills.

			select d.first_name, d.last_name, sum(b.amount) as total_revenue
            from doctors as d
            join appointments as a
            on d.doctor_id = a.doctor_id
            join treatments as t
            on a.appointment_id = t.appointment_id
            join billing as b
            on t.treatment_id = b.treatment_id
            group by d.first_name, d.last_name;

			
-- 8. List patients who have a Failed payment status, along with the doctor they saw and the treatment type.

			create view payment_status as 
            select concat(p.first_name,' ', p.last_name) as Patient_name, 
				  concat(d.first_name,' ', d.last_name) as doctor_name,
				   t.treatment_type,b.payment_status
                   from patients as p
                   join billing as b
                   on p.patient_id = b.patient_id
                   join treatments as t
                   on b.treatment_id = t.treatment_id
                   join appointments as a
                   on t.appointment_id = a.appointment_id
                   join doctors as d
                   on a.doctor_id = d.doctor_id;
	
		select * from payment_status 
        where payment_status = 'pending';
                   
-- 9. Find the average treatment cost per treatment_type, sorted highest to lowest.

			select treatment_type, round(avg(cost)) as avg_cost
            from treatments 
            group by treatment_type
            order by avg_cost desc;
            
-- 10. Which hospital branch has the highest total billing amount collected (payment_status = 'Paid' only)?

			select d.hospital_branch,sum(b.amount) as total_billing_amount
            from doctors as d
            join appointments as a
            on d.doctor_id = a.doctor_id
            join treatments as t
            on a.appointment_id = t.appointment_id
            join billing as b
            on t.treatment_id = b.treatment_id
            where b.payment_status = 'paid'
            group by d.hospital_branch
            order by total_billing_amount desc
            limit 1;
			

-- 11. Find the top 3 most expensive treatments and the patient + doctor involved in each.
			
            select concat(d.first_name,' ', d.last_name) as Doctor_full_name,
            concat(p.first_name,' ', p.last_name) as Patient_full_name,
            t.treatment_type,t.cost
            from  treatments as t
            join appointments as a
            on t.appointment_id = a.appointment_id
            join patients as p
            on a.patient_id = p.patient_id
            join doctors as d
            on a.doctor_id = d.doctor_id
            order by t.cost desc
            limit 3;

            
-- 12. Which insurance provider is associated with the most Failed payments?

			select p.insurance_provider, count(*) as most_failed_payments
            from patients as p
            join billing as b
			on p.patient_id = b.patient_id
            where payment_status = 'failed'
            group by p.insurance_provider
            order by most_failed_payments desc
            limit 1 
		
-- 13. For every treatment, label it as 'Low' (cost < 1500), 'Medium' (1500–3500), or 'High' (> 3500).
			
			 select treatment_id, treatment_type, cost,
            case 
              when cost < 1500 then 'Low'
              when cost between 1500 and 3500 then 'Medium'
              else 'High'
              end as label
              from treatments;

-- 14. Rank all doctors by the total billing amount their patients generated, highest first.

			select d.doctor_id, d.first_name, d.last_name, 
            sum(b.amount) as total_bill,
            rank() over ( order by sum(b.amount) desc) as revenue_rnk
            from doctors as d
            join appointments as a
            on d.doctor_id = a.doctor_id
            join treatments as t
            on a.appointment_id = t.appointment_id
            join billing as b
            on t.treatment_id = b.treatment_id
            group by d.doctor_id, d.first_name, d.last_name

