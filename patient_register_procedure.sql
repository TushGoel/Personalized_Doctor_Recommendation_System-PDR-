DROP PROCEDURE IF EXISTS patient_register_procedure;

DELIMITER //
CREATE PROCEDURE patient_register_procedure
(
	IN patient_email_param VARCHAR(150),
	IN pswd_param VARCHAR(150)
)
BEGIN
	DECLARE patient_email_var VARCHAR(150);
    DECLARE status_var INT;
    
SELECT  email
INTO 
patient_email_var
FROM
password_table
WHERE 
email = patient_email_param;

IF (patient_email_var=patient_email_param) 
THEN
	SET status_var = 0;
END IF;

IF (patient_email_var IS NULL) 
THEN
	SET status_var = 1;
    IF(status_var = 1) 
    THEN
		INSERT INTO password_table
		VALUES
		(patient_email_param,pswd_param); 
	END IF;

END IF;


    END //
DELIMITER ;

CALL patient_register_procedure('Beatrice_Thomas9583@acrit.org','Beatrice');
CALL patient_register_procedure('Beatrice@acrit.org','Beat');

SELECT * FROM password_table;

