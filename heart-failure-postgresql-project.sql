/* =====================================================
   TABLE: heart_failure
   Purpose:
   - Stores clinical data of heart failure patients
   - Each row represents one patient
   ===================================================== */

CREATE TABLE heart_failure (
    patient_id SERIAL PRIMARY KEY,
    age INT,
    anaemia INT,
    creatinine_phosphokinase INT,
    diabetes INT,
    ejection_fraction INT,
    high_blood_pressure INT,
    platelets FLOAT,
    serum_creatinine FLOAT,
    serum_sodium INT,
    sex INT,
    smoking INT,
    time INT,
    death_event INT
);


SELECT * FROM heart_failure


/* =====================================================
   IMPORT DATA FROM CSV FILE
   Dataset: Heart Failure Clinical Records
   ===================================================== */
COPY heart_failure(
 age, anaemia, creatinine_phosphokinase, diabetes,
 ejection_fraction, high_blood_pressure, platelets,
 serum_creatinine, serum_sodium, sex, smoking, time, death_event
)
FROM 'C:\Users\HP\OneDrive\Desktop\SQL Notes\heart_failure_clinical_records_datasetupdated.csv'
DELIMITER ','
CSV HEADER;


--VERIFYING THE DATA
SELECT COUNT(*) FROM heart_failure;

--CHECKING SAMPLE ROWS
SELECT * FROM heart_failure LIMIT 5;

/* =====================================================
   ANALYSIS: EFFECT OF SMOKING ON DEATH RATE
   ===================================================== */

SELECT smoking,
       COUNT(*) AS total_patients,
       SUM(death_event) AS deaths
FROM heart_failure
GROUP BY smoking;


/* =====================================================
   Showing average age and heart efficiency
   ===================================================== */

SELECT 
    AVG(age) AS avg_age,
    AVG(ejection_fraction) AS avg_ejection_fraction
FROM heart_failure;


/* =====================================================
   ANALYSIS: KIDNEY AND SODIUM LEVELS IN DEATH CASES
   ===================================================== */

SELECT 
    AVG(serum_creatinine) AS avg_creatinine,
    AVG(serum_sodium) AS avg_sodium
FROM heart_failure
WHERE death_event = 1;

/* =====================================================
   VIEW: high_risk_patients
   Criteria:
   - Age > 60
   - Low ejection fraction
   - High serum creatinine
   ===================================================== */

CREATE VIEW high_risk_patients AS
SELECT *
FROM heart_failure
WHERE age > 60
AND ejection_fraction < 35
AND serum_creatinine > 1.5;

/* =====================================================
   DISPLAY HIGH RISK PATIENT RECORDS
   ===================================================== */

SELECT COUNT(*) AS high_risk_count
FROM high_risk_patients;

/* =====================================================
   SUBQUERY:
   Finding patients whose age is greater than
   the average age of all patients
   ===================================================== */

SELECT *
FROM heart_failure
WHERE age >
      (SELECT AVG(age) FROM heart_failure);


/* =====================================================
   CORRELATED SUBQUERY:
   Finding patients with highest kidney creatinine level
   ===================================================== */

SELECT *
FROM heart_failure h
WHERE serum_creatinine =
      (SELECT MAX(serum_creatinine)
       FROM heart_failure
       WHERE sex = h.sex);

/* =====================================================
   CASE STATEMENT:
   Categorizing patients into risk levels
   ===================================================== */

SELECT patient_id,
       age,
       ejection_fraction,
       CASE
           WHEN age > 65 AND ejection_fraction < 30 THEN 'HIGH RISK'
           WHEN age BETWEEN 45 AND 65 THEN 'MEDIUM RISK'
           ELSE 'LOW RISK'
       END AS risk_category
FROM heart_failure;

/* =====================================================
   CTE (COMMON TABLE EXPRESSION):
   Temporary result used for further queries
   ===================================================== */

WITH high_risk AS (
    SELECT *
    FROM heart_failure
    WHERE age > 60
      AND ejection_fraction < 35
)
SELECT COUNT(*) AS high_risk_patients
FROM high_risk;

/* =====================================================
   EXISTS:
   Checking existence of rows in subquery
   ===================================================== */

SELECT *
FROM heart_failure h
WHERE EXISTS (
    SELECT 1
    FROM heart_failure
    WHERE death_event = 1
      AND h.age > 70
);

/* =====================================================
   Automatically filtering critical patients
   ===================================================== */

CREATE VIEW critical_patients AS
SELECT *
FROM heart_failure
WHERE death_event = 1
AND serum_creatinine > 2.0;

/* =====================================================
    Checking existence of rows in subquery
   ===================================================== */

SELECT *
FROM heart_failure h
WHERE EXISTS (
    SELECT 1
    FROM heart_failure
    WHERE death_event = 1
      AND h.age > 70
);


/* =====================================================
   PERCENTILE CONTINUOUS:
   Finds median age of patients
   ===================================================== */

SELECT 
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY age) AS median_age
FROM heart_failure;


/* =====================================================
   ROLLUP:
   Subtotals + Grand total in one query
   ===================================================== */

SELECT sex,
       diabetes,
       COUNT(*) AS total_patients
FROM heart_failure
GROUP BY ROLLUP(sex, diabetes);

/* =====================================================
   CUBE:
   Generating all possible combinations of grouping
   ===================================================== */

SELECT sex,
       smoking,
       COUNT(*) AS total
FROM heart_failure
GROUP BY CUBE(sex, smoking);

/* =====================================================
   FILTER:
   Conditional aggregation inside SELECT
   ===================================================== */

SELECT
    COUNT(*) AS total_patients,
    COUNT(*) FILTER (WHERE death_event = 1) AS total_deaths,
    COUNT(*) FILTER (WHERE diabetes = 1) AS diabetics
FROM heart_failure;

/* =====================================================
   JSON CONVERSION:
   Converting patient record into JSON format
   ===================================================== */

SELECT row_to_json(h)
FROM heart_failure h
LIMIT 3;

/* =====================================================
   TRIGGER FUNCTION:
   Automatically mark critical patients
   ===================================================== */

CREATE OR REPLACE FUNCTION mark_critical()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ejection_fraction < 25 THEN
        NEW.death_event := 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/* =====================================================
   MATERIALIZED VIEW:
   Storing query result physically
   ===================================================== */

CREATE MATERIALIZED VIEW death_summary AS
SELECT sex,
       COUNT(*) AS deaths
FROM heart_failure
WHERE death_event = 1
GROUP BY sex;

/* =====================================================
   CHECK CONSTRAINT:
   Ensuring valid medical values
   ===================================================== */

ALTER TABLE heart_failure
ADD CONSTRAINT chk_ejection_fraction
CHECK (ejection_fraction BETWEEN 0 AND 100);

/* =====================================================
   CONDITIONAL COUNT:
   Counting smokers and non-smokers separately
   ===================================================== */

SELECT
    SUM(CASE WHEN smoking = 1 THEN 1 ELSE 0 END) AS smokers,
    SUM(CASE WHEN smoking = 0 THEN 1 ELSE 0 END) AS non_smokers
FROM heart_failure;

/* =====================================================
   RANGE FILTER:
   Patients with normal sodium levels
   ===================================================== */

SELECT *
FROM heart_failure
WHERE serum_sodium BETWEEN 135 AND 145;


/* =====================================================
   NULL CHECK:
   Verify if any missing values exist
   ===================================================== */

SELECT COUNT(*) AS missing_platelets
FROM heart_failure
WHERE platelets IS NULL;

/* =====================================================
   UPDATE OPERATION:
   Marking patients as smokers based on condition
   ===================================================== */

UPDATE heart_failure
SET smoking = 1
WHERE smoking = 0
  AND age > 55;


/* =====================================================
   DELETE OPERATION:
   Remove test patient records (if any)
   ===================================================== */

DELETE FROM heart_failure
WHERE age < 1;

/* =====================================================
   FOLLOW-UP ANALYSIS:
   Patients monitored for more than 200 days
   ===================================================== */

SELECT *
FROM heart_failure
WHERE time > 200;

/* =====================================================
   OR CONDITION:
   Smokers or diabetic patients
   ===================================================== */

SELECT *
FROM heart_failure
WHERE smoking = 1
   OR diabetes = 1;












