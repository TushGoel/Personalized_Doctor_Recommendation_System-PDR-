-- -----------------------------------------------------
-- Schema pdr
-- -----------------------------------------------------

DROP DATABASE IF EXISTS pdr;
CREATE DATABASE  IF NOT EXISTS pdr;
USE pdr;

-- -----------------------------------------------------
-- Table `pdr`.`language`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS language (
  language_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  language_name VARCHAR(150) NOT NULL
	);

-- -----------------------------------------------------
-- Table `pdr`.`availability`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS availability (
  availability_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  day VARCHAR(50) NOT NULL,
  time VARCHAR(50) NOT NULL
      );


-- -----------------------------------------------------
-- Table `pdr`.`disease`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS disease (
  disease_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  disease VARCHAR(150) NOT NULL
      );
      

-- -----------------------------------------------------
-- Table `pdr`.`insurance`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS insurance (
  insurance_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  insurance_name VARCHAR(100) NULL
      );
      
-- -----------------------------------------------------
-- Table `pdr`.`medication`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS medication (
  medication_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  medication_name VARCHAR(100) NULL
      );
      
      -- Table `pdr`.`comment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS comment (
  comment_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  comment VARCHAR(100) NULL
      );

-- -----------------------------------------------------
-- Table `pdr`.`establishment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS establishment (
  establishment_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  name VARCHAR(150) NOT NULL,
  type VARCHAR(150) NOT NULL,
  state VARCHAR(2) NOT NULL,
  city VARCHAR(50) NOT NULL,
  zipcode INT NOT NULL,
  address VARCHAR(255) NOT NULL
      );
      
      -- -----------------------------------------------------
-- Table `pdr`.`specialty`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS specialty (
  specialty_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  specialty_name VARCHAR(150) UNIQUE NOT NULL
  );

-- -----------------------------------------------------
-- Table `pdr`.`ethnicity`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS ethnicity (
  ethnicity_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  ethnicity_name VARCHAR(100) UNIQUE NOT NULL
  );

-- -----------------------------------------------------
-- Table `pdr`.`doctor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor (
  doctor_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender ENUM('F', 'M') NOT NULL,
  yyyy YEAR NOT NULL,
  mm INT NOT NULL,
  dd INT NOT NULL,
  accepting_patients TINYINT NOT NULL,
  specialty_id INT NOT NULL,
  ethnicity_id INT NOT NULL,
  experience_years INT NOT NULL,
  qualification VARCHAR(4) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  FOREIGN KEY (specialty_id) REFERENCES specialty(specialty_id),
  FOREIGN KEY (ethnicity_id) REFERENCES ethnicity(ethnicity_id)
    );

-- -----------------------------------------------------
-- Table `pdr`.`patient`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS patient (
  patient_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender ENUM('F', 'M') NOT NULL,
  yyyy YEAR NOT NULL,
  mm INT NOT NULL,
  dd INT NOT NULL,
  ethnicity_id INT NOT NULL,
  address VARCHAR(150) NOT NULL,
  state VARCHAR(2) NOT NULL,
  city VARCHAR(50) NOT NULL,
  zipcode INT NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  preferred_lang_id INT NOT NULL,
  phone VARCHAR(15) NULL,
  FOREIGN KEY (ethnicity_id) REFERENCES ethnicity(ethnicity_id),
  FOREIGN KEY (preferred_lang_id) REFERENCES language(language_id)
        );
        
-- -----------------------------------------------------
-- Table `pdr`.`patient_rates_doctor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_rates_doctor (
  rating_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  rater_id INT NOT NULL,
  ratee_id INT NOT NULL,
  overall_rate INT NOT NULL,
  FOREIGN KEY (rater_id) REFERENCES patient(patient_id),
  FOREIGN KEY (ratee_id) REFERENCES doctor(doctor_id)
	);
 
-- -----------------------------------------------------
-- Table `pdr`.`patient_rates_establishment`
-- -----------------------------------------------------

 CREATE TABLE IF NOT EXISTS patient_rates_establishment (
  rating_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  rater_id INT NOT NULL,
  ratee_id INT NOT NULL,
  overall_rate INT NOT NULL,
  FOREIGN KEY (rater_id) REFERENCES patient(patient_id),
  FOREIGN KEY (ratee_id) REFERENCES establishment(establishment_id)
        );

-- -----------------------------------------------------
-- Table `pdr`.`doctor_rates_patient`
-- -----------------------------------------------------
        
    CREATE TABLE IF NOT EXISTS doctor_rates_patient (
  rating_id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  rater_id INT NOT NULL,
  ratee_id INT NOT NULL,
  overall_rate INT NOT NULL,
  FOREIGN KEY (rater_id) REFERENCES doctor(doctor_id),
  FOREIGN KEY (ratee_id) REFERENCES patient(patient_id)
        );    
        
-- -----------------------------------------------------
-- Table `pdr`.`rating_has_comments`
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS rating_has_comments_doctors (
  rating_id INT NOT NULL,
  comment_id INT NOT NULL,
  FOREIGN KEY (rating_id) REFERENCES patient_rates_doctor(rating_id),
  FOREIGN KEY (comment_id) REFERENCES comment(comment_id)
        );

-- -----------------------------------------------------
-- Table `pdr`.`rating_has_comments`
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS rating_has_comments_establishment (
  rating_id INT NOT NULL,
  comment_id INT NOT NULL,
  FOREIGN KEY (rating_id) REFERENCES patient_rates_establishment(rating_id),
  FOREIGN KEY (comment_id) REFERENCES comment(comment_id)
        );
 
-- -----------------------------------------------------
-- Table `pdr`.`prescription`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS prescription (
  yyyy YEAR NOT NULL,
  mm INT NOT NULL,
  dd INT NOT NULL,
  doctor_id INT NULL,
  patient_id INT NOT NULL,
  medication_id INT NULL,
  FOREIGN KEY (doctor_id) REFERENCES doctor (doctor_id),
  FOREIGN KEY (patient_id) REFERENCES patient (patient_id),
  FOREIGN KEY (medication_id) REFERENCES medication (medication_id)
        );
        
        
-- -----------------------------------------------------
-- Table `pdr`.`doctor_accepts_insurance`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_accepts_insurance (
  doctor_id INT NOT NULL,
  insurance_id INT NOT NULL,
  FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id),
  FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id)
        );


-- -----------------------------------------------------
-- Table `pdr`.`patient_has_insurance`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_has_insurance (
  patient_id INT NOT NULL,
  insurance_id INT NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (insurance_id) REFERENCES insurance(insurance_id)
        );


-- -----------------------------------------------------
-- Table `pdr`.`diagnosis`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnosis (
  yyyy YEAR NOT NULL,
  mm INT NOT NULL,
  dd INT NOT NULL,
  disease_id INT NULL,
  patient_id INT NOT NULL,
  doctor_id INT NULL,
  FOREIGN KEY (disease_id) REFERENCES disease(disease_id),
  FOREIGN KEY (patient_id) REFERENCES patient(patient_id),
  FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id)
        );


-- -----------------------------------------------------
-- Table `pdr`.`patient_has_doctor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS patient_has_doctor (
  patient_id INT NOT NULL,
  doctor_id INT NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES patient (patient_id),
  FOREIGN KEY (doctor_id) REFERENCES doctor (doctor_id)
        );


-- -----------------------------------------------------
-- Table `pdr`.`availability_has_doctor`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS availability_has_doctor (
  availability_id INT NOT NULL,
  doctor_id INT NOT NULL,
  FOREIGN KEY (availability_id) REFERENCES availability(availability_id),
  FOREIGN KEY (doctor_id) REFERENCES doctor (doctor_id)
        );


-- -----------------------------------------------------
-- Table `pdr`.`doctor_has_establishment`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_has_establishment (
  doctor_id INT NOT NULL,
  establishment_id INT NOT NULL,
  FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id),
  FOREIGN KEY (establishment_id) REFERENCES establishment(establishment_id)
        );


-- -----------------------------------------------------
-- Table `mydb`.`doctor_has_language`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS doctor_has_language (
  doctor_id INT NOT NULL,
  language_id INT NOT NULL,
  FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id),
  FOREIGN KEY (language_id) REFERENCES language(language_id)
    );
    
-- -----------------------------------------------------
-- Table password
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS password_table (
 email VARCHAR(150) NOT NULL unique,
 pswd VARCHAR(150) NOT NULL
    );    