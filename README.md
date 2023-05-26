# CSDL Quản lý Bệnh viện — MediCore (HQTCSDL_BenhVien)

Cơ sở dữ liệu quản lý bệnh viện đa khoa (khám ngoại trú, hồ sơ bệnh án điện tử, viện phí & BHYT) trên **Microsoft SQL Server / T-SQL**, do Nhóm 2 — HUIT thiết kế và xây dựng cho môn Hệ quản trị cơ sở dữ liệu.

Đặc điểm thiết kế của MediCore:

- **Hồ sơ bệnh án khóa được**: sau khi khóa, không ai sửa trực tiếp được (trigger chặn ở tầng DB) — bổ sung chỉ qua **phụ lục (addendum)** có lý do và người duyệt khác tác giả.
- **Audit log tự động** cho mọi sửa/xóa trên hồ sơ bệnh án và phụ lục.
- **Viện phí tính bằng procedure**: tổng hợp dịch vụ + xét nghiệm + thuốc, áp BHYT theo mức hưởng và tuyến khám (đúng tuyến / trái tuyến / cấp cứu), tách rõ phần bệnh nhân đồng chi trả.
- **Slot khám an toàn**: sức chứa ca khám được trigger bảo vệ, `booked_count` luôn đúng; bác sĩ không bị trùng lịch chồng lấn.
- **Kết quả xét nghiệm tự gắn cờ bất thường** theo khoảng tham chiếu của từng thông số.
- **Đơn thuốc chặt chẽ**: tổng lượng = liều × lần/ngày × số ngày (CHECK + procedure), chặn kê thuốc bệnh nhân dị ứng, đơn đã phát hành không sửa chi tiết.

## Công nghệ

- Microsoft SQL Server 2019+ / Azure SQL (T-SQL), SSMS
- Docker (tùy chọn) với image `mcr.microsoft.com/mssql/server:2022-latest`
- Python 3 (dùng cho bộ test quy tắc nghiệp vụ và công cụ kiểm tra dữ liệu mẫu)

## Cấu trúc thư mục

```
HQTCSDL_BenhVien/
├── database/
│   ├── 01_schema.sql            # 24 bảng + PK/FK/UNIQUE/CHECK
│   ├── 02_seed.sql              # Dữ liệu mẫu (sinh bởi tools/generate_seed.py)
│   ├── 03_indexes.sql           # 12 index bổ sung
│   ├── 04_views.sql             # 7 views báo cáo
│   ├── 05_procedures.sql        # 9 stored procedures nghiệp vụ
│   ├── 06_triggers.sql          # 7 triggers bảo vệ + audit
│   ├── 07_queries_reports.sql   # 12 truy vấn báo cáo cơ bản → nâng cao
│   └── 08_tests.sql             # 14 kịch bản kiểm thử ràng buộc (in PASS/FAIL)
├── docs/
│   ├── ERD.md                   # Sơ đồ ERD (Mermaid) + giải thích quan hệ
│   ├── DATA_DICTIONARY.md       # Từ điển dữ liệu 24 bảng
│   ├── BUSINESS_ANALYSIS.md     # Actors, use cases, business rules, các luồng
│   └── DESIGN_NOTES.md          # Quyết định thiết kế, quy tắc BHYT, bảo mật hồ sơ
├── tests/
│   └── test_medicore.py         # 23 unit test logic (Python stdlib)
├── tools/
│   ├── generate_seed.py         # Sinh 02_seed.sql (tính tự động booked_count, tiền BHYT)
│   ├── audit_seed.py            # Đối chiếu độc lập số học của seed đã sinh
│   └── check_sql_consistency.py # Rà soát nhất quán tên đối tượng giữa các file SQL
├── screenshots/README.md
├── docker-compose.yml
├── .env.example
├── TEST_REPORT.md               # Báo cáo kiểm thử
└── LICENSE                      # MIT
```

## Đối tượng dữ liệu

**24 bảng · 7 views · 9 stored procedures · 7 triggers · 12 indexes**

Dữ liệu mẫu: 7 chuyên khoa · 11 bác sĩ · 7 phòng khám · 16 bệnh nhân · 12 thẻ BHYT · 12 ca khám · 15 lịch hẹn · 13 lần khám · 14 chẩn đoán ICD-10 · 10 chỉ định / 14 kết quả xét nghiệm · 7 đơn thuốc · 7 hóa đơn (đủ đúng tuyến / trái tuyến / cấp cứu / không thẻ) · 10 thanh toán.

## Cài đặt & chạy

### Cách 1 — SSMS trên Windows

1. Kết nối tới SQL Server (LocalDB / Express / Developer).
2. Mở và chạy lần lượt các file trong `database/` theo thứ tự số **01 → 08**.
3. File `08_tests.sql` sẽ in kết quả từng test dạng `[PASS]/[FAIL]` trong cửa sổ Messages.

Tất cả script đều **chạy lại được** (idempotent): tạo DB/bảng có kiểm tra tồn tại, view/procedure/trigger dùng `CREATE OR ALTER`, seed tự dọn dữ liệu mẫu cũ trước khi chèn.

### Cách 2 — Docker

```bash
cp .env.example .env
docker compose up -d
for f in 01_schema 02_seed 03_indexes 04_views 05_procedures 06_triggers 07_queries_reports 08_tests; do
  docker exec -i medicore-sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$SA_PASSWORD" -C -i /database/$f.sql
done
```

### Kiểm thử bằng Python

```bash
python -m unittest discover -s tests -v     # 23 tests
python tools/check_sql_consistency.py       # rà soát nhất quán SQL
python tools/audit_seed.py                  # đối chiếu dữ liệu seed
```

Chi tiết kết quả kiểm thử xem tại `TEST_REPORT.md`.

## Quy tắc BHYT (tóm tắt)

Chi tiết ở `docs/DESIGN_NOTES.md`: đúng tuyến và cấp cứu hưởng nguyên mức trên thẻ (80/95/100%); trái tuyến ngoại trú hưởng 40% mức thẻ; chỉ áp dụng cho dịch vụ/thuốc thuộc danh mục BHYT; thẻ hết hạn tại ngày khám thì không áp dụng.

## Hướng mở rộng

- Row-Level Security cho dữ liệu hồ sơ theo khoa/bác sĩ phụ trách.
- Always Encrypted cho CCCD và số thẻ BHYT.
- API + giao diện web đặt lịch/khám bệnh.

## Giấy phép

MIT — xem `LICENSE`.
