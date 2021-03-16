-- -------------------------------------------------------------------------
-- Stored Procedure recommended_doctors_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS recommended_doctors_procedure;

DELIMITER //
CREATE PROCEDURE recommended_doctors_procedure
(
	IN patient_email_param VARCHAR(150),
	IN specialty_name_param VARCHAR(150),
    IN state_param VARCHAR(2),
    IN insurance_name_param VARCHAR(100)
)
BEGIN
	DECLARE patient_id_var INT;
    DECLARE patient_gender_var VARCHAR(1);
    DECLARE patient_ethnicity_var INT;
    DECLARE patient_year_var YEAR(4);
    DECLARE patient_prefered_lang_var INT;
    DECLARE patient_insurance_id_var INT;
    DECLARE specialty_id_var INT; 
    
	DROP TABLE IF EXISTS similar_patients;
	CREATE TABLE similar_patients(
	patient_id INT, 
	similarities_couNt INT);

	DROP TABLE IF EXISTS results; 
	CREATE TABLE results(
	doctor_id INT UNIQUE,
	full_name VARCHAR(150),
	qualification VARCHAR(4), 
	experience_years INT, 
	accepting_patients TINYINT,
	rating FLOAT
	);
    
	SELECT patient_id, gender, ethnicity_id, yyyy, preferred_lang_id
    INTO patient_id_var, patient_gender_var, patient_ethnicity_var, patient_year_var, patient_prefered_lang_var
	FROM patient
	WHERE email = patient_email_param;
    
    SELECT specialty_id
    INTO specialty_id_var
    FROM specialty
    WHERE specialty_name = specialty_name_param;
    
    SELECT insurance_id 
    INTO patient_insurance_id_var
    FROM insurance 
    WHERE insurance_name = insurance_name_param; 
    
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
			WHERE ABS(yyyy - patient_year_var) < 5
			GROUP BY patient_id
			 UNION ALL
			-- get patients that share diseases 
			SELECT DISTINCT patient_id, COUNT(disease_id) AS 'similarities'
			FROM diagnosis
			WHERE disease_id IN (
				SELECT DISTINCT disease_id
				FROM diagnosis
				WHERE patient_id = patient_id_var) AND 
				patient_id != patient_id_var
			GROUP BY patient_id
			UNION ALL
			-- get patients that share doctors
			SELECT patient_id, COUNT(doctor_id) AS 'similarities'
			FROM patient_has_doctor
			WHERE doctor_id IN (
				SELECT DISTINCT doctor_id
				FROM patient_has_doctor
				WHERE patient_id = patient_id_var) AND 
				patient_id != patient_id_var
			GROUP BY patient_id
			UNION ALL
			-- get patients that share meds
			SELECT patient_id, COUNT(medication_id) AS 'similarities'
			FROM prescription
			WHERE medication_id IN (
				SELECT DISTINCT medication_id
				FROM prescription
				WHERE patient_id = patient_id_var
			) AND patient_id != patient_id_var
			GROUP BY patient_id
            UNION ALL
			-- get patients with the same prefered languages
			SELECT patient_id, 1 AS 'similarities'
            FROM patient
            WHERE preferred_lang_id = patient_prefered_lang_var 
            AND patient_id != patient_id_var
            UNION ALL
            -- get patients with same insurances
            SELECT patient_id, COUNT(insurance_id) AS 'similarities'
            FROM patient_has_insurance
            WHERE insurance_id IN (
				SELECT insurance_id 
                FROM patient_has_insurance
                WHERE patient_id = patient_id_var
            ) AND patient_id != patient_id_var
            GROUP BY patient_id
            ) AAC
		GROUP BY patient_id
		HAVING similarities_cout >= 3
		ORDER BY similarities_cout DESC;
	
    TRUNCATE results;
    -- get the doctors that the similar patients are visiting or have rated
    INSERT INTO results
    SELECT doctor_id, CONCAT(first_name,' ', last_name), qualification, experience_years, accepting_patients, FORMAT(AVG(unit_rate),2) AS 'rating'
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
    LEFT JOIN doctor_has_establishment USING(doctor_id)
    LEFT JOIN establishment USING(establishment_id)
    WHERE specialty_id = specialty_id_var
		AND state = state_param
    GROUP BY doctor_id, state
    HAVING rating >= 3
    ORDER BY rating DESC, doctor_id;
    
    IF (SELECT COUNT(*) FROM results) < 50 THEN 
		INSERT IGNORE INTO results 
			SELECT doctor_id, CONCAT(first_name,' ', last_name), qualification, experience_years, accepting_patients, FORMAT(AVG(overall_rate), 2) AS 'rating'
			FROM doctor
			LEFT JOIN patient_rates_doctor ON(doctor_id = ratee_id)
            LEFT JOIN doctor_has_establishment USING(doctor_id)
			LEFT JOIN establishment USING(establishment_id)
			WHERE specialty_id = specialty_id_var
				AND state = state_param
			GROUP BY doctor_id
			HAVING rating >= 3;
    END IF;
    
    IF insurance_name_param != 'NULL' THEN 
		SELECT full_name, qualification, experience_years, accepting_patients, rating
        FROM results
        LEFT JOIN doctor_accepts_insurance USING(doctor_id)
        LEFT JOIN insurance USING(insurance_id)
        WHERE insurance_id = patient_insurance_id_var;
	ELSE 
		SELECT full_name, qualification, experience_years, accepting_patients, rating
        FROM results;
	END IF;
    
END //
DELIMITER ;
show warnings;

-- -------------------------------------------------------------------------
-- Stored Procedure doctor_info_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS doctor_info_procedure;

DELIMITER //
CREATE PROCEDURE doctor_info_procedure (
	IN doctor_id_param INT
)
BEGIN 

	SELECT  CONCAT(first_name, ' ', last_name) AS 'full_name', 
			specialty_name, 
			qualification, 
            experience_years, 
            IF(accepting_patients = 1, 'YES', 'NO') AS 'accepting',
            FORMAT(AVG(overall_rate), 2) AS 'rating',
            GROUP_CONCAT(DISTINCT name ORDER BY name SEPARATOR ', ' ) AS 'establishments',
            GROUP_CONCAT(DISTINCT language_name ORDER BY language_name SEPARATOR ', ') AS 'languages'
    FROM doctor 
    JOIN specialty USING(specialty_id)
    JOIN patient_rates_doctor ON(doctor_id = ratee_id)
    JOIN doctor_has_establishment USING(doctor_id)
    JOIN establishment USING(establishment_id)
    JOIN doctor_has_language USING(doctor_id)
    JOIN language USING(language_id)
    WHERE doctor_id = doctor_id_param
    GROUP BY doctor_id;
END //

DELIMITER ;
show warnings;


-- -------------------------------------------------------------------------
-- Stored Procedure add_patient_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_patient_procedure;

DELIMITER //
CREATE PROCEDURE add_patient_procedure (
	IN first_name_param VARCHAR(100),
    IN last_name_param VARCHAR(100),
    IN gender_param ENUM('F', 'M'),
    IN yyyy_param YEAR,
    IN mm_param INT,
    IN dd_param INT,
    IN ethnicity_name_param VARCHAR(100),
    IN address_param VARCHAR(150),
    IN state_param VARCHAR(2),
    IN city_param VARCHAR(50),
    IN zipcode_param INT,
    IN email_param VARCHAR(150),
    IN preffered_lang_name_param VARCHAR(150),
    IN phone_param VARCHAR(15)
)
BEGIN 
    DECLARE ethnicity_id_var INT;
    DECLARE preferred_lang_id_var INT;
    
    SELECT ethnicity_id
    INTO ethnicity_id_var
    FROM ethnicity
    WHERE ethnicity_name = ethnicity_name_param; 
    
    SELECT language_id
    INTO preferred_lang_id_var
    FROM language
    WHERE language_name = preffered_lang_name_param;
    
    INSERT INTO patient(  
		first_name,
		last_name,
		gender,
		yyyy,
		mm,
		dd,
		ethnicity_id,
		address,
		state,
		city,
		zipcode,
		email,
		preferred_lang_id,
		phone) 
        VALUES(
		first_name_param,
		last_name_param,
		gender_param,
		yyyy_param,
		mm_param,
		dd_param,
		ethnicity_id_var,
		address_param,
		state_param,
		city_param,
		zipcode_param,
		email_param,
		preferred_lang_id_var,
		phone); 

END //
DELIMITER ;
show warnings;

-- -------------------------------------------------------------------------
-- Stored Procedure add_prescription_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_prescription_procedure;

DELIMITER //
CREATE PROCEDURE add_prescription_procedure (
	IN yyyy_param YEAR,
    IN mm_param INT,
    IN dd_param INT,
    IN patient_email_param VARCHAR(150),
    IN medication_name_param VARCHAR(100)
)
BEGIN 
	DECLARE patient_id_var INT; 
    DECLARE medication_id_var INT; 
    
    SELECT patient_id
    INTO patient_id_var
    FROM patient 
    WHERE email = patient_email_param;
    
    SELECT medication_id
    INTO medication_id_var
    FROM medication
    WHERE medication_name = medication_name_param;
    
    INSERT INTO prescription(
		yyyy,
        mm,
        dd,
        patient_id,
        medication_id)
    VALUES (
		yyyy_param,
		mm_param,
		dd_param,
		patient_id_var,
		medication_id_var);

END //

DELIMITER ;
show warnings;

-- -------------------------------------------------------------------------
-- Stored Procedure add_diagnosis_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS add_diagnosis_procedure;

DELIMITER //
CREATE PROCEDURE add_diagnosis_procedure (
	IN yyyy_param YEAR,
    IN mm_param INT,
    IN dd_param INT,
    IN disease_name_param VARCHAR(100),
    IN patient_email_param VARCHAR(150)
)
BEGIN 
	DECLARE patient_id_var INT; 
    DECLARE disease_id_var INT; 
    
    SELECT patient_id
    INTO patient_id_var
    FROM patient 
    WHERE email = patient_email_param;
    
    SELECT disease_id
    INTO disease_id_var
    FROM disease
    WHERE disease = disease_name_param;
    
    INSERT INTO diagnosis(
		yyyy,
        mm,
        dd,
        disease_id,
        patient_id)
    VALUES (
		yyyy_param,
		mm_param,
		dd_param,
        disease_id_var,
		patient_id_var);
END //

DELIMITER ;
show warnings;

-- -------------------------------------------------------------------------
-- Stored Procedure filters_procedure
-- -------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS filters_procedure;

DELIMITER //
CREATE PROCEDURE filters_procedure (
	IN gender_param ENUM('F', 'M'),
    IN insurance_name_param VARCHAR(150)
)
BEGIN 
	DECLARE insurance_id_var INT;
    
	SELECT insurance_id
    INTO insurance_id_var
    FROM insurance
    WHERE insurance_name = insurance_name_param; 
    
	DROP TABLE IF EXISTS filtered_results; 
	CREATE TABLE filtered_results(
	doctor_id INT UNIQUE,
	full_name VARCHAR(150),
	qualification VARCHAR(4), 
	experience_years INT, 
	accepting_patients TINYINT,
	rating FLOAT
	);
    
	DROP TABLE IF EXISTS temp; 
	CREATE TABLE temp(
	doctor_id INT UNIQUE,
	full_name VARCHAR(150),
	qualification VARCHAR(4), 
	experience_years INT, 
	accepting_patients TINYINT,
	rating FLOAT
	);
    
	INSERT INTO filtered_results
    select * from results;
    
    IF gender_param != 'null' THEN 
		INSERT INTO temp 
			SELECT filtered_results.doctor_id, filtered_results.full_name, filtered_results.qualification, filtered_results.experience_years, filtered_results.accepting_patients, filtered_results.rating 
			FROM filtered_results
			JOIN doctor USING(doctor_id)
			WHERE gender = gender_param;
        
        TRUNCATE filtered_results;
        INSERT INTO filtered_results
			SELECT * FROM temp; 
    END IF;
    
	IF insurance_name_param != 'null' THEN 
		TRUNCATE temp;
		INSERT INTO temp 
			SELECT DISTINCT filtered_results.doctor_id, filtered_results.full_name, filtered_results.qualification, filtered_results.experience_years, filtered_results.accepting_patients, filtered_results.rating 
			FROM filtered_results
			JOIN doctor_accepts_insurance USING(doctor_id)
			WHERE insurance_id = insurance_id_var;
        
        TRUNCATE filtered_results;
        INSERT INTO filtered_results
			SELECT * FROM temp; 
    END IF;
    
    SELECT * FROM filtered_results; 
    
END //

DELIMITER ;
show warnings;

