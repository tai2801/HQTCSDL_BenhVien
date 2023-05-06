/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 05_procedures.sql - Stored procedures nghiep vu (CREATE OR ALTER)
   Quy uoc: moi procedure dung TRY/CATCH + transaction khi sua nhieu bang,
   loi nghiep vu dung THROW voi ma 500xx de ung dung bat duoc.
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

/* ----------------------------------------------------------------------------
   SP1: sp_book_appointment - Dat lich kham.
   Kiem tra: ca con OPEN, con slot trong, benh nhan chua dat chinh ca nay.
   booked_count duoc trigger dong bo sau INSERT (procedure khong tu tang).
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_book_appointment
    @schedule_id INT,
    @patient_id  INT,
    @reason      NVARCHAR(250) = NULL,
    @new_appointment_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @capacity INT, @booked INT, @status VARCHAR(12), @work_date DATE;
        SELECT @capacity = slot_capacity, @booked = booked_count,
               @status = status, @work_date = work_date
        FROM dbo.doctor_schedules WITH (UPDLOCK, HOLDLOCK)
        WHERE schedule_id = @schedule_id;

        IF @capacity IS NULL
            THROW 50001, N'Không tìm thấy ca khám.', 1;
        IF @status <> 'OPEN'
            THROW 50002, N'Ca khám không còn mở để đặt lịch.', 1;
        IF @work_date < CAST(SYSDATETIME() AS DATE)
            THROW 50003, N'Không đặt lịch cho ngày đã qua.', 1;
        IF @booked >= @capacity
            THROW 50004, N'Ca khám đã hết slot.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.patients WHERE patient_id = @patient_id)
            THROW 50005, N'Không tìm thấy bệnh nhân.', 1;
        IF EXISTS (SELECT 1 FROM dbo.appointments
                   WHERE schedule_id = @schedule_id AND patient_id = @patient_id
                     AND status IN ('BOOKED','CHECKED_IN'))
            THROW 50006, N'Bệnh nhân đã có lịch hẹn trong ca này.', 1;

        DECLARE @seq INT = ISNULL((SELECT MAX(appointment_id) FROM dbo.appointments), 0) + 1;
        INSERT INTO dbo.appointments (appointment_no, schedule_id, patient_id, reason, status)
        VALUES (CONCAT('LH', FORMAT(@work_date, 'yyyy'), '-', FORMAT(@seq, '0000')),
                @schedule_id, @patient_id, @reason, 'BOOKED');
        SET @new_appointment_id = SCOPE_IDENTITY();

        /* booked_count do trigger trg_appointments_slot_guard dong bo
           (nguon su that duy nhat) - procedure khong tu tang de tranh dem 2 lan. */
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   SP2: sp_check_in_appointment - Tiep don xac nhan benh nhan den kham,
   tao lan kham (visit) + ho so benh an DRAFT tuong ung.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_check_in_appointment
    @appointment_id INT,
    @new_visit_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @patient_id INT, @schedule_id INT, @status VARCHAR(12);
        SELECT @patient_id = patient_id, @schedule_id = schedule_id, @status = status
        FROM dbo.appointments WITH (UPDLOCK, HOLDLOCK)
        WHERE appointment_id = @appointment_id;

        IF @patient_id IS NULL
            THROW 50010, N'Không tìm thấy lịch hẹn.', 1;
        IF @status <> 'BOOKED'
            THROW 50011, N'Chỉ check-in được lịch hẹn ở trạng thái BOOKED.', 1;

        DECLARE @doctor_id INT, @room_id INT, @work_date DATE, @reason NVARCHAR(250);
        SELECT @doctor_id = doctor_id, @room_id = room_id, @work_date = work_date
        FROM dbo.doctor_schedules WHERE schedule_id = @schedule_id;
        SELECT @reason = reason FROM dbo.appointments WHERE appointment_id = @appointment_id;

        DECLARE @vseq INT = ISNULL((SELECT MAX(visit_id) FROM dbo.visits), 0) + 1;
        INSERT INTO dbo.visits (visit_code, patient_id, appointment_id, doctor_id, room_id,
                                visit_date, chief_complaint, status, started_at)
        VALUES (CONCAT('LK', FORMAT(@work_date, 'yyyy'), '-', FORMAT(@vseq, '0000')),
                @patient_id, @appointment_id, @doctor_id, @room_id,
                @work_date, @reason, 'IN_PROGRESS', SYSDATETIME());
        SET @new_visit_id = SCOPE_IDENTITY();

        INSERT INTO dbo.medical_records (visit_id, patient_id, doctor_id)
        VALUES (@new_visit_id, @patient_id, @doctor_id);

        UPDATE dbo.appointments
        SET status = 'CHECKED_IN', checked_in_at = SYSDATETIME()
        WHERE appointment_id = @appointment_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   SP3: sp_lock_medical_record - Khoa ho so benh an.
   Chi khoa duoc khi: ho so dang DRAFT, lan kham da COMPLETED,
   co it nhat 1 chan doan chinh va co ket luan.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_lock_medical_record
    @record_id INT,
    @locked_by_doctor_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @status VARCHAR(10), @visit_id INT, @conclusion NVARCHAR(1000);
        SELECT @status = record_status, @visit_id = visit_id, @conclusion = conclusion
        FROM dbo.medical_records WITH (UPDLOCK, HOLDLOCK)
        WHERE record_id = @record_id;

        IF @status IS NULL
            THROW 50020, N'Không tìm thấy hồ sơ bệnh án.', 1;
        IF @status = 'LOCKED'
            THROW 50021, N'Hồ sơ đã khóa trước đó.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.visits WHERE visit_id = @visit_id AND status = 'COMPLETED')
            THROW 50022, N'Chỉ khóa hồ sơ khi lần khám đã hoàn tất (COMPLETED).', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.diagnoses WHERE visit_id = @visit_id AND diagnosis_type = 'PRIMARY')
            THROW 50023, N'Hồ sơ phải có ít nhất 1 chẩn đoán chính trước khi khóa.', 1;
        IF NULLIF(LTRIM(RTRIM(@conclusion)), '') IS NULL
            THROW 50024, N'Hồ sơ phải có kết luận trước khi khóa.', 1;

        UPDATE dbo.medical_records
        SET record_status = 'LOCKED',
            locked_by = @locked_by_doctor_id,
            locked_at = SYSDATETIME(),
            updated_at = SYSDATETIME()
        WHERE record_id = @record_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   SP4: sp_add_addendum - Bo sung phu luc cho ho so DA KHOA.
   Ho so dang DRAFT thi sua truc tiep, khong can addendum -> tu choi.
   Addendum moi o trang thai PENDING, phai duoc duyet moi co gia tri.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_add_addendum
    @record_id INT,
    @author_doctor_id INT,
    @content NVARCHAR(4000),
    @reason NVARCHAR(500),
    @new_addendum_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status VARCHAR(10);
    SELECT @status = record_status FROM dbo.medical_records WHERE record_id = @record_id;

    IF @status IS NULL
        THROW 50030, N'Không tìm thấy hồ sơ bệnh án.', 1;
    IF @status <> 'LOCKED'
        THROW 50031, N'Hồ sơ chưa khóa: hãy sửa trực tiếp, không tạo phụ lục.', 1;
    IF NULLIF(LTRIM(RTRIM(@reason)), '') IS NULL
        THROW 50032, N'Phụ lục bắt buộc ghi lý do bổ sung.', 1;

    INSERT INTO dbo.record_addenda (record_id, author_doctor_id, content, reason, approval_status)
    VALUES (@record_id, @author_doctor_id, @content, @reason, 'PENDING');
    SET @new_addendum_id = SCOPE_IDENTITY();
END;
GO

/* ----------------------------------------------------------------------------
   SP5: sp_approve_addendum - Duyet / tu choi phu luc.
   Nguoi duyet khong duoc la chinh tac gia cua phu luc.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_approve_addendum
    @addendum_id INT,
    @approver_doctor_id INT,
    @approve BIT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status VARCHAR(10), @author INT;
    SELECT @status = approval_status, @author = author_doctor_id
    FROM dbo.record_addenda WHERE addendum_id = @addendum_id;

    IF @status IS NULL
        THROW 50040, N'Không tìm thấy phụ lục.', 1;
    IF @status <> 'PENDING'
        THROW 50041, N'Phụ lục đã được xử lý trước đó.', 1;
    IF @author = @approver_doctor_id
        THROW 50042, N'Người duyệt không được là tác giả của phụ lục.', 1;

    UPDATE dbo.record_addenda
    SET approval_status = CASE WHEN @approve = 1 THEN 'APPROVED' ELSE 'REJECTED' END,
        approved_by = @approver_doctor_id,
        approved_at = SYSDATETIME()
    WHERE addendum_id = @addendum_id;
END;
GO

/* ----------------------------------------------------------------------------
   SP6: sp_add_prescription_item - Them 1 dong thuoc vao don DRAFT.
   Validate: don phai DRAFT; kiem tra DI UNG theo hoat chat/ten thuoc;
   tong so luong = lieu x lan/ngay x so ngay (tinh o day, CHECK xac nhan lai).
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_add_prescription_item
    @prescription_id INT,
    @medication_id INT,
    @dose_per_intake DECIMAL(6,2),
    @intakes_per_day INT,
    @duration_days INT,
    @instructions NVARCHAR(250) = NULL,
    @new_item_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @status VARCHAR(12), @visit_id INT;
    SELECT @status = status, @visit_id = visit_id
    FROM dbo.prescriptions WHERE prescription_id = @prescription_id;

    IF @status IS NULL
        THROW 50050, N'Không tìm thấy đơn thuốc.', 1;
    IF @status <> 'DRAFT'
        THROW 50051, N'Đơn thuốc đã phát hành: không sửa chi tiết trực tiếp. Hãy hủy đơn và tạo đơn mới.', 1;

    DECLARE @med_name NVARCHAR(200), @ingredient NVARCHAR(200), @patient_id INT;
    SELECT @med_name = medication_name, @ingredient = active_ingredient
    FROM dbo.medications WHERE medication_id = @medication_id AND is_active = 1;
    IF @med_name IS NULL
        THROW 50052, N'Thuốc không tồn tại hoặc đã ngừng sử dụng.', 1;

    SELECT @patient_id = patient_id FROM dbo.visits WHERE visit_id = @visit_id;

    /* Chan ke thuoc ma benh nhan da ghi nhan di ung (khop theo ten/hoat chat) */
    IF EXISTS (
        SELECT 1 FROM dbo.patient_allergies pa
        WHERE pa.patient_id = @patient_id
          AND ( @med_name LIKE '%' + pa.allergen + '%'
             OR @ingredient LIKE '%' + pa.allergen + '%'
             OR pa.allergen LIKE '%' + @ingredient + '%' )
    )
        THROW 50053, N'CẢNH BÁO DỊ ỨNG: bệnh nhân có tiền sử dị ứng với thuốc/hoạt chất này.', 1;

    DECLARE @total DECIMAL(10,2) = @dose_per_intake * @intakes_per_day * @duration_days;
    INSERT INTO dbo.prescription_items
        (prescription_id, medication_id, dose_per_intake, intakes_per_day, duration_days, total_quantity, instructions)
    VALUES (@prescription_id, @medication_id, @dose_per_intake, @intakes_per_day, @duration_days, @total, @instructions);
    SET @new_item_id = SCOPE_IDENTITY();
END;
GO

/* ----------------------------------------------------------------------------
   SP7: sp_record_lab_result - Nhap 1 thong so ket qua xet nghiem.
   Co abnormal do trigger trg_lab_results_abnormal danh gia tu dong.
   Sau khi co ket qua dau tien, chi dinh chuyen trang thai RESULTED.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_record_lab_result
    @lab_order_id INT,
    @parameter_code VARCHAR(20),
    @parameter_name NVARCHAR(120),
    @result_value DECIMAL(12,3) = NULL,
    @result_text NVARCHAR(250) = NULL,
    @unit VARCHAR(20) = NULL,
    @ref_low DECIMAL(12,3) = NULL,
    @ref_high DECIMAL(12,3) = NULL,
    @resulted_by NVARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @status VARCHAR(12);
        SELECT @status = status FROM dbo.lab_orders WITH (UPDLOCK, HOLDLOCK)
        WHERE lab_order_id = @lab_order_id;

        IF @status IS NULL
            THROW 50060, N'Không tìm thấy chỉ định xét nghiệm.', 1;
        IF @status IN ('VERIFIED','CANCELLED')
            THROW 50061, N'Chỉ định đã duyệt kết quả hoặc đã hủy: không nhập thêm kết quả.', 1;
        IF @result_value IS NULL AND NULLIF(LTRIM(RTRIM(@result_text)), '') IS NULL
            THROW 50062, N'Kết quả phải có giá trị số hoặc kết quả định tính.', 1;

        INSERT INTO dbo.lab_results
            (lab_order_id, parameter_code, parameter_name, result_value, result_text,
             unit, ref_low, ref_high, resulted_by)
        VALUES (@lab_order_id, @parameter_code, @parameter_name, @result_value, @result_text,
                @unit, @ref_low, @ref_high, @resulted_by);

        IF @status IN ('ORDERED','COLLECTED')
            UPDATE dbo.lab_orders SET status = 'RESULTED' WHERE lab_order_id = @lab_order_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   SP8: sp_calculate_invoice - Lap hoa don vien phi cho 1 lan kham.
   Nguon so lieu (snapshot gia tai thoi diem lap):
     - Dich vu: visit_services trang thai DONE
     - Xet nghiem: lab_orders trang thai RESULTED / VERIFIED
     - Thuoc: cac don ISSUED / DISPENSED cua lan kham
   BHYT (quy tac mo phong cua du an - xem DESIGN_NOTES.md):
     - Dung tuyen (CORRECT) hoac cap cuu (EMERGENCY): huong nguyen muc tren the
     - Trai tuyen ngoai tru (WRONG): huong 40% cua muc tren the
     - Chi ap dung cho dong du dieu kien BHYT (is_insurance_eligible = 1)
     - The het han vao ngay kham -> coi nhu khong co the
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_calculate_invoice
    @visit_id INT,
    @referral_type VARCHAR(15) = 'CORRECT',
    @new_invoice_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @patient_id INT, @visit_date DATE, @visit_status VARCHAR(12);
        SELECT @patient_id = patient_id, @visit_date = visit_date, @visit_status = status
        FROM dbo.visits WITH (UPDLOCK, HOLDLOCK) WHERE visit_id = @visit_id;

        IF @patient_id IS NULL
            THROW 50070, N'Không tìm thấy lần khám.', 1;
        IF @visit_status <> 'COMPLETED'
            THROW 50071, N'Chỉ lập hóa đơn khi lần khám đã hoàn tất.', 1;
        IF EXISTS (SELECT 1 FROM dbo.invoices WHERE visit_id = @visit_id AND status <> 'CANCELLED')
            THROW 50072, N'Lần khám này đã có hóa đơn.', 1;
        IF @referral_type NOT IN ('CORRECT','WRONG','EMERGENCY')
            THROW 50073, N'Loại tuyến khám không hợp lệ.', 1;

        DECLARE @insurance_id INT, @coverage DECIMAL(5,2);
        SELECT TOP (1) @insurance_id = insurance_id, @coverage = coverage_percent
        FROM dbo.insurance_cards
        WHERE patient_id = @patient_id AND is_primary = 1
          AND valid_from <= @visit_date AND valid_to >= @visit_date
        ORDER BY valid_to DESC;

        DECLARE @effective DECIMAL(5,2) =
            CASE WHEN @insurance_id IS NULL THEN 0
                 WHEN @referral_type = 'WRONG' THEN ROUND(@coverage * 0.4, 2)
                 ELSE @coverage END;

        DECLARE @iseq INT = ISNULL((SELECT MAX(invoice_id) FROM dbo.invoices), 0) + 1;
        INSERT INTO dbo.invoices
            (invoice_no, visit_id, patient_id, insurance_id, referral_type,
             coverage_percent_snapshot, effective_coverage_percent,
             insurance_claim_status, status, issued_at, due_date)
        VALUES (CONCAT('HD', FORMAT(@visit_date, 'yyyy'), '-', FORMAT(@iseq, '0000')),
                @visit_id, @patient_id, @insurance_id, @referral_type,
                @coverage, @effective,
                CASE WHEN @insurance_id IS NULL THEN 'NOT_SENT' ELSE 'SENT' END,
                'ISSUED', SYSDATETIME(), DATEADD(DAY, 7, @visit_date));
        SET @new_invoice_id = SCOPE_IDENTITY();

        /* Dong dich vu */
        INSERT INTO dbo.invoice_items (invoice_id, item_type, source_id, description, quantity, unit_price, line_total, is_insurance_eligible)
        SELECT @new_invoice_id, 'SERVICE', vs.visit_service_id, s.service_name,
               vs.quantity, vs.unit_price_snapshot, vs.quantity * vs.unit_price_snapshot,
               s.is_insurance_covered
        FROM dbo.visit_services vs
        JOIN dbo.medical_services s ON s.service_id = vs.service_id
        WHERE vs.visit_id = @visit_id AND vs.status = 'DONE';

        /* Dong xet nghiem */
        INSERT INTO dbo.invoice_items (invoice_id, item_type, source_id, description, quantity, unit_price, line_total, is_insurance_eligible)
        SELECT @new_invoice_id, 'LAB', lo.lab_order_id, s.service_name,
               1, s.unit_price, s.unit_price, s.is_insurance_covered
        FROM dbo.lab_orders lo
        JOIN dbo.medical_services s ON s.service_id = lo.service_id
        WHERE lo.visit_id = @visit_id AND lo.status IN ('RESULTED','VERIFIED');

        /* Dong thuoc */
        INSERT INTO dbo.invoice_items (invoice_id, item_type, source_id, description, quantity, unit_price, line_total, is_insurance_eligible)
        SELECT @new_invoice_id, 'MED', pi.item_id, m.medication_name,
               pi.total_quantity, m.unit_price, pi.total_quantity * m.unit_price,
               m.is_insurance_covered
        FROM dbo.prescriptions pr
        JOIN dbo.prescription_items pi ON pi.prescription_id = pr.prescription_id
        JOIN dbo.medications m ON m.medication_id = pi.medication_id
        WHERE pr.visit_id = @visit_id AND pr.status IN ('ISSUED','DISPENSED');

        /* Tong hop tien */
        DECLARE @svc DECIMAL(18,2), @lab DECIMAL(18,2), @med DECIMAL(18,2), @eligible DECIMAL(18,2);
        SELECT
            @svc = SUM(CASE WHEN item_type = 'SERVICE' THEN line_total ELSE 0 END),
            @lab = SUM(CASE WHEN item_type = 'LAB' THEN line_total ELSE 0 END),
            @med = SUM(CASE WHEN item_type = 'MED' THEN line_total ELSE 0 END),
            @eligible = SUM(CASE WHEN is_insurance_eligible = 1 THEN line_total ELSE 0 END)
        FROM dbo.invoice_items WHERE invoice_id = @new_invoice_id;

        SET @svc = ISNULL(@svc, 0); SET @lab = ISNULL(@lab, 0);
        SET @med = ISNULL(@med, 0); SET @eligible = ISNULL(@eligible, 0);

        DECLARE @gross DECIMAL(18,2) = @svc + @lab + @med;
        DECLARE @ins_pay DECIMAL(18,2) = ROUND(@eligible * @effective / 100.0, 2);

        UPDATE dbo.invoices
        SET services_total = @svc, labs_total = @lab, meds_total = @med,
            gross_total = @gross, insurance_payable = @ins_pay,
            patient_copay = @gross - @ins_pay - discount_amount
        WHERE invoice_id = @new_invoice_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ----------------------------------------------------------------------------
   SP9: sp_pay_invoice - Ghi nhan thanh toan cho hoa don.
   Chan tra vuot phan con phai tra cua dung ben tra (benh nhan / BHYT);
   cap nhat trang thai hoa don ISSUED -> PARTIALLY_PAID -> PAID.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_pay_invoice
    @invoice_id INT,
    @payer_type VARCHAR(12),
    @amount DECIMAL(18,2),
    @payment_method VARCHAR(15),
    @transaction_ref VARCHAR(50) = NULL,
    @received_by NVARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @status VARCHAR(15), @copay DECIMAL(18,2), @ins_pay DECIMAL(18,2);
        SELECT @status = status, @copay = patient_copay, @ins_pay = insurance_payable
        FROM dbo.invoices WITH (UPDLOCK, HOLDLOCK) WHERE invoice_id = @invoice_id;

        IF @status IS NULL
            THROW 50080, N'Không tìm thấy hóa đơn.', 1;
        IF @status IN ('PAID','CANCELLED','DRAFT')
            THROW 50081, N'Hóa đơn không ở trạng thái có thể thanh toán.', 1;
        IF @amount <= 0
            THROW 50082, N'Số tiền thanh toán phải lớn hơn 0.', 1;
        IF @payer_type NOT IN ('PATIENT','INSURANCE')
            THROW 50083, N'Bên thanh toán không hợp lệ.', 1;

        DECLARE @due DECIMAL(18,2) = CASE WHEN @payer_type = 'PATIENT' THEN @copay ELSE @ins_pay END;
        DECLARE @paid DECIMAL(18,2) = ISNULL((
            SELECT SUM(amount) FROM dbo.payments
            WHERE invoice_id = @invoice_id AND payer_type = @payer_type AND status = 'COMPLETED'), 0);

        IF @paid + @amount > @due
            THROW 50084, N'Số tiền vượt quá phần còn phải trả của bên thanh toán này.', 1;

        INSERT INTO dbo.payments (invoice_id, payer_type, amount, payment_method, transaction_ref, received_by)
        VALUES (@invoice_id, @payer_type, @amount, @payment_method, @transaction_ref, @received_by);

        DECLARE @patient_paid DECIMAL(18,2) = ISNULL((
            SELECT SUM(amount) FROM dbo.payments
            WHERE invoice_id = @invoice_id AND payer_type = 'PATIENT' AND status = 'COMPLETED'), 0);
        DECLARE @ins_paid DECIMAL(18,2) = ISNULL((
            SELECT SUM(amount) FROM dbo.payments
            WHERE invoice_id = @invoice_id AND payer_type = 'INSURANCE' AND status = 'COMPLETED'), 0);

        UPDATE dbo.invoices
        SET status = CASE
                WHEN @patient_paid >= @copay AND @ins_paid >= @ins_pay THEN 'PAID'
                ELSE 'PARTIALLY_PAID' END
        WHERE invoice_id = @invoice_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT N'05_procedures.sql: Da tao 9 stored procedures.';
GO
