# DATA DICTIONARY — MediCoreDB

24 bảng. Quy ước: tiền dùng `DECIMAL(18,2)` (VND); thời gian `DATETIME2(0)`; ngày khám `DATE`; mã định danh nghiệp vụ (patient_code, visit_code…) là `VARCHAR` có UNIQUE.

## 1. departments — Chuyên khoa
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| department_id | INT IDENTITY | PK | Khóa chính |
| department_code | VARCHAR(10) | UNIQUE, NOT NULL | Mã khoa: GEN, CARD, RESP, GI, PEDI, DERM, ENT |
| department_name | NVARCHAR(120) | NOT NULL | Tên khoa |
| description | NVARCHAR(500) | NULL | Mô tả |
| is_active | BIT | DEFAULT 1 | Đang hoạt động |

## 2. app_users — Tài khoản hệ thống
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| user_id | INT IDENTITY | PK | |
| username | VARCHAR(50) | UNIQUE | Tên đăng nhập |
| password_hash | VARCHAR(255) | NOT NULL | Chỉ lưu hash (seed là placeholder, không phải mật khẩu thật) |
| full_name | NVARCHAR(120) | NOT NULL | Họ tên |
| role_code | VARCHAR(20) | CHECK | ADMIN / DOCTOR / NURSE / LAB_TECH / CASHIER / RECEPTIONIST |
| is_active, created_at | BIT, DATETIME2 | DEFAULT | |

## 3. doctors — Bác sĩ
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| doctor_id | INT IDENTITY | PK | |
| user_id | INT | FK → app_users, NULL | Tài khoản đăng nhập tương ứng |
| department_id | INT | FK → departments | Khoa công tác |
| full_name, title | NVARCHAR | NOT NULL / NULL | Họ tên, học hàm/học vị (BS.CKI, ThS.BS…) |
| license_no | VARCHAR(20) | UNIQUE | Số chứng chỉ hành nghề |
| phone, email | VARCHAR | NULL | Liên hệ |
| is_active | BIT | DEFAULT 1 | |

## 4. rooms — Phòng khám
`room_id` PK · `room_code` UNIQUE (P101…) · `room_name` · `department_id` FK · `floor_no` INT · `is_active` BIT.

## 5. patients — Hồ sơ định danh bệnh nhân
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| patient_id | INT IDENTITY | PK | |
| patient_code | VARCHAR(15) | UNIQUE | Mã BN: BN2023-0001 |
| national_id | VARCHAR(12) | UNIQUE, NOT NULL | CCCD — định danh duy nhất toàn hệ thống |
| full_name | NVARCHAR(120) | NOT NULL | |
| date_of_birth | DATE | CHECK ≤ hôm nay | |
| gender | VARCHAR(6) | CHECK | MALE / FEMALE / OTHER |
| phone, email, address | | NULL | Liên hệ |
| blood_type | VARCHAR(5) | NULL | Nhóm máu |
| created_at | DATETIME2 | DEFAULT | Ngày tạo hồ sơ định danh |

## 6. patient_allergies — Dị ứng
`allergy_id` PK · `patient_id` FK · `allergen` NVARCHAR (tên thuốc/tác nhân) · `reaction` · `severity` CHECK (MILD/MODERATE/SEVERE) · `recorded_at`.

## 7. insurance_cards — Thẻ BHYT
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| insurance_id | INT IDENTITY | PK | |
| patient_id | INT | FK → patients | Chủ thẻ |
| card_no | VARCHAR(20) | UNIQUE | Số thẻ BHYT |
| insurer_name | NVARCHAR(150) | DEFAULT BHXH VN | Cơ quan bảo hiểm |
| coverage_percent | DECIMAL(5,2) | CHECK (0,100] | Mức hưởng ghi trên thẻ: 80 / 95 / 100 |
| registered_facility | NVARCHAR(200) | NULL | Nơi đăng ký KCB ban đầu (căn cứ đúng/trái tuyến) |
| valid_from, valid_to | DATE | CHECK valid_to ≥ valid_from | Hiệu lực thẻ |
| is_primary | BIT | DEFAULT 1 | Thẻ chính đang dùng |

## 8. doctor_schedules — Ca làm việc của bác sĩ
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| schedule_id | INT IDENTITY | PK | |
| doctor_id, room_id | INT | FK | Bác sĩ / phòng của ca |
| work_date | DATE | | Ngày làm việc |
| shift_code | VARCHAR(10) | CHECK | MORNING / AFTERNOON / EVENING |
| start_time, end_time | TIME | CHECK end > start | Khung giờ ca |
| slot_capacity | INT | CHECK > 0 | Sức chứa (số bệnh nhân tối đa) |
| booked_count | INT | CHECK 0 ≤ … ≤ capacity | Số slot đã đặt — **do trigger đồng bộ**, không sửa tay |
| status | VARCHAR(12) | CHECK | OPEN / CLOSED / CANCELLED |
| | | UNIQUE (doctor, date, shift); UNIQUE (room, date, shift) | Chống trùng lịch ở mức dữ liệu |

## 9. appointments — Lịch hẹn
`appointment_id` PK · `appointment_no` UNIQUE (LH2023-0001) · `schedule_id` FK · `patient_id` FK · UNIQUE (schedule_id, patient_id) · `reason` · `status` CHECK (BOOKED/CHECKED_IN/CANCELLED/NO_SHOW/COMPLETED) · `booked_at`, `checked_in_at`.

## 10. visits — Lần khám (encounter)
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| visit_id | INT IDENTITY | PK | |
| visit_code | VARCHAR(15) | UNIQUE | LK2023-0001 |
| patient_id | INT | FK → patients | |
| appointment_id | INT | FK, NULL; unique có lọc | Lịch hẹn nguồn (NULL = khám trực tiếp không hẹn) |
| doctor_id, room_id | INT | FK | Bác sĩ phụ trách / phòng |
| visit_date | DATE | NOT NULL | |
| chief_complaint | NVARCHAR(500) | NULL | Lý do đến khám |
| status | VARCHAR(12) | CHECK | OPEN / IN_PROGRESS / COMPLETED / CANCELLED |
| started_at, ended_at | DATETIME2 | CHECK ended ≥ started | |

## 11. medical_records — Hồ sơ bệnh án
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| record_id | INT IDENTITY | PK | |
| visit_id | INT | FK, UNIQUE | 1 hồ sơ ↔ 1 lần khám |
| patient_id, doctor_id | INT | FK | |
| physical_exam | NVARCHAR(2000) | NULL | Khám lâm sàng |
| clinical_notes | NVARCHAR(4000) | NULL | Diễn biến / ghi chú |
| conclusion | NVARCHAR(1000) | NULL | Kết luận (bắt buộc có trước khi khóa — kiểm ở procedure) |
| record_status | VARCHAR(10) | CHECK | DRAFT / LOCKED |
| locked_by, locked_at | INT FK, DATETIME2 | CHECK: LOCKED ⇔ locked_at NOT NULL | Người khóa / thời điểm khóa |
| created_at, updated_at | DATETIME2 | DEFAULT | |

## 12. record_addenda — Phụ lục hồ sơ đã khóa
`addendum_id` PK · `record_id` FK · `author_doctor_id` FK · `content` NOT NULL · `reason` NOT NULL · `approval_status` CHECK (PENDING/APPROVED/REJECTED) · `approved_by` FK · `approved_at` (CHECK: đã xử lý ⇔ approved_at NOT NULL) · `created_at`.

## 13. audit_logs — Nhật ký kiểm toán
`audit_id` BIGINT IDENTITY PK · `table_name` · `record_pk` (khóa chính dạng chuỗi) · `action` CHECK (INSERT/UPDATE/DELETE) · `old_summary`, `new_summary` NVARCHAR(2000) — tóm tắt giá trị trước/sau do trigger tạo · `changed_by` DEFAULT ORIGINAL_LOGIN() · `changed_at` DEFAULT SYSDATETIME(). Cố ý **không** có FK để log tồn tại độc lập với dữ liệu nghiệp vụ.

## 14. diagnoses — Chẩn đoán
`diagnosis_id` PK · `visit_id` FK · `icd10_code` VARCHAR(10) · `icd10_name` · `diagnosis_type` CHECK (PRIMARY/SECONDARY) · UNIQUE (visit_id, icd10_code, diagnosis_type) · `diagnosed_by` FK → doctors · `diagnosed_at`.

## 15. medical_services — Danh mục dịch vụ
`service_id` PK · `service_code` UNIQUE · `service_name` · `department_id` FK NULL · `service_type` CHECK (CONSULT/LAB/IMAGING/PROCEDURE) · `unit_price` DECIMAL ≥ 0 · `is_insurance_covered` BIT · `is_active` BIT.

## 16. visit_services — Dịch vụ đã thực hiện trong lần khám
`visit_service_id` PK · `visit_id` FK · `service_id` FK · `quantity` INT > 0 · `unit_price_snapshot` DECIMAL — **giá chụp tại thời điểm thực hiện**, đổi giá danh mục sau này không làm sai hóa đơn cũ · `performed_at` · `status` CHECK (ORDERED/DONE/CANCELLED).

## 17. lab_orders — Chỉ định xét nghiệm
`lab_order_id` PK · `visit_id` FK (bắt buộc — chỉ định luôn thuộc 1 lần khám) · `service_id` FK (dịch vụ loại LAB) · `ordered_by` FK → doctors · `ordered_at` · `priority` CHECK (NORMAL/URGENT) · `status` CHECK (ORDERED/COLLECTED/RESULTED/VERIFIED/CANCELLED).

## 18. lab_results — Kết quả từng thông số
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| result_id | INT IDENTITY | PK | |
| lab_order_id | INT | FK → lab_orders | |
| parameter_code | VARCHAR(20) | UNIQUE cùng (lab_order_id, parameter_code) | GLU, HBA1C, WBC… |
| parameter_name | NVARCHAR(120) | NOT NULL | |
| result_value | DECIMAL(12,3) | NULL | Giá trị định lượng |
| result_text | NVARCHAR(250) | NULL | Kết quả định tính |
| unit | VARCHAR(20) | NULL | mmol/L, G/L… |
| ref_low, ref_high | DECIMAL(12,3) | CHECK high ≥ low | Khoảng tham chiếu của chính thông số |
| is_abnormal | BIT | DEFAULT 0 | **Trigger tự đánh giá** từ result_value và khoảng tham chiếu |
| resulted_by, resulted_at | | | Kỹ thuật viên nhập kết quả |
| verified_by, verified_at | INT FK, DATETIME2 | NULL | Người duyệt kết quả |

## 19. medications — Danh mục thuốc
`medication_id` PK · `medication_code` UNIQUE · `medication_name` · `active_ingredient` (hoạt chất — dùng kiểm tra dị ứng) · `dosage_form` · `strength` · `unit` (viên/chai…) · `unit_price` ≥ 0 · `is_insurance_covered` · `is_active`.

## 20. prescriptions — Đơn thuốc
`prescription_id` PK · `prescription_code` UNIQUE (DT2023-0001) · `visit_id` FK · `doctor_id` FK · `status` CHECK (DRAFT/ISSUED/DISPENSED/CANCELLED) · `notes` · `created_at` · `issued_at` (CHECK: không còn DRAFT thì phải có issued_at).

## 21. prescription_items — Chi tiết đơn thuốc
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| item_id | INT IDENTITY | PK | |
| prescription_id, medication_id | INT | FK; UNIQUE (prescription, medication) | |
| dose_per_intake | DECIMAL(6,2) | CHECK > 0 | Liều mỗi lần dùng |
| intakes_per_day | INT | CHECK > 0 | Số lần dùng / ngày |
| duration_days | INT | CHECK > 0 | Số ngày dùng |
| total_quantity | DECIMAL(10,2) | **CHECK = dose × intakes × days** | Tổng số lượng phát |
| instructions | NVARCHAR(250) | NULL | Cách dùng (uống sau ăn…) |

## 22. invoices — Hóa đơn viện phí
| Cột | Kiểu | Ràng buộc | Mô tả |
|---|---|---|---|
| invoice_id | INT IDENTITY | PK | |
| invoice_no | VARCHAR(15) | UNIQUE | HD2023-0001 |
| visit_id | INT | FK, UNIQUE | 1 lần khám tối đa 1 hóa đơn hiệu lực |
| patient_id | INT | FK | Người chịu phí |
| insurance_id | INT | FK, NULL | Thẻ BHYT áp dụng (NULL = không có thẻ/hết hạn) |
| referral_type | VARCHAR(15) | CHECK | CORRECT (đúng tuyến) / WRONG (trái tuyến) / EMERGENCY (cấp cứu) |
| coverage_percent_snapshot | DECIMAL(5,2) | NULL | Mức hưởng trên thẻ tại thời điểm lập |
| effective_coverage_percent | DECIMAL(5,2) | NOT NULL | Mức hưởng hiệu lực sau quy tắc tuyến (trái tuyến = 40% mức thẻ) |
| services_total, labs_total, meds_total | DECIMAL(18,2) | ≥ 0 | Tổng theo nguồn |
| gross_total | DECIMAL(18,2) | CHECK = services + labs + meds | Tổng viện phí |
| insurance_payable | DECIMAL(18,2) | CHECK 0 ≤ … ≤ gross | BHYT chi trả |
| discount_amount | DECIMAL(18,2) | ≥ 0 | Giảm giá (mặc định 0) |
| patient_copay | DECIMAL(18,2) | CHECK = gross − insurance − discount | Bệnh nhân đồng chi trả |
| insurance_claim_status | VARCHAR(12) | CHECK | NOT_SENT / SENT / APPROVED / REJECTED |
| status | VARCHAR(15) | CHECK | DRAFT / ISSUED / PARTIALLY_PAID / PAID / CANCELLED |
| issued_at, due_date, created_at | | | |

## 23. invoice_items — Dòng hóa đơn
`invoice_item_id` PK · `invoice_id` FK · `item_type` CHECK (SERVICE/LAB/MED) · `source_id` — khóa của bản ghi nguồn tương ứng (visit_services / lab_orders / prescription_items) · `description` (snapshot tên) · `quantity`, `unit_price`, `line_total` (CHECK line_total = quantity × unit_price) · `is_insurance_eligible` BIT · UNIQUE (invoice_id, item_type, source_id) chống tính trùng 1 nguồn 2 lần.

## 24. payments — Thanh toán
`payment_id` PK · `invoice_id` FK · `payer_type` CHECK (PATIENT/INSURANCE) · `amount` DECIMAL CHECK > 0 · `payment_method` CHECK (CASH/CARD/TRANSFER/INSURANCE_CLAIM) · `transaction_ref` · `paid_at` · `received_by` · `status` CHECK (COMPLETED/REFUNDED/VOID).
