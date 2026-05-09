"""Unit tests for CRA (Coeficiente de Rendimento Acadêmico) calculation.

Tests the pure-Python CRA function without database access (D-07).
Only grades with final_grade IS NOT NULL are included (D-08).
"""

from decimal import Decimal

import pytest


class TestCalculateCRA:
    """Test GradeService.calculate_cra — pure function, no DB."""

    def test_cra_three_courses_weighted_average(self):
        """CRA with 3 courses (credits 4,3,2; grades 8.0, 7.0, 9.0).

        Expected: (4×8.0 + 3×7.0 + 2×9.0) / (4+3+2) = 71/9 ≈ 7.89
        """
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (Decimal("8.0"), 4),
            (Decimal("7.0"), 3),
            (Decimal("9.0"), 2),
        ])
        assert cra == Decimal("7.89")

    def test_cra_no_completed_grades_returns_zero(self):
        """CRA with no completed grades → 0.00."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([])
        assert cra == Decimal("0.00")

    def test_cra_excludes_none_final_grade(self):
        """CRA excludes entries where grade_final is None (in-progress courses)."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (None, 4),
            (Decimal("8.0"), 3),
        ])
        assert cra == Decimal("8.00")

    def test_cra_all_none_returns_zero(self):
        """CRA when all entries have None grade_final → 0.00."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (None, 4),
            (None, 3),
        ])
        assert cra == Decimal("0.00")

    def test_cra_single_course(self):
        """CRA with single course = that course's grade."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (Decimal("9.50"), 4),
        ])
        assert cra == Decimal("9.50")

    def test_cra_returns_decimal_type(self):
        """CRA should return Decimal, not float."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (Decimal("8.0"), 4),
        ])
        assert isinstance(cra, Decimal)

    def test_cra_accepts_float_inputs_for_compatibility(self):
        """CRA should handle float inputs (from plan verify command)."""
        from src.features.grades.services import GradeService

        cra = GradeService.calculate_cra([
            (8.0, 4),
            (7.0, 3),
            (9.0, 2),
        ])
        # Should be approximately 7.89
        assert abs(cra - Decimal("7.89")) < Decimal("0.01")


class TestGradeFinalCalculation:
    """Test grade_final auto-calculation from grade_1 and grade_2."""

    def test_final_grade_calculation(self):
        """grade_final = (grade_1 + grade_2) / 2."""
        from src.features.grades.services import GradeService

        result = GradeService.compute_final_grade(
            Decimal("8.50"), Decimal("7.00")
        )
        assert result == Decimal("7.75")

    def test_final_grade_none_when_grade_1_missing(self):
        """grade_final is None when grade_1 is not set."""
        from src.features.grades.services import GradeService

        result = GradeService.compute_final_grade(None, Decimal("7.00"))
        assert result is None

    def test_final_grade_none_when_grade_2_missing(self):
        """grade_final is None when grade_2 is not set."""
        from src.features.grades.services import GradeService

        result = GradeService.compute_final_grade(Decimal("8.50"), None)
        assert result is None

    def test_status_approved_when_passing(self):
        """Status is 'approved' when grade_final >= 5.0."""
        from src.features.grades.services import GradeService

        status = GradeService.compute_status(Decimal("5.00"))
        assert status == "approved"

    def test_status_failed_when_not_passing(self):
        """Status is 'failed' when grade_final < 5.0."""
        from src.features.grades.services import GradeService

        status = GradeService.compute_status(Decimal("4.99"))
        assert status == "failed"

    def test_status_in_progress_when_no_final(self):
        """Status remains 'in_progress' when grade_final is None."""
        from src.features.grades.services import GradeService

        status = GradeService.compute_status(None)
        assert status == "in_progress"
