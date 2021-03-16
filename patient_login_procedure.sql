DROP PROCEDURE IF EXISTS patient_login_procedure;

DELIMITER //
CREATE PROCEDURE patient_login_procedure
(
	IN patient_email_param VARCHAR(150),
	IN pswd_param VARCHAR(150)
)
BEGIN
	DECLARE patient_email_var VARCHAR(150);
    DECLARE pswd_var VARCHAR(150);
    
    DROP TABLE IF EXISTS status_patients_2;
	CREATE TABLE status_patients_2
    ( 
    status_1 INT
	 );
         
SELECT email, pswd
INTO 
patient_email_var, pswd_var
FROM
password_table
WHERE 
email = patient_email_param;

IF (patient_email_var=patient_email_param and pswd_var=pswd_param ) THEN
INSERT INTO  status_patients_2
VALUE (1);

ELSE
INSERT INTO  status_patients_2
VALUE (0);
END IF;

    END //
DELIMITER ;

CALL patient_login_procedure('Beatrice_Thomas9583@acrit.org','Beatrice');
CALL patient_login_procedure('Beatrice_Thomas9583@acrit.org','Beatrice');
CALL patient_login_procedure('Beatrice@acrit.org','Beat');

SELECT * FROM status_patients_2;
select * from password_table;

SELECT * FROM status_patients;
