# PHÂN TÍCH NGHIỆP VỤ — MEDICORE HOSPITAL DATABASE

Bệnh viện đa khoa quy mô vừa, trọng tâm: khám ngoại trú, hồ sơ bệnh án điện tử và viện phí có BHYT. Tài liệu này do Nhóm 2 phân tích và thiết kế cho học phần Hệ quản trị cơ sở dữ liệu.

## 1. Actors

| Actor | Vai trò trong hệ thống |
|---|---|
| Bệnh nhân | Đặt lịch, đến khám, thanh toán phần đồng chi trả, xem lịch sử điều trị |
| Lễ tân / Tiếp đón | Quản lý ca khám, check-in lịch hẹn, tạo hồ sơ định danh bệnh nhân mới |
| Bác sĩ | Khám, ghi hồ sơ bệnh án, chẩn đoán ICD-10, chỉ định xét nghiệm, kê đơn, khóa hồ sơ, tạo/duyệt phụ lục |
| Kỹ thuật viên xét nghiệm | Nhận chỉ định, nhập kết quả từng thông số |
| Trưởng khoa / Bác sĩ duyệt | Duyệt kết quả xét nghiệm, duyệt phụ lục hồ sơ |
| Thu ngân | Lập hóa đơn viện phí, ghi nhận thanh toán, đối soát |
| Cơ quan BHYT (bên ngoài) | Nhận hồ sơ thanh toán (claim), duyệt và chi trả phần BHYT |
| Quản trị hệ thống | Quản lý tài khoản, danh mục khoa/phòng/dịch vụ/thuốc |

## 2. Use Cases chính

| Mã | Use case | Actor chính | Hiện thực trong dự án |
|---|---|---|---|
| UC01 | Đăng ký hồ sơ định danh bệnh nhân | Lễ tân | Bảng `patients`, CCCD UNIQUE |
| UC02 | Mở ca khám cho bác sĩ | Lễ tân/Admin | `doctor_schedules` + UNIQUE + trigger chống chồng lấn |
| UC03 | Đặt lịch khám | Bệnh nhân/Lễ tân | `sp_book_appointment` |
| UC04 | Check-in và bắt đầu lần khám | Lễ tân | `sp_check_in_appointment` (tạo visit + hồ sơ DRAFT) |
| UC05 | Ghi hồ sơ bệnh án & chẩn đoán | Bác sĩ | `medical_records`, `diagnoses` |
| UC06 | Chỉ định & trả kết quả xét nghiệm | Bác sĩ / KTV | `lab_orders`, `sp_record_lab_result`, cờ abnormal tự động |
| UC07 | Kê đơn thuốc | Bác sĩ | `sp_add_prescription_item` (validate liều, dị ứng) |
| UC08 | Khóa hồ sơ bệnh án | Bác sĩ | `sp_lock_medical_record` |
| UC09 | Bổ sung hồ sơ đã khóa bằng phụ lục | Bác sĩ + người duyệt | `sp_add_addendum`, `sp_approve_addendum` |
| UC10 | Lập hóa đơn & tính BHYT | Thu ngân | `sp_calculate_invoice` |
| UC11 | Thanh toán (bệnh nhân / BHYT) | Thu ngân | `sp_pay_invoice` |
| UC12 | Báo cáo lượt khám, doanh thu, công nợ BHYT | Quản lý | Views V1–V7 + `07_queries_reports.sql` |

## 3. Business Rules

| Mã | Quy tắc |
|---|---|
| BR01 | Một người = một hồ sơ định danh duy nhất theo CCCD; mọi lần khám dùng chung hồ sơ này. |
| BR02 | Một bác sĩ không có hai ca làm việc chồng lấn thời gian trong cùng ngày; một phòng không phục vụ hai ca cùng lúc (UNIQUE theo ca + trigger kiểm tra giao khoảng giờ). |
| BR03 | Số lịch hẹn còn hiệu lực trong một ca không vượt sức chứa của ca; `booked_count` do hệ thống (trigger) duy trì, con người không sửa tay. |
| BR04 | Kết quả xét nghiệm phải thuộc một chỉ định, chỉ định phải thuộc đúng một lần khám — không có kết quả "mồ côi". |
| BR05 | Kết quả nằm ngoài khoảng tham chiếu của chính thông số đó được tự động gắn cờ bất thường. |
| BR06 | Tổng lượng thuốc phát = liều/lần × số lần/ngày × số ngày; sai công thức là dữ liệu không hợp lệ ở mọi tầng (CHECK + procedure + test). |
| BR07 | Bệnh nhân có tiền sử dị ứng với hoạt chất/thuốc thì hệ thống chặn kê thuốc đó và yêu cầu bác sĩ đổi thuốc. |
| BR08 | Đơn thuốc đã phát hành (ISSUED trở đi) không sửa chi tiết; muốn thay đổi phải hủy đơn và tạo đơn mới để giữ dấu vết. |
| BR09 | Hồ sơ bệnh án chỉ khóa khi lần khám đã hoàn tất, có chẩn đoán chính và có kết luận. Sau khi khóa, cấm sửa trực tiếp ở tầng database (trigger), không chỉ ở giao diện. |
| BR10 | Bổ sung sau khóa chỉ bằng phụ lục: có lý do, có tác giả, phải được một bác sĩ khác duyệt mới có hiệu lực. |
| BR11 | Mọi sửa/xóa trên hồ sơ bệnh án và phụ lục đều ghi audit log (ai, khi nào, giá trị trước/sau dạng tóm tắt). |
| BR12 | Viện phí = dịch vụ đã thực hiện + xét nghiệm đã có kết quả + thuốc của đơn đã phát hành. Giá lấy snapshot tại thời điểm thực hiện/lập hóa đơn. |
| BR13 | BHYT chỉ chi trả cho dòng đủ điều kiện; mức hưởng hiệu lực: đúng tuyến/cấp cứu = mức trên thẻ, trái tuyến ngoại trú = 40% mức trên thẻ (quy tắc mô phỏng của dự án — xem DESIGN_NOTES). Thẻ hết hạn tại ngày khám = không áp dụng. |
| BR14 | Đồng chi trả của bệnh nhân = tổng viện phí − BHYT chi trả − giảm giá; không bên nào được trả vượt phần phải trả của mình. |
| BR15 | Doanh thu báo cáo là tiền **đã thu** (payments), không phải tổng hóa đơn phát hành. |

## 4. Luồng chính (Main Flow) — một lần khám trọn vẹn

1. Lễ tân mở ca khám (bác sĩ – phòng – ca – sức chứa).
2. Bệnh nhân đặt lịch qua `sp_book_appointment` → hệ thống kiểm tra ca còn mở, còn slot.
3. Bệnh nhân đến, lễ tân check-in → tạo lần khám + hồ sơ bệnh án DRAFT.
4. Bác sĩ khám, ghi hồ sơ, nhập chẩn đoán chính/phụ (ICD-10).
5. Bác sĩ chỉ định xét nghiệm; KTV nhập kết quả; hệ thống tự gắn cờ bất thường; bác sĩ duyệt kết quả.
6. Bác sĩ kê đơn từng dòng qua procedure (hệ thống kiểm tra dị ứng, tính tổng lượng), rồi phát hành đơn.
7. Lần khám chuyển COMPLETED; bác sĩ khóa hồ sơ.
8. Thu ngân lập hóa đơn: hệ thống tổng hợp 3 nguồn, áp BHYT theo tuyến khám.
9. Bệnh nhân trả phần đồng chi trả; BHYT trả phần của mình sau khi duyệt claim → hóa đơn PAID.

## 5. Luồng thay thế (Alternative Flow)

- **Khám không hẹn trước (walk-in):** lễ tân tạo lần khám trực tiếp (`appointment_id = NULL`) — vẫn dùng chung quy trình từ bước 4.
- **Bệnh nhân không có thẻ BHYT / thẻ hết hạn:** hóa đơn vẫn lập, BHYT chi trả = 0, bệnh nhân trả toàn bộ.
- **Khám trái tuyến:** hóa đơn vẫn lập, mức hưởng hiệu lực giảm còn 40% mức thẻ.
- **Kết quả xét nghiệm trả muộn sau khi hồ sơ đã khóa:** bác sĩ tạo phụ lục kèm kết quả và lý do; trưởng khoa duyệt.
- **Bệnh nhân trả một phần:** hóa đơn ở trạng thái PARTIALLY_PAID, phần còn lại hiển thị ở view công nợ `v_unpaid_invoices`.
- **Đổi thuốc sau khi đơn đã phát hành:** hủy đơn cũ (giữ dấu vết), tạo đơn mới — không sửa đơn cũ.

## 6. Luồng ngoại lệ (Exception Flow)

| Tình huống | Hệ thống xử lý |
|---|---|
| Đặt lịch vào ca đã đầy / đã đóng / ngày đã qua | Procedure từ chối với mã lỗi 50002–50004, không tạo dữ liệu |
| Hai ca của cùng bác sĩ chồng giờ | Trigger rollback, báo lỗi rõ ràng |
| Kê thuốc bệnh nhân dị ứng | Procedure từ chối (50053) trước khi ghi |
| Sửa hồ sơ đã khóa qua bất kỳ đường nào (kể cả SQL trực tiếp) | Trigger rollback + thông báo phải dùng phụ lục |
| Người duyệt phụ lục chính là tác giả | Procedure từ chối (50042) — nguyên tắc bốn mắt |
| Thanh toán vượt phần còn phải trả | Procedure từ chối (50084) |
| Nhập kết quả cho chỉ định đã duyệt/đã hủy | Procedure từ chối (50061) |
| Lập hóa đơn lần 2 cho cùng lần khám | Procedure từ chối (50072) + UNIQUE ở bảng invoices |
| CCCD trùng khi đăng ký bệnh nhân mới | UNIQUE từ chối — lễ tân phải tìm và dùng hồ sơ định danh đã có |
