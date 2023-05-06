/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 07_queries_reports.sql - Bo truy van bao cao tu co ban den nang cao
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

/* Q1 (co ban): Danh sach benh nhan kem the BHYT chinh (neu co) ------------- */
SELECT p.patient_code, p.full_name, p.date_of_birth, p.phone,
       ic.card_no, ic.coverage_percent, ic.valid_to
FROM dbo.patients p
LEFT JOIN dbo.insurance_cards ic
       ON ic.patient_id = p.patient_id AND ic.is_primary = 1
ORDER BY p.patient_code;
GO

/* Q2 (co ban): Lich lam viec ngay mai cua tat ca bac si -------------------- */
SELECT * FROM dbo.v_doctor_schedule_availability
WHERE work_date = CAST(DATEADD(DAY, 1, SYSDATETIME()) AS DATE)
ORDER BY start_time, doctor_name;
GO

/* Q3: Luot kham theo chuyen khoa trong thang (dung view V1) ---------------- */
SELECT * FROM dbo.v_visit_volume_by_department
ORDER BY visit_month DESC, total_visits DESC;
GO

/* Q4: Top 5 bac si co nhieu luot kham hoan tat nhat ------------------------ */
SELECT TOP (5) doc.full_name AS doctor_name, d.department_name,
       COUNT(*) AS completed_visits
FROM dbo.visits v
JOIN dbo.doctors doc ON doc.doctor_id = v.doctor_id
JOIN dbo.departments d ON d.department_id = doc.department_id
WHERE v.status = 'COMPLETED'
GROUP BY doc.full_name, d.department_name
ORDER BY completed_visits DESC;
GO

/* Q5: Doanh thu da thu theo thang, tach benh nhan / BHYT (view V3) --------- */
SELECT * FROM dbo.v_revenue_by_month ORDER BY revenue_month;
GO

/* Q6: Ty le ket qua xet nghiem bat thuong theo thong so -------------------- */
SELECT res.parameter_code, res.parameter_name,
       COUNT(*) AS total_results,
       SUM(CASE WHEN res.is_abnormal = 1 THEN 1 ELSE 0 END) AS abnormal_results,
       CAST(100.0 * SUM(CASE WHEN res.is_abnormal = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS abnormal_percent
FROM dbo.lab_results res
GROUP BY res.parameter_code, res.parameter_name
ORDER BY abnormal_results DESC;
GO

/* Q7: Benh nhan co tu 2 lan kham tro len (khach hang than thiet / tai kham)  */
SELECT p.patient_code, p.full_name, COUNT(*) AS visit_count,
       MIN(v.visit_date) AS first_visit, MAX(v.visit_date) AS last_visit
FROM dbo.visits v
JOIN dbo.patients p ON p.patient_id = v.patient_id
WHERE v.status <> 'CANCELLED'
GROUP BY p.patient_code, p.full_name
HAVING COUNT(*) >= 2
ORDER BY visit_count DESC;
GO

/* Q8: Chan doan pho bien nhat (ICD-10 chinh) ------------------------------- */
SELECT TOP (10) dg.icd10_code, dg.icd10_name, COUNT(*) AS case_count
FROM dbo.diagnoses dg
WHERE dg.diagnosis_type = 'PRIMARY'
GROUP BY dg.icd10_code, dg.icd10_name
ORDER BY case_count DESC;
GO

/* Q9 (nang cao): Phan tich hoa don - ty le BHYT chi tra tren tong vien phi
   theo nhom tuyen (dung tuyen / trai tuyen / cap cuu) ----------------------- */
SELECT inv.referral_type,
       COUNT(*) AS invoice_count,
       SUM(inv.gross_total) AS gross_total,
       SUM(inv.insurance_payable) AS insurance_payable,
       SUM(inv.patient_copay) AS patient_copay,
       CAST(100.0 * SUM(inv.insurance_payable) / NULLIF(SUM(inv.gross_total), 0) AS DECIMAL(5,1)) AS insurance_share_percent
FROM dbo.invoices inv
WHERE inv.status <> 'CANCELLED'
GROUP BY inv.referral_type;
GO

/* Q10 (nang cao): Thuoc duoc ke nhieu nhat va tong so luong da ke ---------- */
SELECT m.medication_name, m.active_ingredient,
       COUNT(DISTINCT pi.prescription_id) AS prescription_count,
       SUM(pi.total_quantity) AS total_quantity
FROM dbo.prescription_items pi
JOIN dbo.medications m ON m.medication_id = pi.medication_id
JOIN dbo.prescriptions pr ON pr.prescription_id = pi.prescription_id
WHERE pr.status IN ('ISSUED','DISPENSED')
GROUP BY m.medication_name, m.active_ingredient
ORDER BY total_quantity DESC;
GO

/* Q11 (nang cao - window function): Xep hang luot kham cua bac si
   trong tung chuyen khoa ---------------------------------------------------- */
SELECT d.department_name, doc.full_name AS doctor_name,
       COUNT(*) AS visit_count,
       RANK() OVER (PARTITION BY d.department_name ORDER BY COUNT(*) DESC) AS rank_in_department
FROM dbo.visits v
JOIN dbo.doctors doc ON doc.doctor_id = v.doctor_id
JOIN dbo.departments d ON d.department_id = doc.department_id
WHERE v.status = 'COMPLETED'
GROUP BY d.department_name, doc.full_name
ORDER BY d.department_name, rank_in_department;
GO

/* Q12 (nang cao - CTE): Doi soat hoa don PAID - tong thanh toan phai bang
   phan benh nhan dong chi tra + phan BHYT (cac hoa don lech se lo ra) ------- */
WITH paid_sum AS (
    SELECT invoice_id, payer_type, SUM(amount) AS paid
    FROM dbo.payments WHERE status = 'COMPLETED'
    GROUP BY invoice_id, payer_type
)
SELECT inv.invoice_no, inv.status,
       inv.patient_copay, ISNULL(pp.paid, 0) AS patient_paid,
       inv.insurance_payable, ISNULL(ip.paid, 0) AS insurance_paid,
       CASE WHEN ISNULL(pp.paid, 0) = inv.patient_copay
             AND ISNULL(ip.paid, 0) = inv.insurance_payable
            THEN N'KHỚP' ELSE N'LỆCH - CẦN ĐỐI SOÁT' END AS reconcile_state
FROM dbo.invoices inv
LEFT JOIN paid_sum pp ON pp.invoice_id = inv.invoice_id AND pp.payer_type = 'PATIENT'
LEFT JOIN paid_sum ip ON ip.invoice_id = inv.invoice_id AND ip.payer_type = 'INSURANCE'
WHERE inv.status = 'PAID'
ORDER BY inv.invoice_no;
GO

PRINT N'07_queries_reports.sql: Da chay 12 truy van bao cao.';
GO
