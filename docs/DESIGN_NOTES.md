# GHI CHÚ THIẾT KẾ — MEDICORE

Tài liệu giải thích *vì sao* thiết kế như vậy — phần cần nắm khi bảo vệ đồ án.

## 1. Quyết định thiết kế chính

### 1.1. Tách `patients` (định danh) khỏi `visits` (lần khám)
Hồ sơ định danh chứa thông tin ít thay đổi (CCCD, ngày sinh, nhóm máu, dị ứng, thẻ BHYT). Mỗi lần đến khám tạo một `visits` mới trỏ về cùng một bệnh nhân. Nhờ vậy lịch sử điều trị là một truy vấn đơn giản theo `patient_id`, và không bao giờ có "hai bệnh nhân trùng CCCD" làm vỡ lịch sử.

### 1.2. Hồ sơ bệnh án khóa được + phụ lục (addendum) thay cho "cấm sửa tuyệt đối"
Thực tế bệnh viện vẫn cần bổ sung kết quả trả muộn hoặc đính chính sau khi hồ sơ đã ký. Nếu chỉ "cấm sửa", người dùng sẽ tìm cách lách. Thiết kế của MediCore:
- Bản gốc sau khi khóa là **bất biến ở tầng database** (trigger chặn UPDATE, kể cả khi sửa bằng SQL trực tiếp chứ không qua ứng dụng).
- Bổ sung đi qua `record_addenda`: nội dung mới là một bản ghi riêng, có lý do bắt buộc, tác giả, và **người duyệt khác tác giả** (nguyên tắc bốn mắt).
- Cả hai thao tác đều ghi `audit_logs`.

Đây là mô hình gần với cách hồ sơ bệnh án điện tử (EMR) vận hành ngoài thực tế: *append-only sau khi ký*.

### 1.3. `booked_count` do trigger duy trì — một nguồn sự thật duy nhất
`booked_count` là dữ liệu dẫn xuất (đếm lịch hẹn còn hiệu lực). Nếu để procedure tự cộng/trừ, sớm muộn sẽ lệch (quên trừ khi hủy, cộng hai lần khi retry…). MediCore để trigger `trg_appointments_slot_guard` **tính lại** từ bảng appointments sau mọi INSERT/UPDATE/DELETE và chặn luôn trường hợp vượt sức chứa. Procedure đặt lịch chỉ kiểm tra trước để báo lỗi thân thiện; trigger là chốt chặn cuối cùng. Bài học rút ra trong lúc làm: ban đầu procedure cũng tự tăng `booked_count` — rà soát thấy sẽ đếm trùng với trigger nên đã bỏ khỏi procedure.

### 1.4. Giá snapshot, không lấy giá hiện hành khi tính tiền cũ
`visit_services.unit_price_snapshot` chụp giá tại thời điểm thực hiện dịch vụ; dòng hóa đơn lưu `description` và `unit_price` riêng. Đổi giá danh mục không làm thay đổi hóa đơn đã lập — điều kiện bắt buộc để đối soát tài chính.

### 1.5. Hóa đơn có dòng truy xuất nguồn (`invoice_items.source_id`)
Mỗi dòng hóa đơn biết nó sinh ra từ dịch vụ nào / chỉ định nào / dòng đơn thuốc nào, kèm UNIQUE (invoice, type, source) chống tính trùng. Khi bệnh nhân khiếu nại, thu ngân truy ngược được từng dòng thay vì chỉ thấy một con số tổng.

### 1.6. Doanh thu = tiền đã thu
View doanh thu tổng hợp từ `payments` (trạng thái COMPLETED), tách nguồn bệnh nhân/BHYT. Tổng hóa đơn phát hành (`gross_total`) là *doanh số*, không phải *doanh thu đã thu* — trộn hai khái niệm này là lỗi báo cáo rất hay gặp.

## 2. Quy tắc BHYT (mô phỏng cho đồ án)

> Đây là quy tắc **đơn giản hóa phục vụ học tập**, không phải văn bản pháp luật. Khi trình bày cần nói rõ điều này.

- Mỗi thẻ có `coverage_percent` (mức hưởng: 80 / 95 / 100%).
- Mức hưởng **hiệu lực**:
  - Đúng tuyến (`CORRECT`): bằng mức trên thẻ.
  - Cấp cứu (`EMERGENCY`): bằng mức trên thẻ (cấp cứu được coi như đúng tuyến).
  - Trái tuyến ngoại trú (`WRONG`): bằng **40%** mức trên thẻ.
- BHYT chỉ trả cho dòng đủ điều kiện (`is_insurance_eligible` — suy ra từ cờ của dịch vụ/thuốc tại thời điểm lập hóa đơn). Dịch vụ ngoài danh mục (vd tư vấn dinh dưỡng chuyên sâu, vitamin bổ sung) bệnh nhân tự trả 100%.
- `insurance_payable = tròn 2 số lẻ (tổng dòng đủ điều kiện × mức hiệu lực / 100)`.
- `patient_copay = gross_total − insurance_payable − discount`.
- Thẻ phải còn hạn **tại ngày khám** mới được áp dụng; mức hưởng được snapshot vào hóa đơn để sau này thẻ đổi mức cũng không làm sai hóa đơn cũ.

Ví dụ kiểm chứng được trong seed (hóa đơn HD2023-0003, trái tuyến): tổng 705.000₫, thẻ 95% → hiệu lực 38% → BHYT trả 267.900₫, bệnh nhân trả 437.100₫.

## 3. Mô hình bảo mật dữ liệu hồ sơ

| Lớp | Cơ chế trong dự án |
|---|---|
| Tài khoản | `app_users.password_hash` — chỉ lưu hash; seed dùng placeholder, mật khẩu thật do người triển khai đặt qua biến môi trường/SSMS, không commit. |
| Vai trò | `role_code` phân vai (ADMIN/DOCTOR/NURSE/LAB_TECH/CASHIER/RECEPTIONIST) — tầng ứng dụng dùng để ẩn/hiện chức năng. |
| Toàn vẹn hồ sơ | Khóa hồ sơ + addendum + trigger chặn sửa ở tầng DB: kể cả tài khoản ứng dụng bị lộ, dữ liệu đã khóa vẫn không sửa thẳng được nếu không có quyền tắt trigger (quyền của DBA). |
| Kiểm toán | Trigger ghi audit log cho UPDATE/DELETE trên `medical_records` và INSERT/UPDATE trên `record_addenda`: ai (ORIGINAL_LOGIN), khi nào, tóm tắt trước/sau. |
| Dữ liệu nhạy cảm | CCCD và số thẻ BHYT là định danh — khi làm báo cáo/demo chỉ dùng dữ liệu giả (seed dùng số CCCD/thẻ bịa theo đúng định dạng). Không đưa dữ liệu bệnh nhân thật vào repo. |
| Nguyên tắc bốn mắt | Người duyệt phụ lục ≠ tác giả; người duyệt kết quả xét nghiệm được lưu riêng (`verified_by`) khác người nhập (`resulted_by`). |

Phạm vi hiện tại: dự án tập trung ở tầng thiết kế schema, thủ tục và trigger nên chưa triển khai Row-Level Security hay mã hóa cột (TDE/Always Encrypted) — đây là hướng mở rộng ghi trong README.

## 4. Idempotent — chạy lại được

- Tạo DB: `IF DB_ID(...) IS NULL`.
- Tạo bảng: `IF OBJECT_ID(...) IS NULL`.
- Views/Procedures/Triggers: `CREATE OR ALTER`.
- Indexes: kiểm tra `sys.indexes` trước khi tạo.
- Seed: xóa dữ liệu mẫu theo thứ tự FK an toàn rồi chèn lại với `IDENTITY_INSERT`; nếu đã cài trigger thì seed tự tạm tắt trigger chặn-sửa-đơn-thuốc trong lúc dọn dữ liệu và bật lại ngay sau đó.
- Thứ tự chạy chuẩn: 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08.
