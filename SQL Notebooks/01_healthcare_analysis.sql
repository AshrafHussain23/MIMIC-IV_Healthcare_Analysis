-- 1. Total number of patients

SELECT COUNT(*) AS total_patients
FROM patients;

-- 2. Total number of admissions

SELECT COUNT(*) AS total_admissions
FROM admissions;

-- 3. Admissions by type

SELECT
    admission_type,
    COUNT(*) AS admission_count
FROM admissions
GROUP BY admission_type
ORDER BY admission_count DESC;

-- 4. Average patient age

SELECT
    ROUND(AVG(anchor_age), 2) AS average_age
FROM patients;

-- 5. Top 10 diagnoses

SELECT
    d.long_title,
    COUNT(*) AS diagnosis_count
FROM diagnoses_icd di
JOIN d_icd_diagnoses d
    ON di.icd_code = d.icd_code
    AND di.icd_version = d.icd_version
GROUP BY d.long_title
ORDER BY diagnosis_count DESC
LIMIT 10;

-- 6. Top 10 medications

SELECT
    drug,
    COUNT(*) AS medication_orders
FROM prescriptions
GROUP BY drug
ORDER BY medication_orders DESC
LIMIT 10;

-- 7. Admissions by insurance

SELECT
    insurance,
    COUNT(*) AS admission_count
FROM admissions
GROUP BY insurance
ORDER BY admission_count DESC;

-- 8. Diagnoses per admission

SELECT
    hadm_id,
    COUNT(*) AS diagnosis_count
FROM diagnoses_icd
GROUP BY hadm_id
ORDER BY diagnosis_count DESC;

-- 9. Medication orders per admission

SELECT
    hadm_id,
    COUNT(*) AS medication_count
FROM prescriptions
GROUP BY hadm_id
ORDER BY medication_count DESC;

-- 10. Patient, admission and diagnosis details

SELECT
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    p.gender,
    p.anchor_age,
    d.icd_code,
    di.long_title
FROM admissions a
JOIN patients p
    ON a.subject_id = p.subject_id
JOIN diagnoses_icd d
    ON a.hadm_id = d.hadm_id
JOIN d_icd_diagnoses di
    ON d.icd_code = di.icd_code
    AND d.icd_version = di.icd_version
LIMIT 20;

-- 11. Admission summary with diagnosis count

SELECT
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    p.gender,
    p.anchor_age,
    COUNT(d.icd_code) AS diagnosis_count
FROM admissions a
JOIN patients p
    ON a.subject_id = p.subject_id
LEFT JOIN diagnoses_icd d
    ON a.hadm_id = d.hadm_id
GROUP BY
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    p.gender,
    p.anchor_age
ORDER BY diagnosis_count DESC
LIMIT 20;

-- 12. Diagnosis and medication orders per admission

SELECT
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    p.gender,
    p.anchor_age,
    COUNT(DISTINCT d.icd_code) AS diagnosis_count,
    COUNT(pr.drug) AS medication_count
FROM admissions a
JOIN patients p
    ON a.subject_id = p.subject_id
LEFT JOIN diagnoses_icd d
    ON a.hadm_id = d.hadm_id
LEFT JOIN prescriptions pr
    ON a.hadm_id = pr.hadm_id
GROUP BY
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    p.gender,
    p.anchor_age
ORDER BY medication_count DESC
LIMIT 20;



-- 13. Final admission-level summary

SELECT
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    a.insurance,
    p.gender,
    p.anchor_age,
    COALESCE(d.diagnosis_count, 0) AS diagnosis_count,
    COALESCE(m.medication_count, 0) AS medication_count
FROM admissions a

JOIN patients p
    ON a.subject_id = p.subject_id

LEFT JOIN (
    SELECT
        hadm_id,
        COUNT(*) AS diagnosis_count
    FROM diagnoses_icd
    GROUP BY hadm_id
) d
    ON a.hadm_id = d.hadm_id

LEFT JOIN (
    SELECT
        hadm_id,
        COUNT(*) AS medication_count
    FROM prescriptions
    GROUP BY hadm_id
) m
    ON a.hadm_id = m.hadm_id

ORDER BY medication_count DESC;

-- 14. Correct final admission-level summary

WITH diagnosis_summary AS (
    SELECT
        hadm_id,
        COUNT(*) AS diagnosis_count
    FROM diagnoses_icd
    GROUP BY hadm_id
),

medication_summary AS (
    SELECT
        hadm_id,
        COUNT(*) AS medication_count
    FROM prescriptions
    GROUP BY hadm_id
)

SELECT
    a.subject_id,
    a.hadm_id,
    a.admission_type,
    a.insurance,
    p.gender,
    p.anchor_age,
    COALESCE(d.diagnosis_count, 0) AS diagnosis_count,
    COALESCE(m.medication_count, 0) AS medication_count
FROM admissions a

JOIN patients p
    ON a.subject_id = p.subject_id

LEFT JOIN diagnosis_summary d
    ON a.hadm_id = d.hadm_id

LEFT JOIN medication_summary m
    ON a.hadm_id = m.hadm_id

ORDER BY medication_count DESC;