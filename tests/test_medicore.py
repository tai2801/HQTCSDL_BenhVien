# -*- coding: utf-8 -*-
"""
test_medicore.py - Kiem thu mo hinh hoa cac quy tac nghiep vu cot loi cua
MediCore bang Python stdlib (unittest). Cac quy tac o day khop 1-1 voi
database/05_procedures.sql va 06_triggers.sql:

  - Tinh vien phi + BHYT (sp_calculate_invoice)
  - Khoa ho so + addendum (sp_lock_medical_record / sp_add_addendum /
    sp_approve_addendum + trg_medical_records_block_locked)
  - Slot kham (sp_book_appointment + trg_appointments_slot_guard)
  - Co abnormal ket qua xet nghiem (trg_lab_results_abnormal)
  - Tong luong thuoc + chan sua don da phat hanh + di ung
    (sp_add_prescription_item + trg_prescription_items_block_issued)

Chay:  python3 -m unittest discover -s tests -v
Luu y: day la kiem thu LOGIC mo hinh hoa, khong thay the viec chay
08_tests.sql tren SQL Server that (xem TEST_REPORT.md).
"""
import unittest
from decimal import Decimal, ROUND_HALF_UP


# ---------------------------------------------------------------- BHYT / vien phi
def effective_coverage(coverage_percent, referral_type):
    """Dung tuyen / cap cuu: huong nguyen muc. Trai tuyen: 40% muc tren the."""
    if coverage_percent is None:
        return Decimal("0")
    cov = Decimal(str(coverage_percent))
    if referral_type == "WRONG":
        return (cov * Decimal("0.4")).quantize(Decimal("0.01"))
    return cov


def calculate_invoice(lines, coverage_percent, referral_type):
    """lines: list of (item_type, line_total, eligible)."""
    eff = effective_coverage(coverage_percent, referral_type)
    totals = {"SERVICE": Decimal("0"), "LAB": Decimal("0"), "MED": Decimal("0")}
    eligible_total = Decimal("0")
    for item_type, total, eligible in lines:
        totals[item_type] += Decimal(str(total))
        if eligible:
            eligible_total += Decimal(str(total))
    gross = sum(totals.values())
    ins = (eligible_total * eff / Decimal(100)).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP)
    return {
        "services_total": totals["SERVICE"], "labs_total": totals["LAB"],
        "meds_total": totals["MED"], "gross_total": gross,
        "effective_coverage": eff, "insurance_payable": ins,
        "patient_copay": gross - ins,
    }


class TestInsuranceBilling(unittest.TestCase):
    LINES = [("SERVICE", 150000, True), ("LAB", 60000, True), ("MED", 45000, True)]

    def test_correct_route_full_coverage_percent(self):
        r = calculate_invoice(self.LINES, 80, "CORRECT")
        self.assertEqual(r["gross_total"], Decimal("255000"))
        self.assertEqual(r["insurance_payable"], Decimal("204000.00"))
        self.assertEqual(r["patient_copay"], Decimal("51000.00"))

    def test_wrong_route_reduces_to_40_percent_of_entitlement(self):
        r = calculate_invoice(self.LINES, 80, "WRONG")
        self.assertEqual(r["effective_coverage"], Decimal("32.00"))
        self.assertEqual(r["insurance_payable"], Decimal("81600.00"))
        self.assertEqual(r["patient_copay"], Decimal("173400.00"))

    def test_emergency_treated_as_correct_route(self):
        r = calculate_invoice(self.LINES, 95, "EMERGENCY")
        self.assertEqual(r["effective_coverage"], Decimal("95"))
        self.assertEqual(r["insurance_payable"], Decimal("242250.00"))

    def test_no_card_patient_pays_all(self):
        r = calculate_invoice(self.LINES, None, "CORRECT")
        self.assertEqual(r["insurance_payable"], Decimal("0.00"))
        self.assertEqual(r["patient_copay"], Decimal("255000"))

    def test_ineligible_lines_excluded_from_insurance(self):
        lines = self.LINES + [("SERVICE", 250000, False)]  # tu van dinh duong
        r = calculate_invoice(lines, 100, "CORRECT")
        self.assertEqual(r["gross_total"], Decimal("505000"))
        self.assertEqual(r["insurance_payable"], Decimal("255000.00"))
        self.assertEqual(r["patient_copay"], Decimal("250000.00"))

    def test_copay_identity_always_holds(self):
        for cov, ref in [(80, "CORRECT"), (100, "WRONG"), (95, "EMERGENCY"), (None, "WRONG")]:
            r = calculate_invoice(self.LINES, cov, ref)
            self.assertEqual(r["patient_copay"],
                             r["gross_total"] - r["insurance_payable"])


# ---------------------------------------------------------------- Khoa ho so
class MedicalRecord:
    def __init__(self):
        self.status = "DRAFT"
        self.conclusion = "Kết luận mẫu"
        self.addenda = []

    def edit(self, **fields):
        if self.status == "LOCKED":
            raise PermissionError("Hồ sơ đã khóa: không sửa trực tiếp")
        for k, v in fields.items():
            setattr(self, k, v)

    def lock(self):
        if self.status == "LOCKED":
            raise ValueError("Hồ sơ đã khóa trước đó")
        self.status = "LOCKED"

    def add_addendum(self, author, content, reason):
        if self.status != "LOCKED":
            raise ValueError("Hồ sơ chưa khóa: sửa trực tiếp, không cần phụ lục")
        if not reason or not reason.strip():
            raise ValueError("Phụ lục bắt buộc ghi lý do")
        add = {"author": author, "content": content, "reason": reason,
               "approval_status": "PENDING", "approved_by": None}
        self.addenda.append(add)
        return add

    def approve_addendum(self, add, approver, approve=True):
        if add["approval_status"] != "PENDING":
            raise ValueError("Phụ lục đã được xử lý")
        if add["author"] == approver:
            raise ValueError("Người duyệt không được là tác giả")
        add["approval_status"] = "APPROVED" if approve else "REJECTED"
        add["approved_by"] = approver


class TestRecordLocking(unittest.TestCase):
    def test_edit_draft_ok_lock_then_edit_blocked(self):
        r = MedicalRecord()
        r.edit(conclusion="Kết luận mới")
        r.lock()
        with self.assertRaises(PermissionError):
            r.edit(conclusion="Cố sửa")

    def test_addendum_only_for_locked_record(self):
        r = MedicalRecord()
        with self.assertRaises(ValueError):
            r.add_addendum("bs1", "nội dung", "lý do")
        r.lock()
        add = r.add_addendum("bs1", "Bổ sung kết quả", "Kết quả trả muộn")
        self.assertEqual(add["approval_status"], "PENDING")

    def test_addendum_requires_reason(self):
        r = MedicalRecord()
        r.lock()
        with self.assertRaises(ValueError):
            r.add_addendum("bs1", "nội dung", "  ")

    def test_author_cannot_approve_own_addendum(self):
        r = MedicalRecord()
        r.lock()
        add = r.add_addendum("bs1", "nội dung", "lý do")
        with self.assertRaises(ValueError):
            r.approve_addendum(add, "bs1")
        r.approve_addendum(add, "bs2")
        self.assertEqual(add["approval_status"], "APPROVED")


# ---------------------------------------------------------------- Slot kham
class Schedule:
    ACTIVE = {"BOOKED", "CHECKED_IN", "COMPLETED", "NO_SHOW"}

    def __init__(self, capacity, status="OPEN"):
        self.capacity = capacity
        self.status = status
        self.appointments = []  # list of (patient_id, status)

    @property
    def booked_count(self):
        return sum(1 for _p, s in self.appointments if s in self.ACTIVE)

    def book(self, patient_id):
        if self.status != "OPEN":
            raise ValueError("Ca khám không còn mở")
        if self.booked_count >= self.capacity:
            raise ValueError("Ca khám đã hết slot")
        if any(p == patient_id and s in ("BOOKED", "CHECKED_IN")
               for p, s in self.appointments):
            raise ValueError("Bệnh nhân đã có lịch trong ca này")
        self.appointments.append((patient_id, "BOOKED"))

    def cancel(self, patient_id):
        self.appointments = [
            (p, "CANCELLED" if p == patient_id and s == "BOOKED" else s)
            for p, s in self.appointments]


class TestScheduling(unittest.TestCase):
    def test_full_slot_rejected(self):
        s = Schedule(capacity=2)
        s.book(1)
        s.book(2)
        with self.assertRaises(ValueError):
            s.book(3)

    def test_cancel_frees_slot(self):
        s = Schedule(capacity=1)
        s.book(1)
        s.cancel(1)
        s.book(2)
        self.assertEqual(s.booked_count, 1)

    def test_closed_schedule_rejected(self):
        s = Schedule(capacity=10, status="CLOSED")
        with self.assertRaises(ValueError):
            s.book(1)

    def test_duplicate_booking_same_patient_rejected(self):
        s = Schedule(capacity=10)
        s.book(1)
        with self.assertRaises(ValueError):
            s.book(1)


# ---------------------------------------------------------------- Xet nghiem
def is_abnormal(value, ref_low, ref_high):
    if value is None:
        return False
    if ref_low is not None and value < ref_low:
        return True
    if ref_high is not None and value > ref_high:
        return True
    return False


class TestLabAbnormal(unittest.TestCase):
    def test_glucose_high_flagged(self):
        self.assertTrue(is_abnormal(Decimal("7.8"), Decimal("3.9"), Decimal("5.6")))

    def test_hgb_low_flagged(self):
        self.assertTrue(is_abnormal(Decimal("102"), Decimal("120"), Decimal("155")))

    def test_normal_not_flagged(self):
        self.assertFalse(is_abnormal(Decimal("5.4"), Decimal("3.9"), Decimal("5.6")))

    def test_one_sided_reference(self):
        self.assertTrue(is_abnormal(Decimal("6.1"), None, Decimal("5.2")))
        self.assertFalse(is_abnormal(Decimal("4.9"), None, Decimal("5.2")))

    def test_text_only_result_not_flagged(self):
        self.assertFalse(is_abnormal(None, Decimal("0"), Decimal("1")))


# ---------------------------------------------------------------- Don thuoc
def prescription_total(dose, intakes_per_day, days):
    total = Decimal(str(dose)) * intakes_per_day * days
    if total <= 0:
        raise ValueError("Tổng lượng phải > 0")
    return total


class Prescription:
    def __init__(self, patient_allergies=()):
        self.status = "DRAFT"
        self.items = []
        self.allergies = [a.lower() for a in patient_allergies]

    def add_item(self, med_name, ingredient, dose, intakes, days):
        if self.status != "DRAFT":
            raise PermissionError("Đơn đã phát hành: không sửa chi tiết")
        for allergen in self.allergies:
            if allergen in med_name.lower() or allergen in ingredient.lower() \
                    or allergen in ingredient.lower():
                raise ValueError("Dị ứng: không kê được thuốc này")
        total = prescription_total(dose, intakes, days)
        self.items.append((med_name, total))
        return total

    def issue(self):
        self.status = "ISSUED"


class TestPrescription(unittest.TestCase):
    def test_total_quantity_formula(self):
        self.assertEqual(prescription_total(1, 2, 30), Decimal("60"))
        self.assertEqual(prescription_total("0.5", 3, 7), Decimal("10.5"))

    def test_issued_prescription_cannot_be_edited(self):
        p = Prescription()
        p.add_item("Amlodipine 5mg", "Amlodipine", 1, 1, 30)
        p.issue()
        with self.assertRaises(PermissionError):
            p.add_item("Losartan 50mg", "Losartan", 1, 1, 30)

    def test_allergy_blocks_prescription(self):
        p = Prescription(patient_allergies=["Penicillin"])
        with self.assertRaises(ValueError):
            p.add_item("Amoxicillin 500mg", "Amoxicillin (nhóm Penicillin)", 1, 3, 5)

    def test_non_allergic_medication_ok(self):
        p = Prescription(patient_allergies=["Penicillin"])
        total = p.add_item("Paracetamol 500mg", "Paracetamol", 1, 3, 3)
        self.assertEqual(total, Decimal("9"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
