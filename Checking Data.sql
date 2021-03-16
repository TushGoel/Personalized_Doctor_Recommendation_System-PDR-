select * from availability;

select * from availability_has_doctor;

select * from comment;

select * from diagnosis;

select * from disease;

select * from doctor;

select * from doctor_accepts_insurance;

select * from doctor_has_establishment;

select doctor.first_name,patient.email, specialty_name, establishment.state, insurance_name
from
insurance join patient_has_insurance using (insurance_id)
join patient using (patient_id)
join patient_has_doctor using (patient_id)
join doctor using (doctor_id)
join specialty using (specialty_id)
join doctor_has_establishment using (doctor_id)
join establishment using (establishment_id)
where specialty_name='Internists';
 
select * from doctor_has_language;

select * from doctor_rates_patient;

select * from establishment;

select * from ethnicity;

select * from insurance;

select * from language;

select * from medication;

select * from patient;

select * from patient_has_doctor;

select * from patient_has_insurance;

select * from patient_rates_doctor;

select * from patient_rates_establishment;

select * from prescription;

select * from rating_has_comments_doctors;

select * from rating_has_comments_establishment;

select * from specialty;