/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 03_indexes.sql - Chi muc bo sung (idempotent qua sys.indexes)
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

/* Tim benh nhan theo ten / so dien thoai (tiep don) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_patients_name' AND object_id = OBJECT_ID(N'dbo.patients'))
    CREATE NONCLUSTERED INDEX IX_patients_name ON dbo.patients (full_name);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_patients_phone' AND object_id = OBJECT_ID(N'dbo.patients'))
    CREATE NONCLUSTERED INDEX IX_patients_phone ON dbo.patients (phone);
GO

/* Lich kham: loc theo ngay + trang thai cho man hinh tiep don */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_schedules_date_status' AND object_id = OBJECT_ID(N'dbo.doctor_schedules'))
    CREATE NONCLUSTERED INDEX IX_schedules_date_status ON dbo.doctor_schedules (work_date, status)
        INCLUDE (doctor_id, room_id, slot_capacity, booked_count);
GO

/* Lich hen theo benh nhan (xem lich su dat lich) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_appointments_patient' AND object_id = OBJECT_ID(N'dbo.appointments'))
    CREATE NONCLUSTERED INDEX IX_appointments_patient ON dbo.appointments (patient_id, status);
GO

/* Lan kham: theo benh nhan + ngay (lich su dieu tri) va theo bac si + ngay */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_visits_patient_date' AND object_id = OBJECT_ID(N'dbo.visits'))
    CREATE NONCLUSTERED INDEX IX_visits_patient_date ON dbo.visits (patient_id, visit_date DESC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_visits_doctor_date' AND object_id = OBJECT_ID(N'dbo.visits'))
    CREATE NONCLUSTERED INDEX IX_visits_doctor_date ON dbo.visits (doctor_id, visit_date DESC);
GO

/* 1 lan kham chi gan toi da 1 lich hen - unique co loc (nhieu lan kham
   khong hen co appointment_id = NULL van hop le) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_visits_appointment' AND object_id = OBJECT_ID(N'dbo.visits'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_visits_appointment ON dbo.visits (appointment_id)
        WHERE appointment_id IS NOT NULL;
GO

/* Xet nghiem: truy van theo lan kham va trang thai cho phong xet nghiem */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_lab_orders_visit_status' AND object_id = OBJECT_ID(N'dbo.lab_orders'))
    CREATE NONCLUSTERED INDEX IX_lab_orders_visit_status ON dbo.lab_orders (visit_id, status);
GO

/* Ket qua bat thuong: bao cao / canh bao cho bac si */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_lab_results_abnormal' AND object_id = OBJECT_ID(N'dbo.lab_results'))
    CREATE NONCLUSTERED INDEX IX_lab_results_abnormal ON dbo.lab_results (is_abnormal)
        INCLUDE (lab_order_id, parameter_code, result_value, ref_low, ref_high)
        WHERE is_abnormal = 1;
GO

/* Hoa don: cong no chua thanh toan theo benh nhan, trang thai */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_invoices_patient_status' AND object_id = OBJECT_ID(N'dbo.invoices'))
    CREATE NONCLUSTERED INDEX IX_invoices_patient_status ON dbo.invoices (patient_id, status)
        INCLUDE (gross_total, patient_copay, insurance_payable);
GO

/* Thanh toan theo hoa don + thoi gian (doi soat thu ngan) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_payments_invoice_time' AND object_id = OBJECT_ID(N'dbo.payments'))
    CREATE NONCLUSTERED INDEX IX_payments_invoice_time ON dbo.payments (invoice_id, paid_at);
GO

/* Audit log: truy van theo bang / doi tuong / thoi gian khi dieu tra */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_audit_table_time' AND object_id = OBJECT_ID(N'dbo.audit_logs'))
    CREATE NONCLUSTERED INDEX IX_audit_table_time ON dbo.audit_logs (table_name, record_pk, changed_at DESC);
GO

PRINT N'03_indexes.sql: Da tao 12 chi muc bo sung (gom 1 unique co loc).';
GO
