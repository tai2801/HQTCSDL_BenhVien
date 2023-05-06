/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 01_schema.sql - Tao database va toan bo bang (T-SQL, SQL Server 2019+)
   Thiet ke boi Nhom 2 - HUIT. Idempotent: chay lai duoc.
   Thu tu chay: 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08
   ============================================================================ */
SET NOCOUNT ON;
GO

IF DB_ID(N'MediCoreDB') IS NULL
BEGIN
    CREATE DATABASE MediCoreDB;
END;
GO

ALTER DATABASE MediCoreDB SET RECOVERY SIMPLE;
GO

USE MediCoreDB;
GO

/* ----------------------------------------------------------------------------
   1) departments - Chuyen khoa
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.departments', N'U') IS NULL
CREATE TABLE dbo.departments (
    department_id   INT IDENTITY(1,1)   NOT NULL,
    department_code VARCHAR(10)         NOT NULL,
    department_name NVARCHAR(120)       NOT NULL,
    description     NVARCHAR(500)       NULL,
    is_active       BIT                 NOT NULL CONSTRAINT DF_departments_active DEFAULT (1),
    CONSTRAINT PK_departments PRIMARY KEY (department_id),
    CONSTRAINT UQ_departments_code UNIQUE (department_code)
);
GO

/* ----------------------------------------------------------------------------
   2) app_users - Tai khoan he thong (chi luu hash, khong luu mat khau tho)
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.app_users', N'U') IS NULL
CREATE TABLE dbo.app_users (
    user_id       INT IDENTITY(1,1)   NOT NULL,
    username      VARCHAR(50)         NOT NULL,
    password_hash VARCHAR(255)        NOT NULL,
    full_name     NVARCHAR(120)       NOT NULL,
    role_code     VARCHAR(20)         NOT NULL,
    is_active     BIT                 NOT NULL CONSTRAINT DF_users_active DEFAULT (1),
    created_at    DATETIME2(0)        NOT NULL CONSTRAINT DF_users_created DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_app_users PRIMARY KEY (user_id),
    CONSTRAINT UQ_app_users_username UNIQUE (username),
    CONSTRAINT CK_app_users_role CHECK (role_code IN
        ('ADMIN','DOCTOR','NURSE','LAB_TECH','CASHIER','RECEPTIONIST'))
);
GO

/* ----------------------------------------------------------------------------
   3) doctors - Bac si
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.doctors', N'U') IS NULL
CREATE TABLE dbo.doctors (
    doctor_id     INT IDENTITY(1,1)   NOT NULL,
    user_id       INT                 NULL,
    department_id INT                 NOT NULL,
    full_name     NVARCHAR(120)       NOT NULL,
    title         NVARCHAR(60)        NULL,           -- VD: BS.CKI, ThS.BS
    license_no    VARCHAR(20)         NOT NULL,       -- So chung chi hanh nghe
    phone         VARCHAR(15)         NULL,
    email         VARCHAR(120)        NULL,
    is_active     BIT                 NOT NULL CONSTRAINT DF_doctors_active DEFAULT (1),
    CONSTRAINT PK_doctors PRIMARY KEY (doctor_id),
    CONSTRAINT UQ_doctors_license UNIQUE (license_no),
    CONSTRAINT FK_doctors_user FOREIGN KEY (user_id) REFERENCES dbo.app_users (user_id),
    CONSTRAINT FK_doctors_department FOREIGN KEY (department_id) REFERENCES dbo.departments (department_id)
);
GO

/* ----------------------------------------------------------------------------
   4) rooms - Phong kham
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.rooms', N'U') IS NULL
CREATE TABLE dbo.rooms (
    room_id       INT IDENTITY(1,1)   NOT NULL,
    room_code     VARCHAR(10)         NOT NULL,
    room_name     NVARCHAR(120)       NOT NULL,
    department_id INT                 NOT NULL,
    floor_no      INT                 NOT NULL CONSTRAINT DF_rooms_floor DEFAULT (1),
    is_active     BIT                 NOT NULL CONSTRAINT DF_rooms_active DEFAULT (1),
    CONSTRAINT PK_rooms PRIMARY KEY (room_id),
    CONSTRAINT UQ_rooms_code UNIQUE (room_code),
    CONSTRAINT FK_rooms_department FOREIGN KEY (department_id) REFERENCES dbo.departments (department_id)
);
GO

/* ----------------------------------------------------------------------------
   5) patients - Ho so dinh danh benh nhan (1 nguoi = 1 ho so, dung chung
      cho moi lan kham). CCCD la dinh danh duy nhat cap quoc gia.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.patients', N'U') IS NULL
CREATE TABLE dbo.patients (
    patient_id    INT IDENTITY(1,1)   NOT NULL,
    patient_code  VARCHAR(15)         NOT NULL,       -- VD: BN2023-0001
    national_id   VARCHAR(12)         NOT NULL,       -- CCCD 12 so
    full_name     NVARCHAR(120)       NOT NULL,
    date_of_birth DATE                NOT NULL,
    gender        VARCHAR(6)          NOT NULL,
    phone         VARCHAR(15)         NULL,
    email         VARCHAR(120)        NULL,
    address       NVARCHAR(250)       NULL,
    blood_type    VARCHAR(5)          NULL,
    created_at    DATETIME2(0)        NOT NULL CONSTRAINT DF_patients_created DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_patients PRIMARY KEY (patient_id),
    CONSTRAINT UQ_patients_code UNIQUE (patient_code),
    CONSTRAINT UQ_patients_national_id UNIQUE (national_id),
    CONSTRAINT CK_patients_gender CHECK (gender IN ('MALE','FEMALE','OTHER')),
    CONSTRAINT CK_patients_dob CHECK (date_of_birth <= CAST(SYSDATETIME() AS DATE))
);
GO

/* ----------------------------------------------------------------------------
   6) patient_allergies - Di ung cua benh nhan (kiem tra khi ke don)
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.patient_allergies', N'U') IS NULL
CREATE TABLE dbo.patient_allergies (
    allergy_id   INT IDENTITY(1,1)   NOT NULL,
    patient_id   INT                 NOT NULL,
    allergen     NVARCHAR(120)       NOT NULL,        -- Ten thuoc / tac nhan
    reaction     NVARCHAR(250)       NULL,
    severity     VARCHAR(10)         NOT NULL CONSTRAINT DF_allergy_sev DEFAULT ('MODERATE'),
    recorded_at  DATETIME2(0)        NOT NULL CONSTRAINT DF_allergy_time DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_patient_allergies PRIMARY KEY (allergy_id),
    CONSTRAINT FK_allergy_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT CK_allergy_severity CHECK (severity IN ('MILD','MODERATE','SEVERE'))
);
GO

/* ----------------------------------------------------------------------------
   7) insurance_cards - The BHYT cua benh nhan
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.insurance_cards', N'U') IS NULL
CREATE TABLE dbo.insurance_cards (
    insurance_id      INT IDENTITY(1,1)  NOT NULL,
    patient_id        INT                NOT NULL,
    card_no           VARCHAR(20)        NOT NULL,
    insurer_name      NVARCHAR(150)      NOT NULL CONSTRAINT DF_insurer DEFAULT (N'Bảo hiểm Xã hội Việt Nam'),
    coverage_percent  DECIMAL(5,2)       NOT NULL,    -- Muc huong ghi tren the: 80 / 95 / 100
    registered_facility NVARCHAR(200)    NULL,        -- Noi dang ky KCB ban dau
    valid_from        DATE               NOT NULL,
    valid_to          DATE               NOT NULL,
    is_primary        BIT                NOT NULL CONSTRAINT DF_ins_primary DEFAULT (1),
    CONSTRAINT PK_insurance_cards PRIMARY KEY (insurance_id),
    CONSTRAINT UQ_insurance_card_no UNIQUE (card_no),
    CONSTRAINT FK_insurance_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT CK_insurance_coverage CHECK (coverage_percent > 0 AND coverage_percent <= 100),
    CONSTRAINT CK_insurance_valid CHECK (valid_to >= valid_from)
);
GO

/* ----------------------------------------------------------------------------
   8) doctor_schedules - Lich lam viec cua bac si theo ca.
      UNIQUE bac si + ngay + ca va phong + ngay + ca: chan trung lich o muc
      du lieu; trigger trg_schedules_no_overlap chan ca chong lan gio.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.doctor_schedules', N'U') IS NULL
CREATE TABLE dbo.doctor_schedules (
    schedule_id   INT IDENTITY(1,1)   NOT NULL,
    doctor_id     INT                 NOT NULL,
    room_id       INT                 NOT NULL,
    work_date     DATE                NOT NULL,
    shift_code    VARCHAR(10)         NOT NULL,       -- MORNING / AFTERNOON / EVENING
    start_time    TIME                NOT NULL,
    end_time      TIME                NOT NULL,
    slot_capacity INT                 NOT NULL,
    booked_count  INT                 NOT NULL CONSTRAINT DF_sched_booked DEFAULT (0),
    status        VARCHAR(12)         NOT NULL CONSTRAINT DF_sched_status DEFAULT ('OPEN'),
    CONSTRAINT PK_doctor_schedules PRIMARY KEY (schedule_id),
    CONSTRAINT FK_sched_doctor FOREIGN KEY (doctor_id) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT FK_sched_room FOREIGN KEY (room_id) REFERENCES dbo.rooms (room_id),
    CONSTRAINT UQ_sched_doctor_shift UNIQUE (doctor_id, work_date, shift_code),
    CONSTRAINT UQ_sched_room_shift UNIQUE (room_id, work_date, shift_code),
    CONSTRAINT CK_sched_shift CHECK (shift_code IN ('MORNING','AFTERNOON','EVENING')),
    CONSTRAINT CK_sched_status CHECK (status IN ('OPEN','CLOSED','CANCELLED')),
    CONSTRAINT CK_sched_time CHECK (end_time > start_time),
    CONSTRAINT CK_sched_capacity CHECK (slot_capacity > 0 AND booked_count >= 0 AND booked_count <= slot_capacity)
);
GO

/* ----------------------------------------------------------------------------
   9) appointments - Lich hen cua benh nhan trong 1 ca kham
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.appointments', N'U') IS NULL
CREATE TABLE dbo.appointments (
    appointment_id INT IDENTITY(1,1)   NOT NULL,
    appointment_no VARCHAR(15)         NOT NULL,      -- VD: LH2023-0001
    schedule_id    INT                 NOT NULL,
    patient_id     INT                 NOT NULL,
    reason         NVARCHAR(250)       NULL,
    status         VARCHAR(12)         NOT NULL CONSTRAINT DF_appt_status DEFAULT ('BOOKED'),
    booked_at      DATETIME2(0)        NOT NULL CONSTRAINT DF_appt_booked DEFAULT (SYSDATETIME()),
    checked_in_at  DATETIME2(0)        NULL,
    CONSTRAINT PK_appointments PRIMARY KEY (appointment_id),
    CONSTRAINT UQ_appointments_no UNIQUE (appointment_no),
    CONSTRAINT UQ_appointments_patient_schedule UNIQUE (schedule_id, patient_id),
    CONSTRAINT FK_appt_schedule FOREIGN KEY (schedule_id) REFERENCES dbo.doctor_schedules (schedule_id),
    CONSTRAINT FK_appt_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT CK_appt_status CHECK (status IN ('BOOKED','CHECKED_IN','CANCELLED','NO_SHOW','COMPLETED'))
);
GO

/* ----------------------------------------------------------------------------
   10) visits - Mot LAN KHAM (encounter). Moi lan kham sinh 1 ho so benh an.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.visits', N'U') IS NULL
CREATE TABLE dbo.visits (
    visit_id       INT IDENTITY(1,1)   NOT NULL,
    visit_code     VARCHAR(15)         NOT NULL,      -- VD: LK2023-0001
    patient_id     INT                 NOT NULL,
    appointment_id INT                 NULL,
    doctor_id      INT                 NOT NULL,
    room_id        INT                 NULL,
    visit_date     DATE                NOT NULL,
    chief_complaint NVARCHAR(500)      NULL,          -- Ly do den kham
    status         VARCHAR(12)         NOT NULL CONSTRAINT DF_visit_status DEFAULT ('OPEN'),
    started_at     DATETIME2(0)        NULL,
    ended_at       DATETIME2(0)        NULL,
    CONSTRAINT PK_visits PRIMARY KEY (visit_id),
    CONSTRAINT UQ_visits_code UNIQUE (visit_code),
    CONSTRAINT FK_visit_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT FK_visit_appointment FOREIGN KEY (appointment_id) REFERENCES dbo.appointments (appointment_id),
    CONSTRAINT FK_visit_doctor FOREIGN KEY (doctor_id) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT FK_visit_room FOREIGN KEY (room_id) REFERENCES dbo.rooms (room_id),
    CONSTRAINT CK_visit_status CHECK (status IN ('OPEN','IN_PROGRESS','COMPLETED','CANCELLED')),
    CONSTRAINT CK_visit_time CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at)
);
GO

/* ----------------------------------------------------------------------------
   11) medical_records - Ho so benh an cua 1 lan kham (1-1 voi visits).
       record_status: DRAFT -> LOCKED. Da LOCKED thi khong sua truc tiep
       (trigger chan), chi bo sung bang record_addenda.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.medical_records', N'U') IS NULL
CREATE TABLE dbo.medical_records (
    record_id      INT IDENTITY(1,1)   NOT NULL,
    visit_id       INT                 NOT NULL,
    patient_id     INT                 NOT NULL,
    doctor_id      INT                 NOT NULL,
    physical_exam  NVARCHAR(2000)      NULL,
    clinical_notes NVARCHAR(4000)      NULL,
    conclusion     NVARCHAR(1000)      NULL,
    record_status  VARCHAR(10)         NOT NULL CONSTRAINT DF_record_status DEFAULT ('DRAFT'),
    locked_by      INT                 NULL,
    locked_at      DATETIME2(0)        NULL,
    created_at     DATETIME2(0)        NOT NULL CONSTRAINT DF_record_created DEFAULT (SYSDATETIME()),
    updated_at     DATETIME2(0)        NOT NULL CONSTRAINT DF_record_updated DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_medical_records PRIMARY KEY (record_id),
    CONSTRAINT UQ_records_visit UNIQUE (visit_id),
    CONSTRAINT FK_record_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_record_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT FK_record_doctor FOREIGN KEY (doctor_id) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT FK_record_locked_by FOREIGN KEY (locked_by) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT CK_record_status CHECK (record_status IN ('DRAFT','LOCKED')),
    CONSTRAINT CK_record_lock CHECK (
        (record_status = 'DRAFT'  AND locked_at IS NULL) OR
        (record_status = 'LOCKED' AND locked_at IS NOT NULL))
);
GO

/* ----------------------------------------------------------------------------
   12) record_addenda - Phu luc bo sung cho ho so DA KHOA.
       Khong sua ban goc; moi bo sung la 1 dong moi, co ly do va nguoi duyet.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.record_addenda', N'U') IS NULL
CREATE TABLE dbo.record_addenda (
    addendum_id     INT IDENTITY(1,1)   NOT NULL,
    record_id       INT                 NOT NULL,
    author_doctor_id INT                NOT NULL,
    content         NVARCHAR(4000)      NOT NULL,
    reason          NVARCHAR(500)       NOT NULL,
    approval_status VARCHAR(10)         NOT NULL CONSTRAINT DF_addendum_status DEFAULT ('PENDING'),
    approved_by     INT                 NULL,
    approved_at     DATETIME2(0)        NULL,
    created_at      DATETIME2(0)        NOT NULL CONSTRAINT DF_addendum_created DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_record_addenda PRIMARY KEY (addendum_id),
    CONSTRAINT FK_addendum_record FOREIGN KEY (record_id) REFERENCES dbo.medical_records (record_id),
    CONSTRAINT FK_addendum_author FOREIGN KEY (author_doctor_id) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT FK_addendum_approver FOREIGN KEY (approved_by) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT CK_addendum_status CHECK (approval_status IN ('PENDING','APPROVED','REJECTED')),
    CONSTRAINT CK_addendum_approval CHECK (
        (approval_status = 'PENDING'  AND approved_at IS NULL) OR
        (approval_status <> 'PENDING' AND approved_at IS NOT NULL))
);
GO

/* ----------------------------------------------------------------------------
   13) audit_logs - Nhat ky kiem toan thao tac tren du lieu quan trong.
       Ghi bang trigger: bang, khoa chinh, hanh dong, tom tat OLD/NEW,
       nguoi thuc hien (login he thong) va thoi diem.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.audit_logs', N'U') IS NULL
CREATE TABLE dbo.audit_logs (
    audit_id    BIGINT IDENTITY(1,1)  NOT NULL,
    table_name  VARCHAR(60)           NOT NULL,
    record_pk   VARCHAR(60)           NOT NULL,
    action      VARCHAR(10)           NOT NULL,
    old_summary NVARCHAR(2000)        NULL,
    new_summary NVARCHAR(2000)        NULL,
    changed_by  NVARCHAR(128)         NOT NULL CONSTRAINT DF_audit_user DEFAULT (ORIGINAL_LOGIN()),
    changed_at  DATETIME2(0)          NOT NULL CONSTRAINT DF_audit_time DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_audit_logs PRIMARY KEY (audit_id),
    CONSTRAINT CK_audit_action CHECK (action IN ('INSERT','UPDATE','DELETE'))
);
GO

/* ----------------------------------------------------------------------------
   14) diagnoses - Chan doan theo ICD-10, phan biet chinh / phu
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.diagnoses', N'U') IS NULL
CREATE TABLE dbo.diagnoses (
    diagnosis_id   INT IDENTITY(1,1)   NOT NULL,
    visit_id       INT                 NOT NULL,
    icd10_code     VARCHAR(10)         NOT NULL,
    icd10_name     NVARCHAR(250)       NOT NULL,
    diagnosis_type VARCHAR(10)         NOT NULL,
    diagnosed_by   INT                 NOT NULL,
    diagnosed_at   DATETIME2(0)        NOT NULL CONSTRAINT DF_diag_time DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_diagnoses PRIMARY KEY (diagnosis_id),
    CONSTRAINT FK_diag_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_diag_doctor FOREIGN KEY (diagnosed_by) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT UQ_diag_visit_icd UNIQUE (visit_id, icd10_code, diagnosis_type),
    CONSTRAINT CK_diag_type CHECK (diagnosis_type IN ('PRIMARY','SECONDARY'))
);
GO

/* ----------------------------------------------------------------------------
   15) medical_services - Danh muc dich vu (phi kham, xet nghiem, chuan doan
       hinh anh, thu thuat). Gia hien hanh; hoa don luu snapshot gia.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.medical_services', N'U') IS NULL
CREATE TABLE dbo.medical_services (
    service_id          INT IDENTITY(1,1)  NOT NULL,
    service_code        VARCHAR(15)        NOT NULL,
    service_name        NVARCHAR(200)      NOT NULL,
    department_id       INT                NULL,
    service_type        VARCHAR(15)        NOT NULL,
    unit_price          DECIMAL(18,2)      NOT NULL,
    is_insurance_covered BIT               NOT NULL CONSTRAINT DF_svc_ins DEFAULT (1),
    is_active           BIT                NOT NULL CONSTRAINT DF_svc_active DEFAULT (1),
    CONSTRAINT PK_medical_services PRIMARY KEY (service_id),
    CONSTRAINT UQ_services_code UNIQUE (service_code),
    CONSTRAINT FK_service_department FOREIGN KEY (department_id) REFERENCES dbo.departments (department_id),
    CONSTRAINT CK_service_type CHECK (service_type IN ('CONSULT','LAB','IMAGING','PROCEDURE')),
    CONSTRAINT CK_service_price CHECK (unit_price >= 0)
);
GO

/* ----------------------------------------------------------------------------
   16) visit_services - Dich vu da thuc hien trong lan kham (de tinh vien phi)
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.visit_services', N'U') IS NULL
CREATE TABLE dbo.visit_services (
    visit_service_id INT IDENTITY(1,1)  NOT NULL,
    visit_id         INT                NOT NULL,
    service_id       INT                NOT NULL,
    quantity         INT                NOT NULL CONSTRAINT DF_vs_qty DEFAULT (1),
    unit_price_snapshot DECIMAL(18,2)   NOT NULL,
    performed_at     DATETIME2(0)       NOT NULL CONSTRAINT DF_vs_time DEFAULT (SYSDATETIME()),
    status           VARCHAR(12)        NOT NULL CONSTRAINT DF_vs_status DEFAULT ('DONE'),
    CONSTRAINT PK_visit_services PRIMARY KEY (visit_service_id),
    CONSTRAINT FK_vs_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_vs_service FOREIGN KEY (service_id) REFERENCES dbo.medical_services (service_id),
    CONSTRAINT CK_vs_qty CHECK (quantity > 0),
    CONSTRAINT CK_vs_price CHECK (unit_price_snapshot >= 0),
    CONSTRAINT CK_vs_status CHECK (status IN ('ORDERED','DONE','CANCELLED'))
);
GO

/* ----------------------------------------------------------------------------
   17) lab_orders - Chi dinh xet nghiem: bat buoc gan voi dung 1 lan kham
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.lab_orders', N'U') IS NULL
CREATE TABLE dbo.lab_orders (
    lab_order_id INT IDENTITY(1,1)   NOT NULL,
    visit_id     INT                 NOT NULL,
    service_id   INT                 NOT NULL,        -- Dich vu loai LAB
    ordered_by   INT                 NOT NULL,
    ordered_at   DATETIME2(0)        NOT NULL CONSTRAINT DF_lab_ordered DEFAULT (SYSDATETIME()),
    priority     VARCHAR(10)         NOT NULL CONSTRAINT DF_lab_priority DEFAULT ('NORMAL'),
    status       VARCHAR(12)         NOT NULL CONSTRAINT DF_lab_status DEFAULT ('ORDERED'),
    CONSTRAINT PK_lab_orders PRIMARY KEY (lab_order_id),
    CONSTRAINT FK_lab_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_lab_service FOREIGN KEY (service_id) REFERENCES dbo.medical_services (service_id),
    CONSTRAINT FK_lab_ordered_by FOREIGN KEY (ordered_by) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT CK_lab_priority CHECK (priority IN ('NORMAL','URGENT')),
    CONSTRAINT CK_lab_status CHECK (status IN ('ORDERED','COLLECTED','RESULTED','VERIFIED','CANCELLED'))
);
GO

/* ----------------------------------------------------------------------------
   18) lab_results - Ket qua tung thong so cua 1 chi dinh.
       is_abnormal do trigger trg_lab_results_abnormal tu danh gia dua tren
       khoang tham chieu [ref_low, ref_high] cua chinh thong so do.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.lab_results', N'U') IS NULL
CREATE TABLE dbo.lab_results (
    result_id      INT IDENTITY(1,1)   NOT NULL,
    lab_order_id   INT                 NOT NULL,
    parameter_code VARCHAR(20)         NOT NULL,      -- VD: GLU, HBA1C, WBC
    parameter_name NVARCHAR(120)       NOT NULL,
    result_value   DECIMAL(12,3)       NULL,
    result_text    NVARCHAR(250)       NULL,          -- Ket qua dinh tinh neu co
    unit           VARCHAR(20)         NULL,
    ref_low        DECIMAL(12,3)       NULL,
    ref_high       DECIMAL(12,3)       NULL,
    is_abnormal    BIT                 NOT NULL CONSTRAINT DF_lab_abnormal DEFAULT (0),
    resulted_by    NVARCHAR(120)       NULL,          -- Ky thuat vien nhap ket qua
    resulted_at    DATETIME2(0)        NOT NULL CONSTRAINT DF_lab_resulted DEFAULT (SYSDATETIME()),
    verified_by    INT                 NULL,          -- Bac si / truong khoa duyet
    verified_at    DATETIME2(0)        NULL,
    CONSTRAINT PK_lab_results PRIMARY KEY (result_id),
    CONSTRAINT FK_result_order FOREIGN KEY (lab_order_id) REFERENCES dbo.lab_orders (lab_order_id),
    CONSTRAINT FK_result_verified_by FOREIGN KEY (verified_by) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT UQ_result_order_param UNIQUE (lab_order_id, parameter_code),
    CONSTRAINT CK_result_ref CHECK (ref_low IS NULL OR ref_high IS NULL OR ref_high >= ref_low)
);
GO

/* ----------------------------------------------------------------------------
   19) medications - Danh muc thuoc
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.medications', N'U') IS NULL
CREATE TABLE dbo.medications (
    medication_id INT IDENTITY(1,1)   NOT NULL,
    medication_code VARCHAR(15)       NOT NULL,
    medication_name NVARCHAR(200)     NOT NULL,
    active_ingredient NVARCHAR(200)   NULL,           -- Hoat chat
    dosage_form     NVARCHAR(60)      NULL,           -- Vien nen / vien nang / ong tiem...
    strength        VARCHAR(30)       NULL,           -- VD: 5mg, 500mg
    unit            NVARCHAR(30)      NOT NULL CONSTRAINT DF_med_unit DEFAULT (N'viên'),
    unit_price      DECIMAL(18,2)     NOT NULL,
    is_insurance_covered BIT          NOT NULL CONSTRAINT DF_med_ins DEFAULT (1),
    is_active       BIT               NOT NULL CONSTRAINT DF_med_active DEFAULT (1),
    CONSTRAINT PK_medications PRIMARY KEY (medication_id),
    CONSTRAINT UQ_medications_code UNIQUE (medication_code),
    CONSTRAINT CK_med_price CHECK (unit_price >= 0)
);
GO

/* ----------------------------------------------------------------------------
   20) prescriptions - Don thuoc cua 1 lan kham.
       DRAFT -> ISSUED -> DISPENSED. Da ISSUED khong sua chi tiet truc tiep
       (trigger chan); muon doi phai huy don va tao don moi.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.prescriptions', N'U') IS NULL
CREATE TABLE dbo.prescriptions (
    prescription_id INT IDENTITY(1,1)  NOT NULL,
    prescription_code VARCHAR(15)      NOT NULL,      -- VD: DT2023-0001
    visit_id        INT                NOT NULL,
    doctor_id       INT                NOT NULL,
    status          VARCHAR(12)        NOT NULL CONSTRAINT DF_pres_status DEFAULT ('DRAFT'),
    notes           NVARCHAR(500)      NULL,
    created_at      DATETIME2(0)       NOT NULL CONSTRAINT DF_pres_created DEFAULT (SYSDATETIME()),
    issued_at       DATETIME2(0)       NULL,
    CONSTRAINT PK_prescriptions PRIMARY KEY (prescription_id),
    CONSTRAINT UQ_prescriptions_code UNIQUE (prescription_code),
    CONSTRAINT FK_pres_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_pres_doctor FOREIGN KEY (doctor_id) REFERENCES dbo.doctors (doctor_id),
    CONSTRAINT CK_pres_status CHECK (status IN ('DRAFT','ISSUED','DISPENSED','CANCELLED')),
    CONSTRAINT CK_pres_issued CHECK (status = 'DRAFT' OR status = 'CANCELLED' OR issued_at IS NOT NULL)
);
GO

/* ----------------------------------------------------------------------------
   21) prescription_items - Chi tiet don thuoc.
       Tong so luong BAT BUOC thoa: total = lieu/lan x so lan/ngay x so ngay
       (CHECK cung cap du lieu; sp_add_prescription_item tinh va validate).
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.prescription_items', N'U') IS NULL
CREATE TABLE dbo.prescription_items (
    item_id         INT IDENTITY(1,1)   NOT NULL,
    prescription_id INT                 NOT NULL,
    medication_id   INT                 NOT NULL,
    dose_per_intake DECIMAL(6,2)        NOT NULL,     -- VD: 1.00 vien / lan
    intakes_per_day INT                 NOT NULL,     -- VD: 2 lan / ngay
    duration_days   INT                 NOT NULL,     -- VD: 7 ngay
    total_quantity  DECIMAL(10,2)       NOT NULL,     -- = dose x intakes x days
    instructions    NVARCHAR(250)       NULL,         -- VD: Uong sau an
    CONSTRAINT PK_prescription_items PRIMARY KEY (item_id),
    CONSTRAINT FK_item_prescription FOREIGN KEY (prescription_id) REFERENCES dbo.prescriptions (prescription_id),
    CONSTRAINT FK_item_medication FOREIGN KEY (medication_id) REFERENCES dbo.medications (medication_id),
    CONSTRAINT UQ_item_pres_med UNIQUE (prescription_id, medication_id),
    CONSTRAINT CK_item_dose CHECK (dose_per_intake > 0 AND intakes_per_day > 0 AND duration_days > 0),
    CONSTRAINT CK_item_total CHECK (total_quantity = dose_per_intake * intakes_per_day * duration_days)
);
GO

/* ----------------------------------------------------------------------------
   22) invoices - Hoa don vien phi cua 1 lan kham.
       gross_total = tong dich vu + xet nghiem + thuoc (theo invoice_items).
       insurance_payable: phan BHYT chi tra theo muc huong hieu luc.
       patient_copay = gross_total - insurance_payable - discount_amount.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.invoices', N'U') IS NULL
CREATE TABLE dbo.invoices (
    invoice_id      INT IDENTITY(1,1)   NOT NULL,
    invoice_no      VARCHAR(15)         NOT NULL,     -- VD: HD2023-0001
    visit_id        INT                 NOT NULL,
    patient_id      INT                 NOT NULL,
    insurance_id    INT                 NULL,         -- The BHYT ap dung (neu co)
    referral_type   VARCHAR(15)         NOT NULL CONSTRAINT DF_inv_referral DEFAULT ('CORRECT'),
    coverage_percent_snapshot DECIMAL(5,2) NULL,      -- Muc huong tren the tai thoi diem lap
    effective_coverage_percent DECIMAL(5,2) NOT NULL CONSTRAINT DF_inv_eff DEFAULT (0),
    services_total  DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_svc DEFAULT (0),
    labs_total      DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_lab DEFAULT (0),
    meds_total      DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_med DEFAULT (0),
    gross_total     DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_gross DEFAULT (0),
    insurance_payable DECIMAL(18,2)     NOT NULL CONSTRAINT DF_inv_ins DEFAULT (0),
    discount_amount DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_disc DEFAULT (0),
    patient_copay   DECIMAL(18,2)       NOT NULL CONSTRAINT DF_inv_copay DEFAULT (0),
    insurance_claim_status VARCHAR(12)  NOT NULL CONSTRAINT DF_inv_claim DEFAULT ('NOT_SENT'),
    status          VARCHAR(15)         NOT NULL CONSTRAINT DF_inv_status DEFAULT ('DRAFT'),
    issued_at       DATETIME2(0)        NULL,
    due_date        DATE                NULL,
    created_at      DATETIME2(0)        NOT NULL CONSTRAINT DF_inv_created DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_invoices PRIMARY KEY (invoice_id),
    CONSTRAINT UQ_invoices_no UNIQUE (invoice_no),
    CONSTRAINT UQ_invoices_visit UNIQUE (visit_id),
    CONSTRAINT FK_inv_visit FOREIGN KEY (visit_id) REFERENCES dbo.visits (visit_id),
    CONSTRAINT FK_inv_patient FOREIGN KEY (patient_id) REFERENCES dbo.patients (patient_id),
    CONSTRAINT FK_inv_insurance FOREIGN KEY (insurance_id) REFERENCES dbo.insurance_cards (insurance_id),
    CONSTRAINT CK_inv_referral CHECK (referral_type IN ('CORRECT','WRONG','EMERGENCY')),
    CONSTRAINT CK_inv_claim CHECK (insurance_claim_status IN ('NOT_SENT','SENT','APPROVED','REJECTED')),
    CONSTRAINT CK_inv_status CHECK (status IN ('DRAFT','ISSUED','PARTIALLY_PAID','PAID','CANCELLED')),
    CONSTRAINT CK_inv_amounts CHECK (
        services_total >= 0 AND labs_total >= 0 AND meds_total >= 0
        AND gross_total = services_total + labs_total + meds_total
        AND insurance_payable >= 0 AND insurance_payable <= gross_total
        AND discount_amount >= 0
        AND patient_copay = gross_total - insurance_payable - discount_amount)
);
GO

/* ----------------------------------------------------------------------------
   23) invoice_items - Dong hoa don: truy xuat nguon (dich vu / xet nghiem /
       dong don thuoc) va co duoc BHYT chi tra hay khong.
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.invoice_items', N'U') IS NULL
CREATE TABLE dbo.invoice_items (
    invoice_item_id INT IDENTITY(1,1)  NOT NULL,
    invoice_id      INT                NOT NULL,
    item_type       VARCHAR(10)        NOT NULL,      -- SERVICE / LAB / MED
    source_id       INT                NOT NULL,      -- visit_service_id / lab_order_id / prescription_item_id
    description     NVARCHAR(250)      NOT NULL,
    quantity        DECIMAL(10,2)      NOT NULL,
    unit_price      DECIMAL(18,2)      NOT NULL,
    line_total      DECIMAL(18,2)      NOT NULL,
    is_insurance_eligible BIT          NOT NULL CONSTRAINT DF_ii_eligible DEFAULT (0),
    CONSTRAINT PK_invoice_items PRIMARY KEY (invoice_item_id),
    CONSTRAINT FK_ii_invoice FOREIGN KEY (invoice_id) REFERENCES dbo.invoices (invoice_id),
    CONSTRAINT UQ_ii_source UNIQUE (invoice_id, item_type, source_id),
    CONSTRAINT CK_ii_type CHECK (item_type IN ('SERVICE','LAB','MED')),
    CONSTRAINT CK_ii_amount CHECK (quantity > 0 AND unit_price >= 0 AND line_total = quantity * unit_price)
);
GO

/* ----------------------------------------------------------------------------
   24) payments - Giao dich thanh toan (benh nhan hoac BHYT chi tra)
---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.payments', N'U') IS NULL
CREATE TABLE dbo.payments (
    payment_id     INT IDENTITY(1,1)   NOT NULL,
    invoice_id     INT                 NOT NULL,
    payer_type     VARCHAR(12)         NOT NULL,      -- PATIENT / INSURANCE
    amount         DECIMAL(18,2)       NOT NULL,
    payment_method VARCHAR(15)         NOT NULL,
    transaction_ref VARCHAR(50)        NULL,
    paid_at        DATETIME2(0)        NOT NULL CONSTRAINT DF_pay_time DEFAULT (SYSDATETIME()),
    received_by    NVARCHAR(120)       NULL,
    status         VARCHAR(12)         NOT NULL CONSTRAINT DF_pay_status DEFAULT ('COMPLETED'),
    CONSTRAINT PK_payments PRIMARY KEY (payment_id),
    CONSTRAINT FK_pay_invoice FOREIGN KEY (invoice_id) REFERENCES dbo.invoices (invoice_id),
    CONSTRAINT CK_pay_payer CHECK (payer_type IN ('PATIENT','INSURANCE')),
    CONSTRAINT CK_pay_method CHECK (payment_method IN ('CASH','CARD','TRANSFER','INSURANCE_CLAIM')),
    CONSTRAINT CK_pay_amount CHECK (amount > 0),
    CONSTRAINT CK_pay_status CHECK (status IN ('COMPLETED','REFUNDED','VOID'))
);
GO

PRINT N'01_schema.sql: Da tao xong database MediCoreDB va 24 bang.';
GO
