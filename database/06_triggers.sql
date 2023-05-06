/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 06_triggers.sql - Triggers bao ve nghiep vu va kiem toan
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

/* ----------------------------------------------------------------------------
   TRG1: Chan sua truc tiep ho so benh an DA KHOA.
   Ban ghi o trang thai LOCKED truoc khi UPDATE (bang deleted) -> huy giao tac.
   Luu y: thao tac khoa chinh danh (DRAFT -> LOCKED) co deleted = DRAFT nen
   van duoc phep; bo sung sau khoa chi qua record_addenda.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_medical_records_block_locked
ON dbo.medical_records
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted WHERE record_status = 'LOCKED')
    BEGIN
        RAISERROR (N'Hồ sơ bệnh án đã khóa: không sửa trực tiếp. Hãy tạo phụ lục (addendum).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ----------------------------------------------------------------------------
   TRG2: Audit log cho medical_records (UPDATE va DELETE).
   Ghi tom tat OLD/NEW: trang thai, ket luan, do dai ghi chu lam sang.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_medical_records_audit
ON dbo.medical_records
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.audit_logs (table_name, record_pk, action, old_summary, new_summary, changed_by)
    SELECT 'medical_records',
           CAST(d.record_id AS VARCHAR(60)),
           CASE WHEN i.record_id IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
           CONCAT(N'Trạng thái=', d.record_status,
                  N'; Kết luận=', ISNULL(d.conclusion, N'(trống)'),
                  N'; Ghi chú=', CAST(LEN(ISNULL(d.clinical_notes, '')) AS VARCHAR(10)), N' ký tự'),
           CASE WHEN i.record_id IS NULL THEN NULL
                ELSE CONCAT(N'Trạng thái=', i.record_status,
                            N'; Kết luận=', ISNULL(i.conclusion, N'(trống)'),
                            N'; Ghi chú=', CAST(LEN(ISNULL(i.clinical_notes, '')) AS VARCHAR(10)), N' ký tự')
           END,
           ORIGINAL_LOGIN()
    FROM deleted d
    LEFT JOIN inserted i ON i.record_id = d.record_id;
END;
GO

/* ----------------------------------------------------------------------------
   TRG3: Audit log cho record_addenda (INSERT phu luc moi, duyet phu luc).
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_record_addenda_audit
ON dbo.record_addenda
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.audit_logs (table_name, record_pk, action, old_summary, new_summary, changed_by)
    SELECT 'record_addenda',
           CAST(i.addendum_id AS VARCHAR(60)),
           CASE WHEN d.addendum_id IS NULL THEN 'INSERT' ELSE 'UPDATE' END,
           CASE WHEN d.addendum_id IS NULL THEN NULL
                ELSE CONCAT(N'Duyệt=', d.approval_status) END,
           CONCAT(N'Hồ sơ=', CAST(i.record_id AS VARCHAR(10)),
                  N'; Duyệt=', i.approval_status,
                  N'; Lý do=', i.reason),
           ORIGINAL_LOGIN()
    FROM inserted i
    LEFT JOIN deleted d ON d.addendum_id = i.addendum_id;
END;
GO

/* ----------------------------------------------------------------------------
   TRG4: Chan sua/xoa chi tiet don thuoc khi don khong con DRAFT.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_prescription_items_block_issued
ON dbo.prescription_items
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM dbo.prescriptions p
        WHERE p.status <> 'DRAFT'
          AND ( p.prescription_id IN (SELECT prescription_id FROM inserted)
             OR p.prescription_id IN (SELECT prescription_id FROM deleted) )
    )
    BEGIN
        RAISERROR (N'Đơn thuốc đã phát hành: không sửa chi tiết trực tiếp.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ----------------------------------------------------------------------------
   TRG5: Tu dong danh co ket qua xet nghiem bat thuong.
   Bat thuong khi result_value nam ngoai [ref_low, ref_high] (chi xet phia
   co khai bao nguong). Ket qua dinh tinh (chi co result_text) khong danh co.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_lab_results_abnormal
ON dbo.lab_results
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE lr
    SET is_abnormal = CASE
            WHEN lr.result_value IS NOT NULL
             AND ( (lr.ref_low  IS NOT NULL AND lr.result_value < lr.ref_low)
                OR (lr.ref_high IS NOT NULL AND lr.result_value > lr.ref_high) )
            THEN 1 ELSE 0 END
    FROM dbo.lab_results lr
    JOIN inserted i ON i.result_id = lr.result_id;
END;
GO

/* ----------------------------------------------------------------------------
   TRG6: Dong bo booked_count cua ca kham theo so lich hen con hieu luc
   (BOOKED / CHECKED_IN / COMPLETED / NO_SHOW) va chan vuot suc chua.
   Day la nguon su that duy nhat cua booked_count - procedure khong tu tang.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_appointments_slot_guard
ON dbo.appointments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @affected TABLE (schedule_id INT PRIMARY KEY);
    INSERT INTO @affected (schedule_id)
    SELECT schedule_id FROM inserted
    UNION
    SELECT schedule_id FROM deleted;

    IF EXISTS (
        SELECT 1
        FROM @affected a
        JOIN dbo.doctor_schedules s ON s.schedule_id = a.schedule_id
        WHERE (SELECT COUNT(*) FROM dbo.appointments ap
               WHERE ap.schedule_id = a.schedule_id
                 AND ap.status IN ('BOOKED','CHECKED_IN','COMPLETED','NO_SHOW')) > s.slot_capacity
    )
    BEGIN
        RAISERROR (N'Ca khám đã hết slot: không thể thêm lịch hẹn.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE s
    SET booked_count = (SELECT COUNT(*) FROM dbo.appointments ap
                        WHERE ap.schedule_id = s.schedule_id
                          AND ap.status IN ('BOOKED','CHECKED_IN','COMPLETED','NO_SHOW'))
    FROM dbo.doctor_schedules s
    JOIN @affected a ON a.schedule_id = s.schedule_id;
END;
GO

/* ----------------------------------------------------------------------------
   TRG7: Chan lich lam viec chong lan cua cung 1 bac si trong cung 1 ngay
   (ke ca khac ca, neu khoang gio giao nhau) - bo sung cho UNIQUE theo ca.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_schedules_no_overlap
ON dbo.doctor_schedules
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.doctor_schedules other
          ON other.doctor_id = i.doctor_id
         AND other.work_date = i.work_date
         AND other.schedule_id <> i.schedule_id
         AND other.status <> 'CANCELLED'
         AND i.status <> 'CANCELLED'
         AND i.start_time < other.end_time
         AND other.start_time < i.end_time
    )
    BEGIN
        RAISERROR (N'Bác sĩ đã có lịch làm việc chồng lấn trong khoảng giờ này.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

PRINT N'06_triggers.sql: Da tao 7 triggers.';
GO
