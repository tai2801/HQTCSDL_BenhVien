/* ============================================================================
   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE
   File: 02_seed.sql - Du lieu mau (sinh boi tools/generate_seed.py)
   booked_count va tong tien hoa don/BHYT duoc tinh tu dong khi sinh file,
   dam bao nhat quan. Idempotent: xoa du lieu mau cu (theo khoang ID seed)
   truoc khi chen lai.
   ============================================================================ */
SET NOCOUNT ON;
USE MediCoreDB;
GO

BEGIN TRANSACTION;
GO
/* Neu chay lai seed SAU khi da cai triggers (06): tam tat trigger chan
   sua don thuoc da phat hanh de lenh don du lieu mau khong bi chan;
   bat lai ngay sau khi chen xong (trong cung file nay). */
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_prescription_items_block_issued')
    DISABLE TRIGGER dbo.trg_prescription_items_block_issued ON dbo.prescription_items;
GO

DELETE FROM dbo.payments;
DELETE FROM dbo.invoice_items;
DELETE FROM dbo.invoices;
DELETE FROM dbo.prescription_items;
DELETE FROM dbo.prescriptions;
DELETE FROM dbo.lab_results;
DELETE FROM dbo.lab_orders;
DELETE FROM dbo.visit_services;
DELETE FROM dbo.diagnoses;
DELETE FROM dbo.record_addenda;
DELETE FROM dbo.medical_records;
DELETE FROM dbo.visits;
DELETE FROM dbo.appointments;
DELETE FROM dbo.doctor_schedules;
DELETE FROM dbo.insurance_cards;
DELETE FROM dbo.patient_allergies;
DELETE FROM dbo.patients;
DELETE FROM dbo.medications;
DELETE FROM dbo.medical_services;
DELETE FROM dbo.rooms;
DELETE FROM dbo.doctors;
DELETE FROM dbo.app_users;
DELETE FROM dbo.departments;
GO

SET IDENTITY_INSERT dbo.departments ON;
INSERT INTO dbo.departments (department_id, department_code, department_name, description) VALUES
    (1, 'GEN', N'Nội tổng quát', N'Khám và điều trị bệnh nội khoa tổng quát'),
    (2, 'CARD', N'Tim mạch', N'Khám, chẩn đoán bệnh tim mạch'),
    (3, 'RESP', N'Hô hấp', N'Bệnh lý đường hô hấp và phổi'),
    (4, 'GI', N'Tiêu hóa', N'Bệnh lý tiêu hóa, gan mật'),
    (5, 'PEDI', N'Nhi khoa', N'Khám và điều trị cho trẻ em'),
    (6, 'DERM', N'Da liễu', N'Bệnh lý da và phần phụ của da'),
    (7, 'ENT', N'Tai Mũi Họng', N'Bệnh lý tai, mũi, họng');
SET IDENTITY_INSERT dbo.departments OFF;

SET IDENTITY_INSERT dbo.app_users ON;
INSERT INTO dbo.app_users (user_id, username, password_hash, full_name, role_code) VALUES
    (1, 'admin', 'HASH_PLACEHOLDER_ADMIN', N'Quản trị hệ thống', 'ADMIN'),
    (2, 'bs.tuan', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Phạm Minh Tuấn', 'DOCTOR'),
    (3, 'bs.lan', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Trần Thu Lan', 'DOCTOR'),
    (4, 'bs.hung', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Nguyễn Quốc Hùng', 'DOCTOR'),
    (5, 'bs.mai', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Lê Ngọc Mai', 'DOCTOR'),
    (6, 'bs.son', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Vũ Hải Sơn', 'DOCTOR'),
    (7, 'bs.thao', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Đặng Phương Thảo', 'DOCTOR'),
    (8, 'bs.khoa', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Bùi Anh Khoa', 'DOCTOR'),
    (9, 'bs.nhi', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Hồ Tuyết Nhi', 'DOCTOR'),
    (10, 'bs.duyen', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Ngô Mỹ Duyên', 'DOCTOR'),
    (11, 'bs.phong', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Dương Văn Phong', 'DOCTOR'),
    (12, 'bs.trang', 'HASH_PLACEHOLDER_DOCTOR', N'BS. Trịnh Thu Trang', 'DOCTOR'),
    (13, 'ktv.huy', 'HASH_PLACEHOLDER_TECH', N'KTV. Phan Gia Huy', 'LAB_TECH'),
    (14, 'tn.linh', 'HASH_PLACEHOLDER_CASH', N'Nguyễn Khánh Linh', 'CASHIER'),
    (15, 'lt.vy', 'HASH_PLACEHOLDER_RECEP', N'Phạm Thảo Vy', 'RECEPTIONIST');
SET IDENTITY_INSERT dbo.app_users OFF;

SET IDENTITY_INSERT dbo.doctors ON;
INSERT INTO dbo.doctors (doctor_id, user_id, department_id, full_name, title, license_no, phone, email) VALUES
    (1, 2, 1, N'Phạm Minh Tuấn', N'ThS.BS', 'CCHN-00101', '0903101001', 'cchn00101@medicore.vn'),
    (2, 3, 1, N'Trần Thu Lan', N'BS.CKI', 'CCHN-00102', '0903101002', 'cchn00102@medicore.vn'),
    (3, 4, 2, N'Nguyễn Quốc Hùng', N'BS.CKII', 'CCHN-00103', '0903101003', 'cchn00103@medicore.vn'),
    (4, 5, 2, N'Lê Ngọc Mai', N'ThS.BS', 'CCHN-00104', '0903101004', 'cchn00104@medicore.vn'),
    (5, 6, 3, N'Vũ Hải Sơn', N'BS.CKI', 'CCHN-00105', '0903101005', 'cchn00105@medicore.vn'),
    (6, 7, 4, N'Đặng Phương Thảo', N'ThS.BS', 'CCHN-00106', '0903101006', 'cchn00106@medicore.vn'),
    (7, 8, 5, N'Bùi Anh Khoa', N'BS', 'CCHN-00107', '0903101007', 'cchn00107@medicore.vn'),
    (8, 9, 5, N'Hồ Tuyết Nhi', N'BS.CKI', 'CCHN-00108', '0903101008', 'cchn00108@medicore.vn'),
    (9, 10, 6, N'Ngô Mỹ Duyên', N'BS', 'CCHN-00109', '0903101009', 'cchn00109@medicore.vn'),
    (10, 11, 7, N'Dương Văn Phong', N'BS.CKI', 'CCHN-00110', '0903101010', 'cchn00110@medicore.vn'),
    (11, 12, 1, N'Trịnh Thu Trang', N'BS', 'CCHN-00111', '0903101011', 'cchn00111@medicore.vn');
SET IDENTITY_INSERT dbo.doctors OFF;

SET IDENTITY_INSERT dbo.rooms ON;
INSERT INTO dbo.rooms (room_id, room_code, room_name, department_id, floor_no) VALUES
    (1, 'P101', N'Phòng khám Nội 1', 1, 1),
    (2, 'P102', N'Phòng khám Tim mạch', 2, 1),
    (3, 'P103', N'Phòng khám Hô hấp', 3, 1),
    (4, 'P104', N'Phòng khám Tiêu hóa', 4, 2),
    (5, 'P105', N'Phòng khám Nhi', 5, 2),
    (6, 'P106', N'Phòng khám Da liễu', 6, 2),
    (7, 'P107', N'Phòng khám Tai Mũi Họng', 7, 3);
SET IDENTITY_INSERT dbo.rooms OFF;

SET IDENTITY_INSERT dbo.patients ON;
INSERT INTO dbo.patients (patient_id, patient_code, national_id, full_name, date_of_birth, gender, phone, email, address, blood_type) VALUES
    (1, 'BN2023-0001', '079078001201', N'Nguyễn Văn An', '1978-05-12', 'MALE', '0912001001', 'benhnhan01@example.vn', N'TP. Hồ Chí Minh', 'O+'),
    (2, 'BN2023-0002', '052182002302', N'Trần Thị Bình', '1982-09-03', 'FEMALE', '0912001002', 'benhnhan02@example.vn', N'TP. Hồ Chí Minh', 'A+'),
    (3, 'BN2023-0003', '079065003403', N'Lê Văn Cường', '1965-01-25', 'MALE', '0912001003', 'benhnhan03@example.vn', N'TP. Hồ Chí Minh', 'B+'),
    (4, 'BN2023-0004', '031190004504', N'Phạm Thị Dung', '1990-07-18', 'FEMALE', '0912001004', 'benhnhan04@example.vn', N'TP. Hồ Chí Minh', 'O+'),
    (5, 'BN2023-0005', '079201005605', N'Hoàng Minh Đức', '2001-03-30', 'MALE', '0912001005', 'benhnhan05@example.vn', N'TP. Hồ Chí Minh', 'AB+'),
    (6, 'BN2023-0006', '052175006706', N'Vũ Thị Hạnh', '1975-11-08', 'FEMALE', '0912001006', 'benhnhan06@example.vn', N'TP. Hồ Chí Minh', 'A-'),
    (7, 'BN2023-0007', '079088007807', N'Đặng Quốc Khánh', '1988-06-15', 'MALE', '0912001007', 'benhnhan07@example.vn', N'TP. Hồ Chí Minh', 'B-'),
    (8, 'BN2023-0008', '031195008908', N'Ngô Thị Lan Anh', '1995-02-20', 'FEMALE', '0912001008', 'benhnhan08@example.vn', N'TP. Hồ Chí Minh', 'O-'),
    (9, 'BN2023-0009', '079201510109', N'Bùi Gia Bảo', '2015-08-11', 'MALE', '0912001009', 'benhnhan09@example.vn', N'TP. Hồ Chí Minh', 'A+'),
    (10, 'BN2023-0010', '052201811010', N'Hồ Ngọc Châu', '2018-04-05', 'FEMALE', '0912001010', 'benhnhan10@example.vn', N'TP. Hồ Chí Minh', 'B+'),
    (11, 'BN2023-0011', '079060011111', N'Dương Văn Em', '1960-12-01', 'MALE', '0912001011', 'benhnhan11@example.vn', N'TP. Hồ Chí Minh', 'O+'),
    (12, 'BN2023-0012', '031199012212', N'Trịnh Thị Phương', '1999-10-22', 'FEMALE', '0912001012', 'benhnhan12@example.vn', N'TP. Hồ Chí Minh', 'A+'),
    (13, 'BN2023-0013', '079085013313', N'Phan Văn Giang', '1985-05-27', 'MALE', '0912001013', 'benhnhan13@example.vn', N'TP. Hồ Chí Minh', 'AB-'),
    (14, 'BN2023-0014', '052193014414', N'Lý Thị Hoa', '1993-01-14', 'FEMALE', '0912001014', 'benhnhan14@example.vn', N'TP. Hồ Chí Minh', 'O+'),
    (15, 'BN2023-0015', '079070015515', N'Chu Văn Ích', '1970-08-19', 'MALE', '0912001015', 'benhnhan15@example.vn', N'TP. Hồ Chí Minh', 'B+'),
    (16, 'BN2023-0016', '031200016616', N'Đỗ Thuỳ Dương', '2000-06-09', 'FEMALE', '0912001016', 'benhnhan16@example.vn', N'TP. Hồ Chí Minh', 'A-');
SET IDENTITY_INSERT dbo.patients OFF;

SET IDENTITY_INSERT dbo.patient_allergies ON;
INSERT INTO dbo.patient_allergies (allergy_id, patient_id, allergen, reaction, severity) VALUES
    (1, 4, N'Penicillin', N'Phát ban, ngứa toàn thân sau khi dùng Amoxicillin', 'SEVERE'),
    (2, 8, N'NSAID', N'Đau dạ dày dữ dội khi dùng Ibuprofen', 'MODERATE'),
    (3, 13, N'Hải sản', N'Nổi mề đay sau khi ăn tôm', 'MILD');
SET IDENTITY_INSERT dbo.patient_allergies OFF;

SET IDENTITY_INSERT dbo.insurance_cards ON;
INSERT INTO dbo.insurance_cards (insurance_id, patient_id, card_no, coverage_percent, registered_facility, valid_from, valid_to) VALUES
    (1, 1, 'GD479001000001', 80, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (2, 2, 'HT279002000002', 95, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (3, 3, 'GD479003000003', 80, N'Bệnh viện Quận 1', '2023-01-01', '2023-12-31'),
    (4, 4, 'SV479004000004', 80, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (5, 5, 'SV479005000005', 80, N'Trường ĐH Công nghiệp Thực phẩm TP.HCM', '2023-01-01', '2023-12-31'),
    (6, 6, 'HT379006000006', 100, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (7, 7, 'GD479007000007', 80, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (8, 8, 'GD479008000008', 80, N'Bệnh viện Bình Thạnh', '2023-01-01', '2023-12-31'),
    (9, 9, 'TE179009000009', 100, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (10, 10, 'TE179010000010', 100, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (11, 11, 'HT279011000011', 95, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31'),
    (12, 12, 'GD479012000012', 80, N'Bệnh viện MediCore', '2023-01-01', '2023-12-31');
SET IDENTITY_INSERT dbo.insurance_cards OFF;

SET IDENTITY_INSERT dbo.doctor_schedules ON;
INSERT INTO dbo.doctor_schedules (schedule_id, doctor_id, room_id, work_date, shift_code, start_time, end_time, slot_capacity, booked_count, status) VALUES
    (1, 1, 1, '2023-05-16', 'MORNING', '07:30', '11:30', 25, 2, 'CLOSED'),
    (2, 3, 2, '2023-05-16', 'MORNING', '07:30', '11:30', 20, 1, 'CLOSED'),
    (3, 7, 5, '2023-05-16', 'AFTERNOON', '13:00', '17:00', 30, 2, 'CLOSED'),
    (4, 2, 1, '2023-05-17', 'MORNING', '07:30', '11:30', 25, 1, 'CLOSED'),
    (5, 5, 3, '2023-05-17', 'MORNING', '07:30', '11:30', 20, 1, 'CLOSED'),
    (6, 6, 4, '2023-05-18', 'AFTERNOON', '13:00', '17:00', 18, 1, 'CLOSED'),
    (7, 9, 6, '2023-05-18', 'MORNING', '07:30', '11:30', 22, 1, 'CLOSED'),
    (8, 10, 7, '2023-05-19', 'MORNING', '07:30', '11:30', 22, 1, 'CLOSED'),
    (9, 1, 1, '2023-05-23', 'MORNING', '07:30', '11:30', 25, 2, 'OPEN'),
    (10, 4, 2, '2023-05-23', 'AFTERNOON', '13:00', '17:00', 20, 1, 'OPEN'),
    (11, 8, 5, '2023-05-24', 'MORNING', '07:30', '11:30', 30, 1, 'OPEN'),
    (12, 11, 1, '2023-05-24', 'AFTERNOON', '13:00', '17:00', 25, 0, 'OPEN');
SET IDENTITY_INSERT dbo.doctor_schedules OFF;

SET IDENTITY_INSERT dbo.appointments ON;
INSERT INTO dbo.appointments (appointment_id, appointment_no, schedule_id, patient_id, reason, status) VALUES
    (1, 'LH2023-0001', 1, 1, N'Đau đầu, chóng mặt, đo huyết áp cao tại nhà', 'COMPLETED'),
    (2, 'LH2023-0002', 1, 3, N'Tái khám tăng huyết áp', 'COMPLETED'),
    (3, 'LH2023-0003', 2, 11, N'Đau ngực khi gắng sức', 'COMPLETED'),
    (4, 'LH2023-0004', 3, 9, N'Sốt cao, ho nhiều', 'COMPLETED'),
    (5, 'LH2023-0005', 4, 2, N'Mệt mỏi, nghi thiếu máu', 'COMPLETED'),
    (6, 'LH2023-0006', 5, 6, N'Ho kéo dài 3 tuần', 'COMPLETED'),
    (7, 'LH2023-0007', 6, 13, N'Đau thượng vị, ợ chua', 'COMPLETED'),
    (8, 'LH2023-0008', 7, 14, N'Ngứa da, nổi mẩn đỏ', 'COMPLETED'),
    (9, 'LH2023-0009', 8, 16, N'Đau tai phải, ù tai', 'COMPLETED'),
    (10, 'LH2023-0010', 9, 5, N'Khám sức khỏe định kỳ', 'BOOKED'),
    (11, 'LH2023-0011', 9, 7, N'Đau lưng, tê chân', 'BOOKED'),
    (12, 'LH2023-0012', 10, 12, N'Hồi hộp, tim đập nhanh', 'BOOKED'),
    (13, 'LH2023-0013', 11, 10, N'Ho, sổ mũi', 'BOOKED'),
    (14, 'LH2023-0014', 12, 15, N'Đau dạ dày tái phát', 'CANCELLED'),
    (15, 'LH2023-0015', 3, 10, N'Khám tổng quát cho bé', 'NO_SHOW');
SET IDENTITY_INSERT dbo.appointments OFF;

SET IDENTITY_INSERT dbo.visits ON;
INSERT INTO dbo.visits (visit_id, visit_code, patient_id, appointment_id, doctor_id, room_id, visit_date, chief_complaint, status, started_at, ended_at) VALUES
    (1, 'LK2023-0001', 1, 1, 1, 1, '2023-05-16', N'Đau đầu, chóng mặt 2 ngày', 'COMPLETED', '2023-05-16 08:00:00', '2023-05-16 08:45:00'),
    (2, 'LK2023-0002', 3, 2, 1, 1, '2023-05-16', N'Tái khám tăng huyết áp sau 1 tháng', 'COMPLETED', '2023-05-16 08:00:00', '2023-05-16 08:45:00'),
    (3, 'LK2023-0003', 11, 3, 3, 2, '2023-05-16', N'Đau ngực trái khi leo cầu thang', 'COMPLETED', '2023-05-16 08:00:00', '2023-05-16 08:45:00'),
    (4, 'LK2023-0004', 9, 4, 7, 5, '2023-05-16', N'Sốt 39 độ, ho đờm 3 ngày', 'COMPLETED', '2023-05-16 08:00:00', '2023-05-16 08:45:00'),
    (5, 'LK2023-0005', 2, 5, 2, 1, '2023-05-17', N'Mệt mỏi, da xanh, chóng mặt khi đứng', 'COMPLETED', '2023-05-17 08:00:00', '2023-05-17 08:45:00'),
    (6, 'LK2023-0006', 6, 6, 5, 3, '2023-05-17', N'Ho khan kéo dài, khó thở nhẹ về đêm', 'COMPLETED', '2023-05-17 08:00:00', '2023-05-17 08:45:00'),
    (7, 'LK2023-0007', 13, 7, 6, 4, '2023-05-18', N'Đau thượng vị âm ỉ, ợ chua sau ăn', 'COMPLETED', '2023-05-18 08:00:00', '2023-05-18 08:45:00'),
    (8, 'LK2023-0008', 14, 8, 9, 6, '2023-05-18', N'Ngứa và nổi mẩn đỏ hai tay 1 tuần', 'COMPLETED', '2023-05-18 08:00:00', '2023-05-18 08:45:00'),
    (9, 'LK2023-0009', 16, 9, 10, 7, '2023-05-19', N'Đau tai phải, nghe kém 4 ngày', 'COMPLETED', '2023-05-19 08:00:00', '2023-05-19 08:45:00'),
    (10, 'LK2023-0010', 4, NULL, 2, 1, '2023-05-20', N'Đau bụng dưới, rối loạn tiêu hóa', 'IN_PROGRESS', '2023-05-20 08:00:00', NULL),
    (11, 'LK2023-0011', 8, NULL, 4, 2, '2023-05-20', N'Hồi hộp từng cơn, lo âu', 'OPEN', '2023-05-20 08:00:00', NULL),
    (12, 'LK2023-0012', 15, NULL, 11, 1, '2023-05-20', N'Đau dạ dày, buồn nôn', 'OPEN', '2023-05-20 08:00:00', NULL),
    (13, 'LK2023-0013', 7, NULL, 1, 1, '2023-05-20', N'Đau lưng lan xuống chân phải', 'CANCELLED', NULL, NULL);
SET IDENTITY_INSERT dbo.visits OFF;

SET IDENTITY_INSERT dbo.medical_records ON;
INSERT INTO dbo.medical_records (record_id, visit_id, patient_id, doctor_id, physical_exam, clinical_notes, conclusion, record_status, locked_by, locked_at) VALUES
    (1, 1, 1, 1, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 1, '2023-05-20 10:00:00'),
    (2, 2, 3, 1, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 1, '2023-05-20 10:00:00'),
    (3, 3, 11, 3, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 3, '2023-05-20 10:00:00'),
    (4, 4, 9, 7, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 7, '2023-05-20 10:00:00'),
    (5, 5, 2, 2, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 2, '2023-05-20 10:00:00'),
    (6, 6, 6, 5, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'DRAFT', NULL, NULL),
    (7, 7, 13, 6, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 6, '2023-05-20 10:00:00'),
    (8, 8, 14, 9, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'DRAFT', NULL, NULL),
    (9, 9, 16, 10, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'LOCKED', 10, '2023-05-20 10:00:00'),
    (10, 10, 4, 2, N'Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa.', N'Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt.', N'Kết luận theo chẩn đoán chính của lần khám.', 'DRAFT', NULL, NULL);
SET IDENTITY_INSERT dbo.medical_records OFF;

SET IDENTITY_INSERT dbo.record_addenda ON;
INSERT INTO dbo.record_addenda (addendum_id, record_id, author_doctor_id, content, reason, approval_status, approved_by, approved_at) VALUES
    (1, 2, 1, N'Bổ sung kết quả đo huyết áp tại nhà ngày 20/11: trung bình 128/82 mmHg, đáp ứng điều trị tốt.', N'Bệnh nhân gửi sổ theo dõi huyết áp sau khi hồ sơ đã khóa', 'APPROVED', 2, '2023-05-21 09:00:00'),
    (2, 3, 3, N'Bổ sung diễn giải kết quả điện tâm đồ: nhịp xoang, trục trung gian, không có đoạn ST chênh.', N'Kết quả ECG trả về sau thời điểm khóa hồ sơ', 'PENDING', NULL, NULL);
SET IDENTITY_INSERT dbo.record_addenda OFF;

SET IDENTITY_INSERT dbo.diagnoses ON;
INSERT INTO dbo.diagnoses (visit_id, icd10_code, icd10_name, diagnosis_type, diagnosed_by) VALUES
    (1, 'I10', N'Tăng huyết áp vô căn', 'PRIMARY', 1),
    (1, 'R42', N'Chóng mặt', 'SECONDARY', 1),
    (2, 'I10', N'Tăng huyết áp vô căn', 'PRIMARY', 1),
    (2, 'E11', N'Đái tháo đường type 2', 'SECONDARY', 1),
    (3, 'I25.1', N'Bệnh tim thiếu máu cục bộ mạn', 'PRIMARY', 3),
    (3, 'E78.5', N'Rối loạn lipid máu', 'SECONDARY', 3),
    (4, 'J20', N'Viêm phế quản cấp', 'PRIMARY', 7),
    (5, 'D64.9', N'Thiếu máu, không đặc hiệu', 'PRIMARY', 2),
    (6, 'J45', N'Hen phế quản', 'PRIMARY', 5),
    (7, 'K29.5', N'Viêm dạ dày mạn', 'PRIMARY', 6),
    (8, 'L20', N'Viêm da cơ địa', 'PRIMARY', 9),
    (9, 'H66.9', N'Viêm tai giữa, không đặc hiệu', 'PRIMARY', 10),
    (10, 'R10.3', N'Đau vùng chậu và đáy chậu', 'PRIMARY', 2),
    (11, 'R00.2', N'Đánh trống ngực', 'PRIMARY', 4);
SET IDENTITY_INSERT dbo.diagnoses OFF;

SET IDENTITY_INSERT dbo.medical_services ON;
INSERT INTO dbo.medical_services (service_id, service_code, service_name, department_id, service_type, unit_price, is_insurance_covered) VALUES
    (1, 'DV001', N'Khám Nội tổng quát', 1, 'CONSULT', 150000, 1),
    (2, 'DV002', N'Khám Tim mạch', 2, 'CONSULT', 200000, 1),
    (3, 'DV003', N'Khám Hô hấp', 3, 'CONSULT', 180000, 1),
    (4, 'DV004', N'Khám Tiêu hóa', 4, 'CONSULT', 180000, 1),
    (5, 'DV005', N'Khám Nhi khoa', 5, 'CONSULT', 120000, 1),
    (6, 'DV006', N'Khám Da liễu', 6, 'CONSULT', 150000, 1),
    (7, 'DV007', N'Khám Tai Mũi Họng', 7, 'CONSULT', 150000, 1),
    (8, 'XN001', N'Tổng phân tích tế bào máu (CBC)', 1, 'LAB', 120000, 1),
    (9, 'XN002', N'Đường huyết lúc đói', 1, 'LAB', 60000, 1),
    (10, 'XN003', N'HbA1c', 1, 'LAB', 150000, 1),
    (11, 'XN004', N'Bộ mỡ máu (Lipid)', 2, 'LAB', 180000, 1),
    (12, 'XN005', N'Men gan (AST/ALT)', 4, 'LAB', 140000, 1),
    (13, 'XN006', N'Tổng phân tích nước tiểu', 1, 'LAB', 70000, 1),
    (14, 'CD001', N'Điện tâm đồ (ECG)', 2, 'IMAGING', 100000, 1),
    (15, 'CD002', N'X-quang ngực thẳng', 3, 'IMAGING', 150000, 1),
    (16, 'CD003', N'Siêu âm ổ bụng tổng quát', 4, 'IMAGING', 200000, 1),
    (17, 'TT001', N'Nội soi dạ dày gây mê', 4, 'PROCEDURE', 800000, 1),
    (18, 'DV008', N'Tư vấn dinh dưỡng chuyên sâu', 1, 'CONSULT', 250000, 0);
SET IDENTITY_INSERT dbo.medical_services OFF;

SET IDENTITY_INSERT dbo.visit_services ON;
INSERT INTO dbo.visit_services (visit_service_id, visit_id, service_id, quantity, unit_price_snapshot, status) VALUES
    (1, 1, 1, 1, 150000, 'DONE'),
    (2, 2, 1, 1, 150000, 'DONE'),
    (3, 3, 2, 1, 200000, 'DONE'),
    (4, 3, 14, 1, 100000, 'DONE'),
    (5, 4, 5, 1, 120000, 'DONE'),
    (6, 5, 1, 1, 150000, 'DONE'),
    (7, 6, 3, 1, 180000, 'DONE'),
    (8, 6, 15, 1, 150000, 'DONE'),
    (9, 7, 4, 1, 180000, 'DONE'),
    (10, 7, 17, 1, 800000, 'DONE'),
    (11, 8, 6, 1, 150000, 'DONE'),
    (12, 9, 7, 1, 150000, 'DONE'),
    (13, 10, 1, 1, 150000, 'DONE'),
    (14, 11, 2, 1, 200000, 'DONE'),
    (15, 11, 14, 1, 100000, 'DONE'),
    (16, 12, 1, 1, 150000, 'DONE'),
    (17, 1, 18, 1, 250000, 'DONE');
SET IDENTITY_INSERT dbo.visit_services OFF;

SET IDENTITY_INSERT dbo.lab_orders ON;
INSERT INTO dbo.lab_orders (lab_order_id, visit_id, service_id, ordered_by, priority, status) VALUES
    (1, 1, 9, 1, 'NORMAL', 'VERIFIED'),
    (2, 2, 10, 1, 'NORMAL', 'VERIFIED'),
    (3, 3, 11, 3, 'NORMAL', 'VERIFIED'),
    (4, 4, 8, 7, 'NORMAL', 'VERIFIED'),
    (5, 5, 8, 2, 'NORMAL', 'VERIFIED'),
    (6, 6, 8, 5, 'NORMAL', 'RESULTED'),
    (7, 7, 12, 6, 'NORMAL', 'VERIFIED'),
    (8, 10, 13, 2, 'NORMAL', 'ORDERED'),
    (9, 2, 9, 1, 'NORMAL', 'RESULTED'),
    (10, 3, 9, 3, 'NORMAL', 'VERIFIED');
SET IDENTITY_INSERT dbo.lab_orders OFF;

SET IDENTITY_INSERT dbo.lab_results ON;
INSERT INTO dbo.lab_results (result_id, lab_order_id, parameter_code, parameter_name, result_value, result_text, unit, ref_low, ref_high, is_abnormal, resulted_by, verified_by, verified_at) VALUES
    (1, 1, 'GLU', N'Glucose lúc đói', 5.4, NULL, 'mmol/L', 3.9, 5.6, 0, N'KTV. Phan Gia Huy', 1, '2023-05-20 11:00:00'),
    (2, 2, 'HBA1C', N'HbA1c', 7.2, NULL, '%', 4.0, 5.6, 1, N'KTV. Phan Gia Huy', 1, '2023-05-20 11:00:00'),
    (3, 3, 'CHOL', N'Cholesterol toàn phần', 6.1, NULL, 'mmol/L', NULL, 5.2, 1, N'KTV. Phan Gia Huy', 3, '2023-05-20 11:00:00'),
    (4, 3, 'LDL', N'LDL-Cholesterol', 3.9, NULL, 'mmol/L', NULL, 3.4, 1, N'KTV. Phan Gia Huy', 3, '2023-05-20 11:00:00'),
    (5, 4, 'WBC', N'Bạch cầu (WBC)', 11.8, NULL, 'G/L', 4.0, 10.0, 1, N'KTV. Phan Gia Huy', 7, '2023-05-20 11:00:00'),
    (6, 4, 'HGB', N'Huyết sắc tố (HGB)', 138, NULL, 'g/L', 130, 170, 0, N'KTV. Phan Gia Huy', 7, '2023-05-20 11:00:00'),
    (7, 5, 'WBC', N'Bạch cầu (WBC)', 6.2, NULL, 'G/L', 4.0, 10.0, 0, N'KTV. Phan Gia Huy', 2, '2023-05-20 11:00:00'),
    (8, 5, 'HGB', N'Huyết sắc tố (HGB)', 102, NULL, 'g/L', 120, 155, 1, N'KTV. Phan Gia Huy', 2, '2023-05-20 11:00:00'),
    (9, 5, 'PLT', N'Tiểu cầu (PLT)', 265, NULL, 'G/L', 150, 400, 0, N'KTV. Phan Gia Huy', 2, '2023-05-20 11:00:00'),
    (10, 6, 'WBC', N'Bạch cầu (WBC)', 8.9, NULL, 'G/L', 4.0, 10.0, 0, N'KTV. Phan Gia Huy', NULL, NULL),
    (11, 7, 'ALT', N'ALT (GPT)', 68, NULL, 'U/L', 5, 40, 1, N'KTV. Phan Gia Huy', 6, '2023-05-20 11:00:00'),
    (12, 7, 'AST', N'AST (GOT)', 35, NULL, 'U/L', 5, 40, 0, N'KTV. Phan Gia Huy', 6, '2023-05-20 11:00:00'),
    (13, 9, 'GLU', N'Glucose lúc đói', 6.8, NULL, 'mmol/L', 3.9, 5.6, 1, N'KTV. Phan Gia Huy', NULL, NULL),
    (14, 10, 'GLU', N'Glucose lúc đói', 5.1, NULL, 'mmol/L', 3.9, 5.6, 0, N'KTV. Phan Gia Huy', 3, '2023-05-20 11:00:00');
SET IDENTITY_INSERT dbo.lab_results OFF;

SET IDENTITY_INSERT dbo.medications ON;
INSERT INTO dbo.medications (medication_id, medication_code, medication_name, active_ingredient, dosage_form, strength, unit, unit_price, is_insurance_covered) VALUES
    (1, 'TH001', N'Amlodipine 5mg', N'Amlodipine', N'Viên nén', '5mg', N'viên', 1500, 1),
    (2, 'TH002', N'Losartan 50mg', N'Losartan', N'Viên nén bao phim', '50mg', N'viên', 2500, 1),
    (3, 'TH003', N'Metformin 500mg', N'Metformin', N'Viên nén', '500mg', N'viên', 800, 1),
    (4, 'TH004', N'Atorvastatin 10mg', N'Atorvastatin', N'Viên nén bao phim', '10mg', N'viên', 3000, 1),
    (5, 'TH005', N'Paracetamol 500mg', N'Paracetamol', N'Viên nén', '500mg', N'viên', 500, 1),
    (6, 'TH006', N'Amoxicillin 500mg', N'Amoxicillin', N'Viên nang', '500mg', N'viên', 1200, 1),
    (7, 'TH007', N'Omeprazole 20mg', N'Omeprazole', N'Viên nang', '20mg', N'viên', 2000, 1),
    (8, 'TH008', N'Montelukast 10mg', N'Montelukast', N'Viên nén bao phim', '10mg', N'viên', 6000, 1),
    (9, 'TH009', N'Cetirizine 10mg', N'Cetirizine', N'Viên nén bao phim', '10mg', N'viên', 1000, 1),
    (10, 'TH010', N'Azithromycin 250mg', N'Azithromycin', N'Viên nén bao phim', '250mg', N'viên', 5000, 1),
    (11, 'TH011', N'Ibuprofen 400mg', N'Ibuprofen', N'Viên nén bao phim', '400mg', N'viên', 900, 1),
    (12, 'TH012', N'Vitamin C 1000mg sủi', N'Acid ascorbic', N'Viên sủi', '1000mg', N'viên', 4500, 0);
SET IDENTITY_INSERT dbo.medications OFF;

SET IDENTITY_INSERT dbo.prescriptions ON;
INSERT INTO dbo.prescriptions (prescription_id, prescription_code, visit_id, doctor_id, status, issued_at) VALUES
    (1, 'DT2023-0001', 1, 1, 'DISPENSED', '2023-05-20 09:30:00'),
    (2, 'DT2023-0002', 2, 1, 'DISPENSED', '2023-05-20 09:30:00'),
    (3, 'DT2023-0003', 3, 3, 'ISSUED', '2023-05-20 09:30:00'),
    (4, 'DT2023-0004', 4, 7, 'ISSUED', '2023-05-20 09:30:00'),
    (5, 'DT2023-0005', 6, 5, 'DRAFT', NULL),
    (6, 'DT2023-0006', 7, 6, 'ISSUED', '2023-05-20 09:30:00'),
    (7, 'DT2023-0007', 9, 10, 'ISSUED', '2023-05-20 09:30:00');
SET IDENTITY_INSERT dbo.prescriptions OFF;

SET IDENTITY_INSERT dbo.prescription_items ON;
INSERT INTO dbo.prescription_items (item_id, prescription_id, medication_id, dose_per_intake, intakes_per_day, duration_days, total_quantity, instructions) VALUES
    (1, 1, 1, 1.00, 1, 30, 30.00, N'Uống buổi sáng, sau ăn'),
    (2, 2, 2, 1.00, 1, 30, 30.00, N'Uống buổi tối'),
    (3, 2, 3, 1.00, 2, 30, 60.00, N'Uống sau ăn sáng và tối'),
    (4, 3, 4, 1.00, 1, 30, 30.00, N'Uống buổi tối trước ngủ'),
    (5, 3, 2, 1.00, 1, 30, 30.00, N'Uống buổi sáng'),
    (6, 4, 10, 1.00, 1, 3, 3.00, N'Uống sau ăn, đủ 3 ngày'),
    (7, 4, 5, 1.00, 3, 3, 9.00, N'Uống khi sốt trên 38.5 độ'),
    (8, 5, 8, 1.00, 1, 14, 14.00, N'Uống buổi tối'),
    (9, 6, 7, 1.00, 2, 14, 28.00, N'Uống trước ăn 30 phút'),
    (10, 7, 6, 1.00, 3, 5, 15.00, N'Uống sau ăn'),
    (11, 1, 12, 1.00, 1, 10, 10.00, N'Pha 1 viên với 200ml nước, uống sáng');
SET IDENTITY_INSERT dbo.prescription_items OFF;

SET IDENTITY_INSERT dbo.invoices ON;
INSERT INTO dbo.invoices (invoice_id, invoice_no, visit_id, patient_id, insurance_id, referral_type, coverage_percent_snapshot, effective_coverage_percent, services_total, labs_total, meds_total, gross_total, insurance_payable, discount_amount, patient_copay, insurance_claim_status, status, issued_at, due_date) VALUES
    (1, 'HD2023-0001', 1, 1, 1, 'CORRECT', 80, 80.00, 400000.00, 60000.00, 90000.00, 550000.00, 204000.00, 0.00, 346000.00, 'APPROVED', 'PAID', '2023-05-16 12:00:00', '2023-05-16'),
    (2, 'HD2023-0002', 2, 3, 3, 'CORRECT', 80, 80.00, 150000.00, 210000.00, 123000.00, 483000.00, 386400.00, 0.00, 96600.00, 'APPROVED', 'PAID', '2023-05-16 12:00:00', '2023-05-16'),
    (3, 'HD2023-0003', 3, 11, 11, 'WRONG', 95, 38.00, 300000.00, 240000.00, 165000.00, 705000.00, 267900.00, 0.00, 437100.00, 'APPROVED', 'PAID', '2023-05-16 12:00:00', '2023-05-16'),
    (4, 'HD2023-0004', 4, 9, 9, 'CORRECT', 100, 100.00, 120000.00, 120000.00, 19500.00, 259500.00, 259500.00, 0.00, 0.00, 'SENT', 'ISSUED', '2023-05-16 12:00:00', '2023-05-16'),
    (5, 'HD2023-0005', 5, 2, 2, 'CORRECT', 95, 95.00, 150000.00, 120000.00, 0.00, 270000.00, 256500.00, 0.00, 13500.00, 'APPROVED', 'PAID', '2023-05-17 12:00:00', '2023-05-17'),
    (6, 'HD2023-0006', 7, 13, NULL, 'CORRECT', NULL, 0.00, 980000.00, 140000.00, 56000.00, 1176000.00, 0.00, 0.00, 1176000.00, 'NOT_SENT', 'PARTIALLY_PAID', '2023-05-18 12:00:00', '2023-05-18'),
    (7, 'HD2023-0007', 6, 6, 6, 'EMERGENCY', 100, 100.00, 330000.00, 120000.00, 0.00, 450000.00, 450000.00, 0.00, 0.00, 'APPROVED', 'PAID', '2023-05-17 12:00:00', '2023-05-17');
SET IDENTITY_INSERT dbo.invoices OFF;

SET IDENTITY_INSERT dbo.invoice_items ON;
INSERT INTO dbo.invoice_items (invoice_item_id, invoice_id, item_type, source_id, description, quantity, unit_price, line_total, is_insurance_eligible) VALUES
    (1, 1, 'SERVICE', 1, N'Khám Nội tổng quát', 1.00, 150000.00, 150000.00, 1),
    (2, 1, 'SERVICE', 17, N'Tư vấn dinh dưỡng chuyên sâu', 1.00, 250000.00, 250000.00, 0),
    (3, 1, 'LAB', 1, N'Đường huyết lúc đói', 1.00, 60000.00, 60000.00, 1),
    (4, 1, 'MED', 1, N'Amlodipine 5mg', 30.00, 1500.00, 45000.00, 1),
    (5, 1, 'MED', 11, N'Vitamin C 1000mg sủi', 10.00, 4500.00, 45000.00, 0),
    (6, 2, 'SERVICE', 2, N'Khám Nội tổng quát', 1.00, 150000.00, 150000.00, 1),
    (7, 2, 'LAB', 2, N'HbA1c', 1.00, 150000.00, 150000.00, 1),
    (8, 2, 'LAB', 9, N'Đường huyết lúc đói', 1.00, 60000.00, 60000.00, 1),
    (9, 2, 'MED', 2, N'Losartan 50mg', 30.00, 2500.00, 75000.00, 1),
    (10, 2, 'MED', 3, N'Metformin 500mg', 60.00, 800.00, 48000.00, 1),
    (11, 3, 'SERVICE', 3, N'Khám Tim mạch', 1.00, 200000.00, 200000.00, 1),
    (12, 3, 'SERVICE', 4, N'Điện tâm đồ (ECG)', 1.00, 100000.00, 100000.00, 1),
    (13, 3, 'LAB', 3, N'Bộ mỡ máu (Lipid)', 1.00, 180000.00, 180000.00, 1),
    (14, 3, 'LAB', 10, N'Đường huyết lúc đói', 1.00, 60000.00, 60000.00, 1),
    (15, 3, 'MED', 4, N'Atorvastatin 10mg', 30.00, 3000.00, 90000.00, 1),
    (16, 3, 'MED', 5, N'Losartan 50mg', 30.00, 2500.00, 75000.00, 1),
    (17, 4, 'SERVICE', 5, N'Khám Nhi khoa', 1.00, 120000.00, 120000.00, 1),
    (18, 4, 'LAB', 4, N'Tổng phân tích tế bào máu (CBC)', 1.00, 120000.00, 120000.00, 1),
    (19, 4, 'MED', 6, N'Azithromycin 250mg', 3.00, 5000.00, 15000.00, 1),
    (20, 4, 'MED', 7, N'Paracetamol 500mg', 9.00, 500.00, 4500.00, 1),
    (21, 5, 'SERVICE', 6, N'Khám Nội tổng quát', 1.00, 150000.00, 150000.00, 1),
    (22, 5, 'LAB', 5, N'Tổng phân tích tế bào máu (CBC)', 1.00, 120000.00, 120000.00, 1),
    (23, 6, 'SERVICE', 9, N'Khám Tiêu hóa', 1.00, 180000.00, 180000.00, 1),
    (24, 6, 'SERVICE', 10, N'Nội soi dạ dày gây mê', 1.00, 800000.00, 800000.00, 1),
    (25, 6, 'LAB', 7, N'Men gan (AST/ALT)', 1.00, 140000.00, 140000.00, 1),
    (26, 6, 'MED', 9, N'Omeprazole 20mg', 28.00, 2000.00, 56000.00, 1),
    (27, 7, 'SERVICE', 7, N'Khám Hô hấp', 1.00, 180000.00, 180000.00, 1),
    (28, 7, 'SERVICE', 8, N'X-quang ngực thẳng', 1.00, 150000.00, 150000.00, 1),
    (29, 7, 'LAB', 6, N'Tổng phân tích tế bào máu (CBC)', 1.00, 120000.00, 120000.00, 1);
SET IDENTITY_INSERT dbo.invoice_items OFF;

SET IDENTITY_INSERT dbo.payments ON;
INSERT INTO dbo.payments (payment_id, invoice_id, payer_type, amount, payment_method, transaction_ref, paid_at, received_by) VALUES
    (1, 1, 'PATIENT', 346000.00, 'TRANSFER', 'CK000001', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (2, 1, 'INSURANCE', 204000.00, 'INSURANCE_CLAIM', 'BHYT000001', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (3, 2, 'PATIENT', 96600.00, 'TRANSFER', 'CK000002', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (4, 2, 'INSURANCE', 386400.00, 'INSURANCE_CLAIM', 'BHYT000002', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (5, 3, 'PATIENT', 437100.00, 'TRANSFER', 'CK000003', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (6, 3, 'INSURANCE', 267900.00, 'INSURANCE_CLAIM', 'BHYT000003', '2023-05-16 12:30:00', N'Nguyễn Khánh Linh'),
    (7, 5, 'PATIENT', 13500.00, 'TRANSFER', 'CK000005', '2023-05-17 12:30:00', N'Nguyễn Khánh Linh'),
    (8, 5, 'INSURANCE', 256500.00, 'INSURANCE_CLAIM', 'BHYT000005', '2023-05-17 12:30:00', N'Nguyễn Khánh Linh'),
    (9, 6, 'PATIENT', 588000.00, 'CASH', NULL, '2023-05-18 12:30:00', N'Nguyễn Khánh Linh'),
    (10, 7, 'INSURANCE', 450000.00, 'INSURANCE_CLAIM', 'BHYT000007', '2023-05-17 12:30:00', N'Nguyễn Khánh Linh');
SET IDENTITY_INSERT dbo.payments OFF;

IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_prescription_items_block_issued')
    ENABLE TRIGGER dbo.trg_prescription_items_block_issued ON dbo.prescription_items;
GO

COMMIT TRANSACTION;
GO

PRINT N'02_seed.sql: Da nap du lieu mau MediCore.';
SELECT (SELECT COUNT(*) FROM dbo.patients) AS patients,
       (SELECT COUNT(*) FROM dbo.doctors) AS doctors,
       (SELECT COUNT(*) FROM dbo.visits) AS visits,
       (SELECT COUNT(*) FROM dbo.invoices) AS invoices;
GO
