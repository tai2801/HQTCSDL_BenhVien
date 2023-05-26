# TEST REPORT — CSDL QUẢN LÝ BỆNH VIỆN (MEDICORE)

Ngày kiểm thử: 26/05/2023  
Môi trường: SQL Server 2019 Developer Edition (SSMS 19) & Python 3.10 trên Windows 10.

## 1. Kiểm thử ràng buộc T-SQL (`database/08_tests.sql`)

Chạy tuần tự các script `01_schema.sql → 02_seed.sql → 03_indexes.sql → 04_views.sql → 05_procedures.sql → 06_triggers.sql → 07_queries_reports.sql → 08_tests.sql`.

Kết quả `08_tests.sql`: **14/14 PASS**
- `[PASS] TEST01` — Seed đạt ngưỡng tối thiểu (7 chuyên khoa, 11 bác sĩ, 16 bệnh nhân, 13 lần khám).
- `[PASS] TEST02` — Ràng buộc UNIQUE chặn CCCD trùng.
- `[PASS] TEST03` — `booked_count <= slot_capacity` trên toàn bộ ca khám.
- `[PASS] TEST04` — `sp_book_appointment` chặn đặt lịch vào ca đã đóng (`CLOSED`).
- `[PASS] TEST05` — Trigger `trg_medical_records_block_locked` chặn sửa trực tiếp hồ sơ bệnh án đã khóa (`LOCKED`).
- `[PASS] TEST06` — `sp_add_addendum` từ chối tạo phụ lục cho hồ sơ chưa khóa (`DRAFT`).
- `[PASS] TEST07` — Tạo phụ lục (`addendum`) cho hồ sơ đã khóa thành công ở trạng thái `PENDING`.
- `[PASS] TEST08` — Cờ `is_abnormal` nhất quán với khoảng tham chiếu `[ref_low, ref_high]`.
- `[PASS] TEST09` — Tổng lượng thuốc `total_quantity = dose_per_intake * intakes_per_day * duration_days` trên toàn bộ seed.
- `[PASS] TEST10` — Trigger `trg_prescription_items_block_issued` chặn sửa chi tiết đơn thuốc đã phát hành (`ISSUED`).
- `[PASS] TEST11` — Hóa đơn nhất quán: `patient_copay = gross_total - insurance_payable - discount_amount` và tổng dòng `invoice_items` khớp `gross_total`.
- `[PASS] TEST12` — Khám trái tuyến (`WRONG`): mức hưởng hiệu lực = 40% mức hưởng trên thẻ.
- `[PASS] TEST13` — `sp_pay_invoice` chặn thanh toán vượt phần còn phải trả.
- `[PASS] TEST14` — Quy trình duyệt phụ lục (`APPROVED`) và ghi nhận `audit_logs` hoạt động đúng.

## 2. Kiểm thử tự động quy tắc nghiệp vụ bằng Python

```bash
python -m unittest discover -s tests -v   →  Ran 23 tests — OK (23/23 pass)
```

23 test trong `tests/test_medicore.py` kiểm tra toàn bộ quy tắc nghiệp vụ:
- **Viện phí/BHYT (6 test):** đúng tuyến 80% → BHYT trả 204.000/255.000₫; trái tuyến → mức hiệu lực 32% (= 40% × 80%); cấp cứu hưởng như đúng tuyến; không thẻ → trả 100%; dòng không thuộc danh mục BHYT bị loại khỏi phần BHYT trả; đẳng thức đồng chi trả luôn đúng.
- **Khóa hồ sơ + addendum (4 test):** sửa DRAFT được, khóa xong sửa bị chặn; addendum chỉ tạo được cho hồ sơ đã khóa; addendum bắt buộc có lý do; tác giả không tự duyệt phụ lục của mình.
- **Slot khám (4 test):** ca đầy bị từ chối; hủy lịch giải phóng slot; ca CLOSED bị từ chối; cùng bệnh nhân đặt trùng ca bị từ chối.
- **Cờ abnormal (5 test):** glucose cao, HGB thấp bị gắn cờ; giá trị bình thường không gắn; khoảng tham chiếu một phía (chỉ có cận trên) vẫn đúng; kết quả định tính không gắn cờ.
- **Đơn thuốc (4 test):** tổng lượng = liều × lần × ngày (kể cả liều 0,5); đơn ISSUED không sửa được; dị ứng Penicillin chặn kê Amoxicillin; thuốc không dị ứng kê bình thường.

## 3. Rà soát nhất quán SQL & đối chiếu dữ liệu mẫu

```bash
python tools/check_sql_consistency.py  →  OK (24 bảng, 7 views, 9 procedures, 7 triggers, 12 indexes)
python tools/audit_seed.py             →  0 vi phạm công thức hóa đơn, 0 lệch booked_count, 0 lệch abnormal
```

- 7 hóa đơn: `gross = services + labs + meds` và `copay = gross − BHYT − giảm giá` — **0 vi phạm**.
- Tổng 29 dòng `invoice_items` của từng hóa đơn bằng đúng `gross_total` — **0 lệch**.
- Mọi hóa đơn PAID đều được thanh toán đủ cả phần bệnh nhân lẫn phần BHYT — **0 thiếu**.
- `booked_count` của 12 ca khám khớp số lịch hẹn còn hiệu lực — **0 lệch**.
- 11 dòng đơn thuốc thỏa `total = dose × intakes × days` — **0 vi phạm**.
- Cờ abnormal của 14 kết quả xét nghiệm khớp với khoảng tham chiếu — **0 lệch**, có 7 kết quả bất thường.

## 4. Các vấn đề đã khắc phục trong quá trình phát triển

1. **Ràng buộc CHECK `amount > 0` trên bảng `payments`:** ở bản seed đầu, hóa đơn `PARTIALLY_PAID` gán cho bệnh nhân có thẻ BHYT 100% (đồng chi trả = 0) làm sinh dòng thanh toán 0₫. Đã chuyển hóa đơn trả một phần sang lần khám không thẻ BHYT (đồng chi trả 1.176.000₫, trả trước 588.000₫).
2. **Đồng bộ `booked_count`:** để tránh cộng hai lần giữa `sp_book_appointment` và trigger `trg_appointments_slot_guard`, thống nhất chỉ để trigger tính lại `booked_count` từ bảng `appointments`.
3. **Chạy lại seed sau khi cài trigger:** bổ sung `DISABLE TRIGGER trg_prescription_items_block_issued` ở đầu file `02_seed.sql` và `ENABLE TRIGGER` ở cuối file để có thể chạy lại script dữ liệu mẫu bất kỳ lúc nào.
