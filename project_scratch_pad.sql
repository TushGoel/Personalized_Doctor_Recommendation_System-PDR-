use pdr;

 DROP TABLE IF EXISTS similar_patients;
    CREATE TABLE similar_patients(
    patient_id INT, 
    similarities_couNt INT);

DROP PROCEDURE IF EXISTS recommended_doctors;
DELIMITER //
CREATE PROCEDURE recommended_doctors
(
	IN patient_id_param INT,
	IN specialty_id_param INT
)
BEGIN
	DECLARE patient_gender_var VARCHAR(1);
    DECLARE patient_ethnicity_var INT;
    DECLARE patient_year_var YEAR(4);
    
	SELECT gender, ethnicity_id, yyyy
    INTO patient_gender_var, patient_ethnicity_var, patient_year_var
	FROM patient
	WHERE patient_id = patient_id_param;
    
    TRUNCATE similar_patients;
    INSERT INTO similar_patients (patient_id, similarities_count)
		-- Accumulate similarities
		SELECT patient_id, SUM(similarities) AS 'similarities_cout'
			FROM 
			(
			-- get patients of the same gender
			SELECT patient_id, COUNT(patient_id) AS 'similarities'
			FROM patient
			WHERE gender = patient_gender_var
			GROUP BY patient_id
			UNION ALL
			-- get patients of the same ethnicity
			SELECT patient_id, COUNT(patient_id) AS 'similarities'
			FROM patient
			WHERE ethnicity_id = patient_ethnicity_var
			GROUP BY patient_id
			UNION ALL
			-- get patients of the same age
			SELECT patient_id, COUNT(patient_id) AS 'similarities'
			FROM patient 
			WHERE ABS(yyyy - patient_year_var) < 10
			GROUP BY patient_id
			 UNION ALL
			-- get patients that share diseases 
			SELECT DISTINCT patient_id, COUNT(disease_id) AS 'similarities'
			FROM diagnosis
			WHERE disease_id IN (
				SELECT DISTINCT disease_id
				FROM diagnosis
				WHERE patient_id = patient_id_param) AND 
				patient_id != patient_id_param
			GROUP BY patient_id
			UNION ALL
			-- get patients that share doctors
			SELECT DISTINCT patient_id, COUNT(doctor_id) AS 'similarities'
			FROM patient_has_doctor
			WHERE doctor_id IN (
				SELECT DISTINCT doctor_id
				FROM patient_has_doctor
				WHERE patient_id = patient_id_param) AND 
				patient_id != patient_id_param
			GROUP BY patient_id
			UNION ALL
			-- get patients that share meds
			SELECT DISTINCT patient_id, COUNT(patient_id) AS 'similarities'
			FROM prescription
			WHERE medication_id IN (
				SELECT DISTINCT medication_id
				FROM prescription
				WHERE patient_id = patient_id_param) AND 
				patient_id != patient_id_param
			GROUP BY patient_id) AAC
		GROUP BY patient_id
		HAVING similarities_cout >= 3
		ORDER BY similarities_cout DESC;
    
    -- get the doctors that the similar patients are visiting or have rated
    SELECT first_name, last_name, accepting_patients, specialty_name, 
    qualification, phone, FORMAT(AVG(unit_rate),2) AS avg_sim_pat_rate
    FROM
    (
		SELECT DISTINCT doctor_id, 5 AS 'unit_rate'
		FROM patient_has_doctor
        WHERE patient_id IN ( SELECT patient_id FROM similar_patients )
        UNION ALL
		SELECT ratee_id AS 'doctor_id', overall_rate AS 'unit_rate'
		FROM similar_patients
		JOIN patient_rates_doctor ON (rater_id = patient_id)
    ) contact
    JOIN doctor USING(doctor_id)
    JOIN specialty USING(specialty_id)
    WHERE specialty_id = specialty_id_param
    GROUP BY doctor_id
    HAVING avg_sim_pat_rate >= 3
    ORDER BY avg_sim_pat_rate DESC, doctor_id;
    
end //

DELIMITER ;

call recommended_doctors(552940, 10145);
show warnings;
select * from similar_patients;