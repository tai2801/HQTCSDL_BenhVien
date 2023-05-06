/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 04_views.sql - Cac view bao cao (CREATE OR ALTER - chay lai duoc)
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

/* V1: Luot kham theo chuyen khoa va thang ---------------------------------- */
CREATE OR ALTER VIEW dbo.v_visit_volume_by_department AS
SELECT
    d.department_code,
    d.department_name,
    FORMAT(v.visit_date, 'yyyy-MM') AS visit_month,
    COUNT(*)                        AS total_visits,
    SUM(CASE WHEN v.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_visits,
    SUM(CASE WHEN v.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_visits,
    COUNT(DISTINCT v.patient_id)    AS distinct_patients
FROM dbo.visits v
JOIN dbo.doctors doc      ON doc.doctor_id = v.doctor_id
JOIN dbo.departments d    ON d.department_id = doc.department_id
GROUP BY d.department_code, d.department_name, FORMAT(v.visit_date, 'yyyy-MM');
GO

/* V2: Lich su dieu tri cua benh nhan (1 dong = 1 lan kham kem chan doan chinh) */
CREATE OR ALTER VIEW dbo.v_patient_treatment_history AS
SELECT
    p.patient_id,
    p.patient_code,
    p.full_name            AS patient_name,
    v.visit_id,
    v.visit_code,
    v.visit_date,
    v.status               AS visit_status,
    doc.full_name          AS doctor_name,
    d.department_name,
    v.chief_complaint,
    dg.icd10_code          AS primary_icd10,
    dg.icd10_name          AS primary_diagnosis,
    mr.record_status
FROM dbo.visits v
JOIN dbo.patients p       ON p.patient_id = v.patient_id
JOIN dbo.doctors doc      ON doc.doctor_id = v.doctor_id
JOIN dbo.departments d    ON d.department_id = doc.department_id
LEFT JOIN dbo.diagnoses dg ON dg.visit_id = v.visit_id AND dg.diagnosis_type = 'PRIMARY'
LEFT JOIN dbo.medical_records mr ON mr.visit_id = v.visit_id;
GO

/* V3: Doanh thu theo thang - chi tinh tien DA THU (payments COMPLETED),
   tach nguon benh nhan / BHYT; khong lay gross_total cua hoa don chua thu */
CREATE OR ALTER VIEW dbo.v_revenue_by_month AS
SELECT
    FORMAT(pay.paid_at, 'yyyy-MM') AS revenue_month,
    COUNT(DISTINCT pay.invoice_id) AS invoices_with_payment,
    SUM(CASE WHEN pay.payer_type = 'PATIENT'   THEN pay.amount ELSE 0 END) AS patient_collected,
    SUM(CASE WHEN pay.payer_type = 'INSURANCE' THEN pay.amount ELSE 0 END) AS insurance_collected,
    SUM(pay.amount) AS total_collected
FROM dbo.payments pay
WHERE pay.status = 'COMPLETED'
GROUP BY FORMAT(pay.paid_at, 'yyyy-MM');
GO

/* V4: Cong no BHYT - phan BHYT phai tra theo co quan/the va trang thai ho so */
CREATE OR ALTER VIEW dbo.v_insurance_receivables AS
SELECT
    COALESCE(ic.insurer_name, N'(không có thẻ)') AS insurer_name,
    inv.insurance_claim_status,
    COUNT(*)                 AS invoice_count,
    SUM(inv.insurance_payable) AS insurance_receivable,
    SUM(CASE WHEN inv.insurance_claim_status = 'APPROVED'
             THEN inv.insurance_payable ELSE 0 END) AS approved_amount
FROM dbo.invoices inv
LEFT JOIN dbo.insurance_cards ic ON ic.insurance_id = inv.insurance_id
WHERE inv.status <> 'CANCELLED' AND inv.insurance_payable > 0
GROUP BY COALESCE(ic.insurer_name, N'(không có thẻ)'), inv.insurance_claim_status;
GO

/* V5: Lich lam viec cua bac si kem so slot con trong (cho tiep don dat lich) */
CREATE OR ALTER VIEW dbo.v_doctor_schedule_availability AS
SELECT
    s.schedule_id,
    s.work_date,
    s.shift_code,
    s.start_time,
    s.end_time,
    doc.full_name     AS doctor_name,
    d.department_name,
    r.room_code,
    s.slot_capacity,
    s.booked_count,
    (s.slot_capacity - s.booked_count) AS remaining_slots,
    s.status          AS schedule_status
FROM dbo.doctor_schedules s
JOIN dbo.doctors doc   ON doc.doctor_id = s.doctor_id
JOIN dbo.departments d ON d.department_id = doc.department_id
JOIN dbo.rooms r       ON r.room_id = s.room_id;
GO

/* V6: Ket qua xet nghiem BAT THUONG chua duoc duyet het (can bac si chu y) -- */
CREATE OR ALTER VIEW dbo.v_abnormal_lab_results AS
SELECT
    p.patient_code,
    p.full_name       AS patient_name,
    v.visit_code,
    v.visit_date,
    res.parameter_code,
    res.parameter_name,
    res.result_value,
    res.unit,
    res.ref_low,
    res.ref_high,
    res.resulted_at,
    CASE WHEN res.verified_by IS NULL THEN N'CHƯA DUYỆT' ELSE N'ĐÃ DUYỆT' END AS verify_state
FROM dbo.lab_results res
JOIN dbo.lab_orders lo ON lo.lab_order_id = res.lab_order_id
JOIN dbo.visits v      ON v.visit_id = lo.visit_id
JOIN dbo.patients p    ON p.patient_id = v.patient_id
WHERE res.is_abnormal = 1;
GO

/* V7: Hoa don chua thanh toan du (cong no benh nhan) ------------------------ */
CREATE OR ALTER VIEW dbo.v_unpaid_invoices AS
SELECT
    inv.invoice_no,
    inv.issued_at,
    inv.due_date,
    p.patient_code,
    p.full_name AS patient_name,
    inv.gross_total,
    inv.patient_copay,
    COALESCE(paid.patient_paid, 0)                    AS patient_paid,
    (inv.patient_copay - COALESCE(paid.patient_paid, 0)) AS patient_outstanding
FROM dbo.invoices inv
JOIN dbo.patients p ON p.patient_id = inv.patient_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount) AS patient_paid
    FROM dbo.payments
    WHERE payer_type = 'PATIENT' AND status = 'COMPLETED'
    GROUP BY invoice_id
) paid ON paid.invoice_id = inv.invoice_id
WHERE inv.status IN ('ISSUED', 'PARTIALLY_PAID');
GO

PRINT N'04_views.sql: Da tao 7 views.';
GO
