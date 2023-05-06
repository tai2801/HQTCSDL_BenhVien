/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 08_tests.sql - Kich ban kiem thu rang buoc tren SQL Server.
   Moi test chay trong TRY/CATCH rieng, in ket qua dang:
       [PASS] TESTxx - mo ta
       [FAIL] TESTxx - mo ta | ly do
   Cac test dung du lieu tam trong transaction va ROLLBACK o cuoi moi test
   (hoac don dep bang DELETE) de khong lam ban du lieu mau.
   Chay sau khi da nap 01 -> 06.
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

DECLARE @pass INT = 0, @fail INT = 0;
PRINT N'=== MEDICORE CONSTRAINT TESTS ===';

-------------------------------------------------------------------------------
-- TEST01: Seed day du theo nguong toi thieu cua de bai
-------------------------------------------------------------------------------
BEGIN TRY
    IF (SELECT COUNT(*) FROM dbo.departments) < 6 THROW 50001, 'Thieu chuyen khoa', 1;
    IF (SELECT COUNT(*) FROM dbo.doctors) < 10 THROW 50002, 'Thieu bac si', 1;
    IF (SELECT COUNT(*) FROM dbo.patients) < 15 THROW 50003, 'Thieu benh nhan', 1;
    IF (SELECT COUNT(*) FROM dbo.visits) < 12 THROW 50004, 'Thieu lan kham', 1;
    SET @pass += 1; PRINT N'[PASS] TEST01 - Seed dat nguong toi thieu (khoa/bac si/benh nhan/lan kham)';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST01 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST02: CCCD trung bi UNIQUE chan
-------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO dbo.patients (patient_code, national_id, full_name, date_of_birth, gender)
    VALUES ('BN-TEST-DUP', (SELECT TOP 1 national_id FROM dbo.patients),
            N'Bệnh Nhân Trùng CCCD', '1990-01-01', 'MALE');
    ROLLBACK TRANSACTION;
    SET @fail += 1; PRINT N'[FAIL] TEST02 - CCCD trung van chen duoc';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @pass += 1; PRINT N'[PASS] TEST02 - UNIQUE chan CCCD trung';
END CATCH;

-------------------------------------------------------------------------------
-- TEST03: booked_count khong bao gio vuot slot_capacity (du lieu seed)
-------------------------------------------------------------------------------
BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.doctor_schedules WHERE booked_count > slot_capacity)
        THROW 50010, 'Co ca kham vuot suc chua', 1;
    SET @pass += 1; PRINT N'[PASS] TEST03 - booked_count <= slot_capacity tren toan bo ca kham';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST03 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST04: Dat lich vao ca da dong bi sp_book_appointment tu choi
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @closed_sched INT = (SELECT TOP 1 schedule_id FROM dbo.doctor_schedules WHERE status = 'CLOSED');
    DECLARE @any_patient INT = (SELECT TOP 1 patient_id FROM dbo.patients);
    DECLARE @new_id INT;
    EXEC dbo.sp_book_appointment @schedule_id = @closed_sched, @patient_id = @any_patient,
         @reason = N'Test dat lich ca dong', @new_appointment_id = @new_id OUTPUT;
    SET @fail += 1; PRINT N'[FAIL] TEST04 - Dat lich vao ca CLOSED van thanh cong';
END TRY
BEGIN CATCH
    SET @pass += 1; PRINT N'[PASS] TEST04 - sp_book_appointment chan dat lich vao ca da dong';
END CATCH;

-------------------------------------------------------------------------------
-- TEST05: Sua truc tiep ho so DA KHOA bi trigger chan
-------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.medical_records
    SET conclusion = N'Cố sửa hồ sơ đã khóa'
    WHERE record_id = (SELECT TOP 1 record_id FROM dbo.medical_records WHERE record_status = 'LOCKED');
    ROLLBACK TRANSACTION;
    SET @fail += 1; PRINT N'[FAIL] TEST05 - Sua duoc ho so da khoa';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @pass += 1; PRINT N'[PASS] TEST05 - Trigger chan sua ho so da khoa';
END CATCH;

-------------------------------------------------------------------------------
-- TEST06: Addendum cho ho so chua khoa bi tu choi; cho ho so da khoa thi duoc
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @draft_record INT = (SELECT TOP 1 record_id FROM dbo.medical_records WHERE record_status = 'DRAFT');
    DECLARE @doc INT = (SELECT TOP 1 doctor_id FROM dbo.medical_records WHERE record_id = @draft_record);
    DECLARE @add_id INT;
    EXEC dbo.sp_add_addendum @record_id = @draft_record, @author_doctor_id = @doc,
         @content = N'Nội dung test', @reason = N'Lý do test',
         @new_addendum_id = @add_id OUTPUT;
    SET @fail += 1; PRINT N'[FAIL] TEST06 - Tao duoc addendum cho ho so DRAFT';
END TRY
BEGIN CATCH
    SET @pass += 1; PRINT N'[PASS] TEST06 - sp_add_addendum tu choi ho so chua khoa';
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @locked_record INT = (SELECT TOP 1 record_id FROM dbo.medical_records WHERE record_status = 'LOCKED');
    DECLARE @locked_doc INT = (SELECT doctor_id FROM dbo.medical_records WHERE record_id = @locked_record);
    DECLARE @add_id2 INT;
    EXEC dbo.sp_add_addendum @record_id = @locked_record, @author_doctor_id = @locked_doc,
         @content = N'Bổ sung kết quả tái khám (test, sẽ rollback)', @reason = N'Test addendum',
         @new_addendum_id = @add_id2 OUTPUT;
    IF @add_id2 IS NULL THROW 50020, 'Khong tao duoc addendum', 1;
    ROLLBACK TRANSACTION;
    SET @pass += 1; PRINT N'[PASS] TEST07 - Tao addendum cho ho so da khoa thanh cong (PENDING)';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @fail += 1; PRINT N'[FAIL] TEST07 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST08: Co abnormal dung voi khoang tham chieu tren du lieu seed
-- (moi dong lab_results: is_abnormal phai bang ket qua danh gia lai thu cong)
-------------------------------------------------------------------------------
BEGIN TRY
    IF EXISTS (
        SELECT 1 FROM dbo.lab_results
        WHERE result_value IS NOT NULL
          AND is_abnormal <> CASE WHEN (ref_low IS NOT NULL AND result_value < ref_low)
                                    OR (ref_high IS NOT NULL AND result_value > ref_high)
                                  THEN 1 ELSE 0 END)
        THROW 50030, 'Co ket qua danh co abnormal sai', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.lab_results WHERE is_abnormal = 1)
        THROW 50031, 'Seed khong co ket qua bat thuong nao', 1;
    SET @pass += 1; PRINT N'[PASS] TEST08 - Co abnormal nhat quan voi khoang tham chieu, co ca bat thuong trong seed';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST08 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST09: Tong luong thuoc trong seed thoa cong thuc lieu x lan x ngay (CHECK)
-------------------------------------------------------------------------------
BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.prescription_items
               WHERE total_quantity <> dose_per_intake * intakes_per_day * duration_days)
        THROW 50040, 'Co dong don thuoc sai cong thuc tong luong', 1;
    SET @pass += 1; PRINT N'[PASS] TEST09 - Tong luong thuoc = lieu x lan/ngay x so ngay tren toan bo seed';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST09 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST10: Sua chi tiet don thuoc da ISSUED bi trigger chan
-------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.prescription_items
    SET duration_days = 99, total_quantity = dose_per_intake * intakes_per_day * 99
    WHERE item_id = (SELECT TOP 1 pi.item_id FROM dbo.prescription_items pi
                     JOIN dbo.prescriptions pr ON pr.prescription_id = pi.prescription_id
                     WHERE pr.status = 'ISSUED');
    ROLLBACK TRANSACTION;
    SET @fail += 1; PRINT N'[FAIL] TEST10 - Sua duoc chi tiet don da ISSUED';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @pass += 1; PRINT N'[PASS] TEST10 - Trigger chan sua chi tiet don thuoc da phat hanh';
END CATCH;

-------------------------------------------------------------------------------
-- TEST11: Toan ven hoa don - copay = gross - BHYT - giam gia; tong cac dong
-- invoice_items phai bang gross_total
-------------------------------------------------------------------------------
BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.invoices
               WHERE patient_copay <> gross_total - insurance_payable - discount_amount)
        THROW 50050, 'Co hoa don sai cong thuc dong chi tra', 1;
    IF EXISTS (
        SELECT inv.invoice_id FROM dbo.invoices inv
        JOIN dbo.invoice_items ii ON ii.invoice_id = inv.invoice_id
        GROUP BY inv.invoice_id, inv.gross_total
        HAVING SUM(ii.line_total) <> inv.gross_total)
        THROW 50051, 'Tong dong hoa don khac gross_total', 1;
    SET @pass += 1; PRINT N'[PASS] TEST11 - Hoa don nhat quan: copay va tong dong = gross_total';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST11 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST12: Hoa don trai tuyen co muc huong hieu luc = 40% muc tren the
-------------------------------------------------------------------------------
BEGIN TRY
    IF EXISTS (
        SELECT 1 FROM dbo.invoices
        WHERE referral_type = 'WRONG' AND coverage_percent_snapshot IS NOT NULL
          AND ABS(effective_coverage_percent - ROUND(coverage_percent_snapshot * 0.4, 2)) > 0.01)
        THROW 50060, 'Co hoa don trai tuyen tinh sai muc huong hieu luc', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.invoices WHERE referral_type = 'WRONG')
        THROW 50061, 'Seed khong co hoa don trai tuyen de kiem tra', 1;
    SET @pass += 1; PRINT N'[PASS] TEST12 - Trai tuyen: muc huong hieu luc = 40% muc huong tren the';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST12 - ' + ERROR_MESSAGE();
END CATCH;

-------------------------------------------------------------------------------
-- TEST13: Thanh toan vuot phan con phai tra bi sp_pay_invoice tu choi
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @inv INT = (SELECT TOP 1 invoice_id FROM dbo.invoices WHERE status = 'ISSUED');
    IF @inv IS NOT NULL
        EXEC dbo.sp_pay_invoice @invoice_id = @inv, @payer_type = 'PATIENT',
             @amount = 999999999, @payment_method = 'CASH', @received_by = N'Test';
    SET @fail += 1; PRINT N'[FAIL] TEST13 - Thanh toan vuot muc van duoc chap nhan (hoac khong co hoa don ISSUED)';
END TRY
BEGIN CATCH
    SET @pass += 1; PRINT N'[PASS] TEST13 - sp_pay_invoice chan thanh toan vuot phan con phai tra';
END CATCH;

-------------------------------------------------------------------------------
-- TEST14: Audit log da ghi nhan thao tac (seed co addendum duoc duyet)
-------------------------------------------------------------------------------
BEGIN TRY
    IF NOT EXISTS (SELECT 1 FROM dbo.record_addenda WHERE approval_status = 'APPROVED')
        THROW 50070, 'Seed thieu addendum da duyet', 1;
    SET @pass += 1; PRINT N'[PASS] TEST14 - Quy trinh addendum: co phu luc o trang thai APPROVED trong seed';
END TRY
BEGIN CATCH
    SET @fail += 1; PRINT N'[FAIL] TEST14 - ' + ERROR_MESSAGE();
END CATCH;

PRINT CONCAT(N'=== KET QUA: ', @pass, N' PASS / ', @fail, N' FAIL ===');
GO
