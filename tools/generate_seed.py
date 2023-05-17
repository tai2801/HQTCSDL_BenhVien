#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_seed.py - Sinh file database/02_seed.sql cho CSDL Benh vien MediCore.
Du lieu mau duoc dinh nghia mot lan tai day; cac so lieu phu thuoc
(booked_count cua ca kham, tong tien hoa don, phan BHYT chi tra, dong chi tra)
duoc TINH TU DONG de seed luon nhat quan - khong cong tay.

Chay:  python3 tools/generate_seed.py
"""
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "database" / "02_seed.sql"


def q(s):
    """SQL string literal (N'...' cho unicode)."""
    if s is None:
        return "NULL"
    return "N'" + str(s).replace("'", "''") + "'"


def v(s):
    """SQL string literal thuong (varchar)."""
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"


def money(x):
    return f"{Decimal(x):.2f}"


# ---------------------------------------------------------------- departments
DEPARTMENTS = [
    (1, "GEN",  "Nội tổng quát", "Khám và điều trị bệnh nội khoa tổng quát"),
    (2, "CARD", "Tim mạch",      "Khám, chẩn đoán bệnh tim mạch"),
    (3, "RESP", "Hô hấp",        "Bệnh lý đường hô hấp và phổi"),
    (4, "GI",   "Tiêu hóa",      "Bệnh lý tiêu hóa, gan mật"),
    (5, "PEDI", "Nhi khoa",      "Khám và điều trị cho trẻ em"),
    (6, "DERM", "Da liễu",       "Bệnh lý da và phần phụ của da"),
    (7, "ENT",  "Tai Mũi Họng",  "Bệnh lý tai, mũi, họng"),
]

# ------------------------------------------------------------------- app_users
USERS = [
    (1,  "admin",        "HASH_PLACEHOLDER_ADMIN",  "Quản trị hệ thống", "ADMIN"),
    (2,  "bs.tuan",      "HASH_PLACEHOLDER_DOCTOR", "BS. Phạm Minh Tuấn", "DOCTOR"),
    (3,  "bs.lan",       "HASH_PLACEHOLDER_DOCTOR", "BS. Trần Thu Lan", "DOCTOR"),
    (4,  "bs.hung",      "HASH_PLACEHOLDER_DOCTOR", "BS. Nguyễn Quốc Hùng", "DOCTOR"),
    (5,  "bs.mai",       "HASH_PLACEHOLDER_DOCTOR", "BS. Lê Ngọc Mai", "DOCTOR"),
    (6,  "bs.son",       "HASH_PLACEHOLDER_DOCTOR", "BS. Vũ Hải Sơn", "DOCTOR"),
    (7,  "bs.thao",      "HASH_PLACEHOLDER_DOCTOR", "BS. Đặng Phương Thảo", "DOCTOR"),
    (8,  "bs.khoa",      "HASH_PLACEHOLDER_DOCTOR", "BS. Bùi Anh Khoa", "DOCTOR"),
    (9,  "bs.nhi",       "HASH_PLACEHOLDER_DOCTOR", "BS. Hồ Tuyết Nhi", "DOCTOR"),
    (10, "bs.duyen",     "HASH_PLACEHOLDER_DOCTOR", "BS. Ngô Mỹ Duyên", "DOCTOR"),
    (11, "bs.phong",     "HASH_PLACEHOLDER_DOCTOR", "BS. Dương Văn Phong", "DOCTOR"),
    (12, "bs.trang",     "HASH_PLACEHOLDER_DOCTOR", "BS. Trịnh Thu Trang", "DOCTOR"),
    (13, "ktv.huy",      "HASH_PLACEHOLDER_TECH",   "KTV. Phan Gia Huy", "LAB_TECH"),
    (14, "tn.linh",      "HASH_PLACEHOLDER_CASH",   "Nguyễn Khánh Linh", "CASHIER"),
    (15, "lt.vy",        "HASH_PLACEHOLDER_RECEP",  "Phạm Thảo Vy", "RECEPTIONIST"),
]

# --------------------------------------------------------------------- doctors
# (id, user_id, dept_id, name, title, license, phone)
DOCTORS = [
    (1,  2,  1, "Phạm Minh Tuấn",   "ThS.BS",  "CCHN-00101", "0903101001"),
    (2,  3,  1, "Trần Thu Lan",     "BS.CKI",  "CCHN-00102", "0903101002"),
    (3,  4,  2, "Nguyễn Quốc Hùng", "BS.CKII", "CCHN-00103", "0903101003"),
    (4,  5,  2, "Lê Ngọc Mai",      "ThS.BS",  "CCHN-00104", "0903101004"),
    (5,  6,  3, "Vũ Hải Sơn",       "BS.CKI",  "CCHN-00105", "0903101005"),
    (6,  7,  4, "Đặng Phương Thảo", "ThS.BS",  "CCHN-00106", "0903101006"),
    (7,  8,  5, "Bùi Anh Khoa",     "BS",      "CCHN-00107", "0903101007"),
    (8,  9,  5, "Hồ Tuyết Nhi",     "BS.CKI",  "CCHN-00108", "0903101008"),
    (9,  10, 6, "Ngô Mỹ Duyên",     "BS",      "CCHN-00109", "0903101009"),
    (10, 11, 7, "Dương Văn Phong",  "BS.CKI",  "CCHN-00110", "0903101010"),
    (11, 12, 1, "Trịnh Thu Trang",  "BS",      "CCHN-00111", "0903101011"),
]

# ----------------------------------------------------------------------- rooms
ROOMS = [
    (1, "P101", "Phòng khám Nội 1",   1, 1),
    (2, "P102", "Phòng khám Tim mạch", 2, 1),
    (3, "P103", "Phòng khám Hô hấp",   3, 1),
    (4, "P104", "Phòng khám Tiêu hóa", 4, 2),
    (5, "P105", "Phòng khám Nhi",      5, 2),
    (6, "P106", "Phòng khám Da liễu",  6, 2),
    (7, "P107", "Phòng khám Tai Mũi Họng", 7, 3),
]

# -------------------------------------------------------------------- patients
# (id, code, cccd, name, dob, gender, phone, blood)
PATIENTS = [
    (1,  "BN2023-0001", "079078001201", "Nguyễn Văn An",     "1978-05-12", "MALE",   "0912001001", "O+"),
    (2,  "BN2023-0002", "052182002302", "Trần Thị Bình",     "1982-09-03", "FEMALE", "0912001002", "A+"),
    (3,  "BN2023-0003", "079065003403", "Lê Văn Cường",      "1965-01-25", "MALE",   "0912001003", "B+"),
    (4,  "BN2023-0004", "031190004504", "Phạm Thị Dung",     "1990-07-18", "FEMALE", "0912001004", "O+"),
    (5,  "BN2023-0005", "079201005605", "Hoàng Minh Đức",    "2001-03-30", "MALE",   "0912001005", "AB+"),
    (6,  "BN2023-0006", "052175006706", "Vũ Thị Hạnh",       "1975-11-08", "FEMALE", "0912001006", "A-"),
    (7,  "BN2023-0007", "079088007807", "Đặng Quốc Khánh",   "1988-06-15", "MALE",   "0912001007", "B-"),
    (8,  "BN2023-0008", "031195008908", "Ngô Thị Lan Anh",   "1995-02-20", "FEMALE", "0912001008", "O-"),
    (9,  "BN2023-0009", "079201510109", "Bùi Gia Bảo",       "2015-08-11", "MALE",   "0912001009", "A+"),
    (10, "BN2023-0010", "052201811010", "Hồ Ngọc Châu",      "2018-04-05", "FEMALE", "0912001010", "B+"),
    (11, "BN2023-0011", "079060011111", "Dương Văn Em",      "1960-12-01", "MALE",   "0912001011", "O+"),
    (12, "BN2023-0012", "031199012212", "Trịnh Thị Phương",  "1999-10-22", "FEMALE", "0912001012", "A+"),
    (13, "BN2023-0013", "079085013313", "Phan Văn Giang",    "1985-05-27", "MALE",   "0912001013", "AB-"),
    (14, "BN2023-0014", "052193014414", "Lý Thị Hoa",        "1993-01-14", "FEMALE", "0912001014", "O+"),
    (15, "BN2023-0015", "079070015515", "Chu Văn Ích",       "1970-08-19", "MALE",   "0912001015", "B+"),
    (16, "BN2023-0016", "031200016616", "Đỗ Thuỳ Dương",     "2000-06-09", "FEMALE", "0912001016", "A-"),
]

# (id, patient_id, card_no, coverage, facility, from, to)
INSURANCE = [
    (1,  1,  "GD479001000001", 80,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (2,  2,  "HT279002000002", 95,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (3,  3,  "GD479003000003", 80,  "Bệnh viện Quận 1",   "2023-01-01", "2023-12-31"),
    (4,  4,  "SV479004000004", 80,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (5,  5,  "SV479005000005", 80,  "Trường ĐH Công nghiệp Thực phẩm TP.HCM", "2023-01-01", "2023-12-31"),
    (6,  6,  "HT379006000006", 100, "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (7,  7,  "GD479007000007", 80,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (8,  8,  "GD479008000008", 80,  "Bệnh viện Bình Thạnh", "2023-01-01", "2023-12-31"),
    (9,  9,  "TE179009000009", 100, "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (10, 10, "TE179010000010", 100, "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (11, 11, "HT279011000011", 95,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
    (12, 12, "GD479012000012", 80,  "Bệnh viện MediCore", "2023-01-01", "2023-12-31"),
]

ALLERGIES = [
    (1, 4,  "Penicillin",  "Phát ban, ngứa toàn thân sau khi dùng Amoxicillin", "SEVERE"),
    (2, 8,  "NSAID",       "Đau dạ dày dữ dội khi dùng Ibuprofen", "MODERATE"),
    (3, 13, "Hải sản",     "Nổi mề đay sau khi ăn tôm", "MILD"),
]

# ------------------------------------------------------------------ schedules
# (id, doctor, room, date, shift, start, end, capacity, status)
SCHEDULES = [
    (1,  1, 1, "2023-05-16", "MORNING",   "07:30", "11:30", 25, "CLOSED"),
    (2,  3, 2, "2023-05-16", "MORNING",   "07:30", "11:30", 20, "CLOSED"),
    (3,  7, 5, "2023-05-16", "AFTERNOON", "13:00", "17:00", 30, "CLOSED"),
    (4,  2, 1, "2023-05-17", "MORNING",   "07:30", "11:30", 25, "CLOSED"),
    (5,  5, 3, "2023-05-17", "MORNING",   "07:30", "11:30", 20, "CLOSED"),
    (6,  6, 4, "2023-05-18", "AFTERNOON", "13:00", "17:00", 18, "CLOSED"),
    (7,  9, 6, "2023-05-18", "MORNING",   "07:30", "11:30", 22, "CLOSED"),
    (8,  10, 7, "2023-05-19", "MORNING",  "07:30", "11:30", 22, "CLOSED"),
    (9,  1, 1, "2023-05-23", "MORNING",   "07:30", "11:30", 25, "OPEN"),
    (10, 4, 2, "2023-05-23", "AFTERNOON", "13:00", "17:00", 20, "OPEN"),
    (11, 8, 5, "2023-05-24", "MORNING",   "07:30", "11:30", 30, "OPEN"),
    (12, 11, 1, "2023-05-24", "AFTERNOON", "13:00", "17:00", 25, "OPEN"),
]

# --------------------------------------------------------------- appointments
# (id, schedule, patient, reason, status)  -- appointment_no sinh tu dong
APPOINTMENTS = [
    (1,  1, 1,  "Đau đầu, chóng mặt, đo huyết áp cao tại nhà", "COMPLETED"),
    (2,  1, 3,  "Tái khám tăng huyết áp", "COMPLETED"),
    (3,  2, 11, "Đau ngực khi gắng sức", "COMPLETED"),
    (4,  3, 9,  "Sốt cao, ho nhiều", "COMPLETED"),
    (5,  4, 2,  "Mệt mỏi, nghi thiếu máu", "COMPLETED"),
    (6,  5, 6,  "Ho kéo dài 3 tuần", "COMPLETED"),
    (7,  6, 13, "Đau thượng vị, ợ chua", "COMPLETED"),
    (8,  7, 14, "Ngứa da, nổi mẩn đỏ", "COMPLETED"),
    (9,  8, 16, "Đau tai phải, ù tai", "COMPLETED"),
    (10, 9, 5,  "Khám sức khỏe định kỳ", "BOOKED"),
    (11, 9, 7,  "Đau lưng, tê chân", "BOOKED"),
    (12, 10, 12, "Hồi hộp, tim đập nhanh", "BOOKED"),
    (13, 11, 10, "Ho, sổ mũi", "BOOKED"),
    (14, 12, 15, "Đau dạ dày tái phát", "CANCELLED"),
    (15, 3, 10, "Khám tổng quát cho bé", "NO_SHOW"),
]
ACTIVE_APPT = {"BOOKED", "CHECKED_IN", "COMPLETED", "NO_SHOW"}

# ---------------------------------------------------------------------- visits
# (id, patient, appointment_id|None, doctor, room, date, complaint, status)
VISITS = [
    (1,  1,  1,    1, 1, "2023-05-16", "Đau đầu, chóng mặt 2 ngày", "COMPLETED"),
    (2,  3,  2,    1, 1, "2023-05-16", "Tái khám tăng huyết áp sau 1 tháng", "COMPLETED"),
    (3,  11, 3,    3, 2, "2023-05-16", "Đau ngực trái khi leo cầu thang", "COMPLETED"),
    (4,  9,  4,    7, 5, "2023-05-16", "Sốt 39 độ, ho đờm 3 ngày", "COMPLETED"),
    (5,  2,  5,    2, 1, "2023-05-17", "Mệt mỏi, da xanh, chóng mặt khi đứng", "COMPLETED"),
    (6,  6,  6,    5, 3, "2023-05-17", "Ho khan kéo dài, khó thở nhẹ về đêm", "COMPLETED"),
    (7,  13, 7,    6, 4, "2023-05-18", "Đau thượng vị âm ỉ, ợ chua sau ăn", "COMPLETED"),
    (8,  14, 8,    9, 6, "2023-05-18", "Ngứa và nổi mẩn đỏ hai tay 1 tuần", "COMPLETED"),
    (9,  16, 9,    10, 7, "2023-05-19", "Đau tai phải, nghe kém 4 ngày", "COMPLETED"),
    (10, 4,  None, 2, 1, "2023-05-20", "Đau bụng dưới, rối loạn tiêu hóa", "IN_PROGRESS"),
    (11, 8,  None, 4, 2, "2023-05-20", "Hồi hộp từng cơn, lo âu", "OPEN"),
    (12, 15, None, 11, 1, "2023-05-20", "Đau dạ dày, buồn nôn", "OPEN"),
    (13, 7,  None, 1, 1, "2023-05-20", "Đau lưng lan xuống chân phải", "CANCELLED"),
]

# ------------------------------------------------------------- medical records
# (id, visit, status) - noi dung sinh ngan gon
RECORDS = [
    (1, 1, "LOCKED"), (2, 2, "LOCKED"), (3, 3, "LOCKED"), (4, 4, "LOCKED"),
    (5, 5, "LOCKED"), (6, 6, "DRAFT"), (7, 7, "LOCKED"), (8, 8, "DRAFT"),
    (9, 9, "LOCKED"), (10, 10, "DRAFT"),
]
ADDENDA = [
    (1, 2, 1, "Bổ sung kết quả đo huyết áp tại nhà ngày 20/11: trung bình 128/82 mmHg, đáp ứng điều trị tốt.",
     "Bệnh nhân gửi sổ theo dõi huyết áp sau khi hồ sơ đã khóa", "APPROVED", 2),
    (2, 3, 3, "Bổ sung diễn giải kết quả điện tâm đồ: nhịp xoang, trục trung gian, không có đoạn ST chênh.",
     "Kết quả ECG trả về sau thời điểm khóa hồ sơ", "PENDING", None),
]

# ------------------------------------------------------------------ diagnoses
# (visit, icd, name, type)
DIAGNOSES = [
    (1, "I10", "Tăng huyết áp vô căn", "PRIMARY"),
    (1, "R42", "Chóng mặt", "SECONDARY"),
    (2, "I10", "Tăng huyết áp vô căn", "PRIMARY"),
    (2, "E11", "Đái tháo đường type 2", "SECONDARY"),
    (3, "I25.1", "Bệnh tim thiếu máu cục bộ mạn", "PRIMARY"),
    (3, "E78.5", "Rối loạn lipid máu", "SECONDARY"),
    (4, "J20", "Viêm phế quản cấp", "PRIMARY"),
    (5, "D64.9", "Thiếu máu, không đặc hiệu", "PRIMARY"),
    (6, "J45", "Hen phế quản", "PRIMARY"),
    (7, "K29.5", "Viêm dạ dày mạn", "PRIMARY"),
    (8, "L20", "Viêm da cơ địa", "PRIMARY"),
    (9, "H66.9", "Viêm tai giữa, không đặc hiệu", "PRIMARY"),
    (10, "R10.3", "Đau vùng chậu và đáy chậu", "PRIMARY"),
    (11, "R00.2", "Đánh trống ngực", "PRIMARY"),
]

# -------------------------------------------------------------------- services
# (id, code, name, dept, type, price, insurance_covered)
SERVICES = [
    (1,  "DV001", "Khám Nội tổng quát", 1, "CONSULT", 150000, 1),
    (2,  "DV002", "Khám Tim mạch", 2, "CONSULT", 200000, 1),
    (3,  "DV003", "Khám Hô hấp", 3, "CONSULT", 180000, 1),
    (4,  "DV004", "Khám Tiêu hóa", 4, "CONSULT", 180000, 1),
    (5,  "DV005", "Khám Nhi khoa", 5, "CONSULT", 120000, 1),
    (6,  "DV006", "Khám Da liễu", 6, "CONSULT", 150000, 1),
    (7,  "DV007", "Khám Tai Mũi Họng", 7, "CONSULT", 150000, 1),
    (8,  "XN001", "Tổng phân tích tế bào máu (CBC)", 1, "LAB", 120000, 1),
    (9,  "XN002", "Đường huyết lúc đói", 1, "LAB", 60000, 1),
    (10, "XN003", "HbA1c", 1, "LAB", 150000, 1),
    (11, "XN004", "Bộ mỡ máu (Lipid)", 2, "LAB", 180000, 1),
    (12, "XN005", "Men gan (AST/ALT)", 4, "LAB", 140000, 1),
    (13, "XN006", "Tổng phân tích nước tiểu", 1, "LAB", 70000, 1),
    (14, "CD001", "Điện tâm đồ (ECG)", 2, "IMAGING", 100000, 1),
    (15, "CD002", "X-quang ngực thẳng", 3, "IMAGING", 150000, 1),
    (16, "CD003", "Siêu âm ổ bụng tổng quát", 4, "IMAGING", 200000, 1),
    (17, "TT001", "Nội soi dạ dày gây mê", 4, "PROCEDURE", 800000, 1),
    (18, "DV008", "Tư vấn dinh dưỡng chuyên sâu", 1, "CONSULT", 250000, 0),
]
SVC = {s[0]: s for s in SERVICES}

# (visit_service_id, visit, service, qty)
VISIT_SERVICES = [
    (1, 1, 1, 1), (2, 2, 1, 1), (3, 3, 2, 1), (4, 3, 14, 1),
    (5, 4, 5, 1), (6, 5, 1, 1), (7, 6, 3, 1), (8, 6, 15, 1),
    (9, 7, 4, 1), (10, 7, 17, 1), (11, 8, 6, 1), (12, 9, 7, 1),
    (13, 10, 1, 1), (14, 11, 2, 1), (15, 11, 14, 1), (16, 12, 1, 1),
    (17, 1, 18, 1),  # Tu van dinh duong - BHYT khong chi tra
]

# ------------------------------------------------------------------ lab orders
# (id, visit, service, status)
LAB_ORDERS = [
    (1, 1, 9, "VERIFIED"), (2, 2, 10, "VERIFIED"), (3, 3, 11, "VERIFIED"),
    (4, 4, 8, "VERIFIED"), (5, 5, 8, "VERIFIED"), (6, 6, 8, "RESULTED"),
    (7, 7, 12, "VERIFIED"), (8, 10, 13, "ORDERED"), (9, 2, 9, "RESULTED"),
    (10, 3, 9, "VERIFIED"),
]
# (order, param_code, param_name, value, text, unit, ref_low, ref_high)
LAB_RESULTS = [
    (1, "GLU", "Glucose lúc đói", 5.4, None, "mmol/L", 3.9, 5.6),
    (2, "HBA1C", "HbA1c", 7.2, None, "%", 4.0, 5.6),
    (3, "CHOL", "Cholesterol toàn phần", 6.1, None, "mmol/L", None, 5.2),
    (3, "LDL", "LDL-Cholesterol", 3.9, None, "mmol/L", None, 3.4),
    (4, "WBC", "Bạch cầu (WBC)", 11.8, None, "G/L", 4.0, 10.0),
    (4, "HGB", "Huyết sắc tố (HGB)", 138, None, "g/L", 130, 170),
    (5, "WBC", "Bạch cầu (WBC)", 6.2, None, "G/L", 4.0, 10.0),
    (5, "HGB", "Huyết sắc tố (HGB)", 102, None, "g/L", 120, 155),
    (5, "PLT", "Tiểu cầu (PLT)", 265, None, "G/L", 150, 400),
    (6, "WBC", "Bạch cầu (WBC)", 8.9, None, "G/L", 4.0, 10.0),
    (7, "ALT", "ALT (GPT)", 68, None, "U/L", 5, 40),
    (7, "AST", "AST (GOT)", 35, None, "U/L", 5, 40),
    (9, "GLU", "Glucose lúc đói", 6.8, None, "mmol/L", 3.9, 5.6),
    (10, "GLU", "Glucose lúc đói", 5.1, None, "mmol/L", 3.9, 5.6),
]

# ----------------------------------------------------------------- medications
# (id, code, name, ingredient, form, strength, unit, price, covered)
MEDICATIONS = [
    (1,  "TH001", "Amlodipine 5mg", "Amlodipine", "Viên nén", "5mg", "viên", 1500, 1),
    (2,  "TH002", "Losartan 50mg", "Losartan", "Viên nén bao phim", "50mg", "viên", 2500, 1),
    (3,  "TH003", "Metformin 500mg", "Metformin", "Viên nén", "500mg", "viên", 800, 1),
    (4,  "TH004", "Atorvastatin 10mg", "Atorvastatin", "Viên nén bao phim", "10mg", "viên", 3000, 1),
    (5,  "TH005", "Paracetamol 500mg", "Paracetamol", "Viên nén", "500mg", "viên", 500, 1),
    (6,  "TH006", "Amoxicillin 500mg", "Amoxicillin", "Viên nang", "500mg", "viên", 1200, 1),
    (7,  "TH007", "Omeprazole 20mg", "Omeprazole", "Viên nang", "20mg", "viên", 2000, 1),
    (8,  "TH008", "Montelukast 10mg", "Montelukast", "Viên nén bao phim", "10mg", "viên", 6000, 1),
    (9,  "TH009", "Cetirizine 10mg", "Cetirizine", "Viên nén bao phim", "10mg", "viên", 1000, 1),
    (10, "TH010", "Azithromycin 250mg", "Azithromycin", "Viên nén bao phim", "250mg", "viên", 5000, 1),
    (11, "TH011", "Ibuprofen 400mg", "Ibuprofen", "Viên nén bao phim", "400mg", "viên", 900, 1),
    (12, "TH012", "Vitamin C 1000mg sủi", "Acid ascorbic", "Viên sủi", "1000mg", "viên", 4500, 0),
]
MED = {m[0]: m for m in MEDICATIONS}

# --------------------------------------------------------------- prescriptions
# (id, visit, doctor, status)
PRESCRIPTIONS = [
    (1, 1, 1, "DISPENSED"), (2, 2, 1, "DISPENSED"), (3, 3, 3, "ISSUED"),
    (4, 4, 7, "ISSUED"), (5, 6, 5, "DRAFT"), (6, 7, 6, "ISSUED"),
    (7, 9, 10, "ISSUED"),
]
# (item_id, pres, med, dose, intakes/day, days, instructions)
PRESC_ITEMS = [
    (1, 1, 1, 1, 1, 30, "Uống buổi sáng, sau ăn"),
    (2, 2, 2, 1, 1, 30, "Uống buổi tối"),
    (3, 2, 3, 1, 2, 30, "Uống sau ăn sáng và tối"),
    (4, 3, 4, 1, 1, 30, "Uống buổi tối trước ngủ"),
    (5, 3, 2, 1, 1, 30, "Uống buổi sáng"),
    (6, 4, 10, 1, 1, 3, "Uống sau ăn, đủ 3 ngày"),
    (7, 4, 5, 1, 3, 3, "Uống khi sốt trên 38.5 độ"),
    (8, 5, 8, 1, 1, 14, "Uống buổi tối"),
    (9, 6, 7, 1, 2, 14, "Uống trước ăn 30 phút"),
    (10, 7, 6, 1, 3, 5, "Uống sau ăn"),
    (11, 1, 12, 1, 1, 10, "Pha 1 viên với 200ml nước, uống sáng"),
]

# -------------------------------------------------------------------- invoices
# (visit, referral, claim_status, status) - tien tinh tu dong o duoi
INVOICE_DEFS = [
    (1, "CORRECT",   "APPROVED", "PAID"),
    (2, "CORRECT",   "APPROVED", "PAID"),
    (3, "WRONG",     "APPROVED", "PAID"),
    (4, "CORRECT",   "SENT",     "ISSUED"),
    (5, "CORRECT",   "APPROVED", "PAID"),
    (7, "CORRECT",   "NOT_SENT", "PARTIALLY_PAID"),  # BN khong the BHYT, tra truoc 1/2
    (6, "EMERGENCY", "APPROVED", "PAID"),            # Cap cuu: huong nhu dung tuyen 100%
]
VISIT_BY_ID = {x[0]: x for x in VISITS}
INS_BY_PATIENT = {i[1]: i for i in INSURANCE}


def effective_coverage(card, referral):
    if card is None:
        return Decimal("0")
    cov = Decimal(card[3])
    if referral == "WRONG":
        return (cov * Decimal("0.4")).quantize(Decimal("0.01"))
    return cov  # CORRECT va EMERGENCY huong nhu dung tuyen


def build_invoice_lines(visit_id):
    """Tra ve list (item_type, source_id, description, qty, unit_price, eligible)."""
    lines = []
    for vs_id, v_id, svc_id, qty in VISIT_SERVICES:
        if v_id != visit_id:
            continue
        s = SVC[svc_id]
        lines.append(("SERVICE", vs_id, s[2], Decimal(qty), Decimal(s[5]), bool(s[6])))
    visit_status = {o[0]: o for o in LAB_ORDERS}
    for o_id, v_id, svc_id, status in LAB_ORDERS:
        if v_id != visit_id or status in ("ORDERED", "CANCELLED"):
            continue
        s = SVC[svc_id]
        lines.append(("LAB", o_id, s[2], Decimal(1), Decimal(s[5]), bool(s[6])))
    pres_of_visit = {p[0]: p for p in PRESCRIPTIONS if p[1] == visit_id and p[3] in ("ISSUED", "DISPENSED")}
    for it_id, pres_id, med_id, dose, intakes, days, _ins in PRESC_ITEMS:
        if pres_id not in pres_of_visit:
            continue
        m = MED[med_id]
        total_qty = Decimal(dose) * intakes * days
        lines.append(("MED", it_id, m[2], total_qty, Decimal(m[7]), bool(m[8])))
    return lines


def main():
    L = []
    A = L.append
    A("/* ============================================================================")
    A("   DO AN HE QUAN TRI CO SO DU LIEU - MEDICORE HOSPITAL DATABASE")
    A("   File: 02_seed.sql - Du lieu mau (sinh boi tools/generate_seed.py)")
    A("   booked_count va tong tien hoa don/BHYT duoc tinh tu dong khi sinh file,")
    A("   dam bao nhat quan. Idempotent: xoa du lieu mau cu (theo khoang ID seed)")
    A("   truoc khi chen lai.")
    A("   ============================================================================ */")
    A("SET NOCOUNT ON;")
    A("USE MediCoreDB;")
    A("GO")
    A("")
    A("BEGIN TRANSACTION;")
    A("GO")
    A("/* Neu chay lai seed SAU khi da cai triggers (06): tam tat trigger chan")
    A("   sua don thuoc da phat hanh de lenh don du lieu mau khong bi chan;")
    A("   bat lai ngay sau khi chen xong (trong cung file nay). */")
    A("IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_prescription_items_block_issued')")
    A("    DISABLE TRIGGER dbo.trg_prescription_items_block_issued ON dbo.prescription_items;")
    A("GO")
    A("")
    # Cleanup seed range in FK-safe order (children first)
    for tbl in ["payments", "invoice_items", "invoices", "prescription_items",
                "prescriptions", "lab_results", "lab_orders", "visit_services",
                "diagnoses", "record_addenda", "medical_records", "visits",
                "appointments", "doctor_schedules", "insurance_cards",
                "patient_allergies", "patients", "medications", "medical_services",
                "rooms", "doctors", "app_users", "departments"]:
        A(f"DELETE FROM dbo.{tbl};")
    A("GO")
    A("")

    def insert(table, cols, rows, fmt):
        A(f"SET IDENTITY_INSERT dbo.{table} ON;")
        vals = ",\n    ".join("(" + ", ".join(fmt(r)) + ")" for r in rows)
        A(f"INSERT INTO dbo.{table} ({cols}) VALUES\n    {vals};")
        A(f"SET IDENTITY_INSERT dbo.{table} OFF;")
        A("")

    insert("departments", "department_id, department_code, department_name, description",
           DEPARTMENTS, lambda r: [str(r[0]), v(r[1]), q(r[2]), q(r[3])])
    insert("app_users", "user_id, username, password_hash, full_name, role_code",
           USERS, lambda r: [str(r[0]), v(r[1]), v(r[2]), q(r[3]), v(r[4])])
    insert("doctors", "doctor_id, user_id, department_id, full_name, title, license_no, phone, email",
           DOCTORS, lambda r: [str(r[0]), str(r[1]), str(r[2]), q(r[3]), q(r[4]), v(r[5]), v(r[6]),
                                v(r[5].lower().replace("-", "") + "@medicore.vn")])
    insert("rooms", "room_id, room_code, room_name, department_id, floor_no",
           ROOMS, lambda r: [str(r[0]), v(r[1]), q(r[2]), str(r[3]), str(r[4])])
    insert("patients", "patient_id, patient_code, national_id, full_name, date_of_birth, gender, phone, email, address, blood_type",
           PATIENTS, lambda r: [str(r[0]), v(r[1]), v(r[2]), q(r[3]), v(r[4]), v(r[5]), v(r[6]),
                                v(f"benhnhan{r[0]:02d}@example.vn"), q("TP. Hồ Chí Minh"), v(r[7])])
    insert("patient_allergies", "allergy_id, patient_id, allergen, reaction, severity",
           ALLERGIES, lambda r: [str(r[0]), str(r[1]), q(r[2]), q(r[3]), v(r[4])])
    insert("insurance_cards", "insurance_id, patient_id, card_no, coverage_percent, registered_facility, valid_from, valid_to",
           INSURANCE, lambda r: [str(r[0]), str(r[1]), v(r[2]), str(r[3]), q(r[4]), v(r[5]), v(r[6])])

    booked = {}
    for _id, sch, _pat, _reason, status in APPOINTMENTS:
        if status in ACTIVE_APPT:
            booked[sch] = booked.get(sch, 0) + 1
    sched_rows = [s + (booked.get(s[0], 0),) for s in SCHEDULES]
    insert("doctor_schedules", "schedule_id, doctor_id, room_id, work_date, shift_code, start_time, end_time, slot_capacity, booked_count, status",
           sched_rows, lambda r: [str(r[0]), str(r[1]), str(r[2]), v(r[3]), v(r[4]), v(r[5]), v(r[6]), str(r[7]), str(r[9]), v(r[8])])
    insert("appointments", "appointment_id, appointment_no, schedule_id, patient_id, reason, status",
           APPOINTMENTS, lambda r: [str(r[0]), v(f"LH2023-{r[0]:04d}"), str(r[1]), str(r[2]), q(r[3]), v(r[4])])
    insert("visits", "visit_id, visit_code, patient_id, appointment_id, doctor_id, room_id, visit_date, chief_complaint, status, started_at, ended_at",
           VISITS, lambda r: [str(r[0]), v(f"LK2023-{r[0]:04d}"), str(r[1]),
                              str(r[2]) if r[2] else "NULL", str(r[3]), str(r[4]), v(r[5]), q(r[6]), v(r[7]),
                              v(r[5] + " 08:00:00") if r[7] != "CANCELLED" else "NULL",
                              v(r[5] + " 08:45:00") if r[7] == "COMPLETED" else "NULL"])

    doc_of_visit = {x[0]: x[3] for x in VISITS}
    pat_of_visit = {x[0]: x[1] for x in VISITS}
    rec_rows = []
    for rec_id, visit_id, status in RECORDS:
        locked = status == "LOCKED"
        rec_rows.append((rec_id, visit_id, pat_of_visit[visit_id], doc_of_visit[visit_id],
                         status, doc_of_visit[visit_id] if locked else None,
                         "2023-05-20 10:00:00" if locked else None))
    insert("medical_records", "record_id, visit_id, patient_id, doctor_id, physical_exam, clinical_notes, conclusion, record_status, locked_by, locked_at",
           rec_rows, lambda r: [str(r[0]), str(r[1]), str(r[2]), str(r[3]),
                                q("Sinh hiệu ổn định, khám lâm sàng theo chuyên khoa."),
                                q("Diễn biến trong ngày, đáp ứng điều trị ban đầu tốt."),
                                q("Kết luận theo chẩn đoán chính của lần khám."),
                                v(r[4]), str(r[5]) if r[5] else "NULL",
                                v(r[6]) if r[6] else "NULL"])
    insert("record_addenda", "addendum_id, record_id, author_doctor_id, content, reason, approval_status, approved_by, approved_at",
           ADDENDA, lambda r: [str(r[0]), str(r[1]), str(r[2]), q(r[3]), q(r[4]), v(r[5]),
                               str(r[6]) if r[6] else "NULL",
                               v("2023-05-21 09:00:00") if r[6] else "NULL"])
    insert("diagnoses", "visit_id, icd10_code, icd10_name, diagnosis_type, diagnosed_by",
           DIAGNOSES, lambda r: [str(r[0]), v(r[1]), q(r[2]), v(r[3]), str(doc_of_visit[r[0]])])
    insert("medical_services", "service_id, service_code, service_name, department_id, service_type, unit_price, is_insurance_covered",
           SERVICES, lambda r: [str(r[0]), v(r[1]), q(r[2]), str(r[3]), v(r[4]), str(r[5]), str(r[6])])
    insert("visit_services", "visit_service_id, visit_id, service_id, quantity, unit_price_snapshot, status",
           VISIT_SERVICES, lambda r: [str(r[0]), str(r[1]), str(r[2]), str(r[3]), str(SVC[r[2]][5]), v("DONE")])
    insert("lab_orders", "lab_order_id, visit_id, service_id, ordered_by, priority, status",
           LAB_ORDERS, lambda r: [str(r[0]), str(r[1]), str(r[2]), str(doc_of_visit[r[1]]), v("NORMAL"), v(r[3])])

    res_rows = []
    rid = 0
    for o_id, code, name, val, txt, unit, lo, hi in LAB_RESULTS:
        rid += 1
        abnormal = 0
        if val is not None:
            if lo is not None and val < lo:
                abnormal = 1
            if hi is not None and val > hi:
                abnormal = 1
        res_rows.append((rid, o_id, code, name, val, txt, unit, lo, hi, abnormal,
                         "VERIFIED" if any(o[0] == o_id and o[3] == "VERIFIED" for o in LAB_ORDERS) else None))
    insert("lab_results", "result_id, lab_order_id, parameter_code, parameter_name, result_value, result_text, unit, ref_low, ref_high, is_abnormal, resulted_by, verified_by, verified_at",
           res_rows, lambda r: [str(r[0]), str(r[1]), v(r[2]), q(r[3]),
                                str(r[4]) if r[4] is not None else "NULL",
                                q(r[5]), v(r[6]),
                                str(r[7]) if r[7] is not None else "NULL",
                                str(r[8]) if r[8] is not None else "NULL",
                                str(r[9]), q("KTV. Phan Gia Huy"),
                                str(doc_of_visit[{o[0]: o[1] for o in LAB_ORDERS}[r[1]]]) if r[10] else "NULL",
                                v("2023-05-20 11:00:00") if r[10] else "NULL"])
    insert("medications", "medication_id, medication_code, medication_name, active_ingredient, dosage_form, strength, unit, unit_price, is_insurance_covered",
           MEDICATIONS, lambda r: [str(r[0]), v(r[1]), q(r[2]), q(r[3]), q(r[4]), v(r[5]), q(r[6]), str(r[7]), str(r[8])])
    insert("prescriptions", "prescription_id, prescription_code, visit_id, doctor_id, status, issued_at",
           PRESCRIPTIONS, lambda r: [str(r[0]), v(f"DT2023-{r[0]:04d}"), str(r[1]), str(r[2]), v(r[3]),
                                     v("2023-05-20 09:30:00") if r[3] in ("ISSUED", "DISPENSED") else "NULL"])
    item_rows = []
    for it_id, pres_id, med_id, dose, intakes, days, ins in PRESC_ITEMS:
        total = Decimal(dose) * intakes * days
        item_rows.append((it_id, pres_id, med_id, dose, intakes, days, total, ins))
    insert("prescription_items", "item_id, prescription_id, medication_id, dose_per_intake, intakes_per_day, duration_days, total_quantity, instructions",
           item_rows, lambda r: [str(r[0]), str(r[1]), str(r[2]), f"{r[3]:.2f}", str(r[4]), str(r[5]), f"{r[6]:.2f}", q(r[7])])

    # ---------------------------------------------------------------- invoices
    inv_rows, ii_rows, pay_rows = [], [], []
    ii_id = 0
    pay_id = 0
    for idx, (visit_id, referral, claim, status) in enumerate(INVOICE_DEFS, start=1):
        patient_id = pat_of_visit[visit_id]
        card = INS_BY_PATIENT.get(patient_id)
        # The phai con han vao ngay kham
        visit_date = VISIT_BY_ID[visit_id][5]
        if card and not (card[5] <= visit_date <= card[6]):
            card = None
        eff = effective_coverage(card, referral)
        lines = build_invoice_lines(visit_id)
        svc_total = sum(q_ * p for t, _s, _d, q_, p, _e in lines if t == "SERVICE")
        lab_total = sum(q_ * p for t, _s, _d, q_, p, _e in lines if t == "LAB")
        med_total = sum(q_ * p for t, _s, _d, q_, p, _e in lines if t == "MED")
        gross = svc_total + lab_total + med_total
        eligible_total = sum(q_ * p for _t, _s, _d, q_, p, e in lines if e)
        ins_pay = (eligible_total * eff / Decimal(100)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        copay = gross - ins_pay
        inv_rows.append((idx, f"HD2023-{idx:04d}", visit_id, patient_id,
                         card[0] if card else None, referral,
                         card[3] if card else None, eff, svc_total, lab_total,
                         med_total, gross, ins_pay, copay, claim, status, visit_date))
        for t, src, desc, q_, p, e in lines:
            ii_id += 1
            ii_rows.append((ii_id, idx, t, src, desc, q_, p, q_ * p, 1 if e else 0))
        # payments
        if status == "PAID":
            if copay > 0:
                pay_id += 1
                pay_rows.append((pay_id, idx, "PATIENT", copay, "TRANSFER", f"CK{idx:06d}", visit_date))
            if ins_pay > 0 and claim == "APPROVED":
                pay_id += 1
                pay_rows.append((pay_id, idx, "INSURANCE", ins_pay, "INSURANCE_CLAIM", f"BHYT{idx:06d}", visit_date))
        elif status == "PARTIALLY_PAID":
            part = (copay / 2).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            assert part > 0, "PARTIALLY_PAID can copay > 0 de co payment hop le"
            pay_id += 1
            pay_rows.append((pay_id, idx, "PATIENT", part, "CASH", None, visit_date))
    for row in pay_rows:
        assert row[3] > 0, f"Payment khong hop le (amount <= 0): {row}"
    insert("invoices", "invoice_id, invoice_no, visit_id, patient_id, insurance_id, referral_type, coverage_percent_snapshot, effective_coverage_percent, services_total, labs_total, meds_total, gross_total, insurance_payable, discount_amount, patient_copay, insurance_claim_status, status, issued_at, due_date",
           inv_rows, lambda r: [str(r[0]), v(r[1]), str(r[2]), str(r[3]),
                                str(r[4]) if r[4] else "NULL", v(r[5]),
                                str(r[6]) if r[6] is not None else "NULL", f"{r[7]:.2f}",
                                money(r[8]), money(r[9]), money(r[10]), money(r[11]),
                                money(r[12]), "0.00", money(r[13]), v(r[14]), v(r[15]),
                                v(r[16] + " 12:00:00"), v(r[16])])
    insert("invoice_items", "invoice_item_id, invoice_id, item_type, source_id, description, quantity, unit_price, line_total, is_insurance_eligible",
           ii_rows, lambda r: [str(r[0]), str(r[1]), v(r[2]), str(r[3]), q(r[4]),
                               f"{r[5]:.2f}", money(r[6]), money(r[7]), str(r[8])])
    insert("payments", "payment_id, invoice_id, payer_type, amount, payment_method, transaction_ref, paid_at, received_by",
           pay_rows, lambda r: [str(r[0]), str(r[1]), v(r[2]), money(r[3]), v(r[4]),
                                v(r[5]), v(r[6] + " 12:30:00"), q("Nguyễn Khánh Linh")])

    A("IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_prescription_items_block_issued')")
    A("    ENABLE TRIGGER dbo.trg_prescription_items_block_issued ON dbo.prescription_items;")
    A("GO")
    A("")
    A("COMMIT TRANSACTION;")
    A("GO")
    A("")
    A("PRINT N'02_seed.sql: Da nap du lieu mau MediCore.';")
    A("SELECT (SELECT COUNT(*) FROM dbo.patients) AS patients,")
    A("       (SELECT COUNT(*) FROM dbo.doctors) AS doctors,")
    A("       (SELECT COUNT(*) FROM dbo.visits) AS visits,")
    A("       (SELECT COUNT(*) FROM dbo.invoices) AS invoices;")
    A("GO")
    OUT.write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")
    print(f"Counts: dept={len(DEPARTMENTS)} users={len(USERS)} doctors={len(DOCTORS)} rooms={len(ROOMS)} "
          f"patients={len(PATIENTS)} insurance={len(INSURANCE)} schedules={len(SCHEDULES)} "
          f"appointments={len(APPOINTMENTS)} visits={len(VISITS)} records={len(RECORDS)} "
          f"diagnoses={len(DIAGNOSES)} services={len(SERVICES)} lab_orders={len(LAB_ORDERS)} "
          f"lab_results={len(LAB_RESULTS)} meds={len(MEDICATIONS)} prescriptions={len(PRESCRIPTIONS)} "
          f"presc_items={len(PRESC_ITEMS)} invoices={len(inv_rows)} invoice_items={len(ii_rows)} payments={len(pay_rows)}")


if __name__ == "__main__":
    main()
