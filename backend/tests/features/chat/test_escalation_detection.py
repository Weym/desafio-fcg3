"""Escalation detection tests (HI-01, HI-02, HI-10).

Tests keyword-based escalation detection (before AI call),
AI response escalation detection (procurar a secretaria phrases),
and ChatSession model field presence.
"""

import uuid

import pytest

from src.features.chat.models import ChatSession
from src.features.webhook.background import (
    _should_escalate_by_keywords,
    _should_escalate_by_ai_response,
    ESCALATION_KEYWORDS,
    ESCALATION_BOT_PHRASES,
    ESCALATION_ACK_MESSAGE,
)


class TestKeywordEscalationDetection:
    """HI-01: Escalation keyword detection triggers before AI call."""

    def test_keyword_atendente_triggers_escalation(self):
        assert _should_escalate_by_keywords("quero falar com um atendente") is True

    def test_keyword_humano_triggers_escalation(self):
        assert _should_escalate_by_keywords("preciso de um humano") is True

    def test_keyword_pessoa_triggers_escalation(self):
        assert _should_escalate_by_keywords("quero falar com uma pessoa") is True

    def test_keyword_secretaria_triggers_escalation(self):
        assert _should_escalate_by_keywords("preciso da secretaria") is True

    def test_keyword_falar_com_alguem_triggers_escalation(self):
        assert _should_escalate_by_keywords("eu preciso falar com alguem agora") is True

    def test_keyword_atendimento_humano_triggers_escalation(self):
        assert _should_escalate_by_keywords("quero atendimento humano") is True

    def test_normal_academic_question_does_not_trigger(self):
        assert _should_escalate_by_keywords("qual minha nota em calculo?") is False

    def test_empty_message_does_not_trigger(self):
        assert _should_escalate_by_keywords("") is False

    def test_keyword_detection_is_case_insensitive(self):
        assert _should_escalate_by_keywords("QUERO ATENDENTE") is True

    def test_keyword_detection_strips_whitespace(self):
        assert _should_escalate_by_keywords("  atendente  ") is True


class TestAIResponseEscalationDetection:
    """HI-02: AI response escalation detection (procurar a secretaria phrases)."""

    def test_procurar_a_secretaria_triggers_escalation(self):
        response = "Recomendo procurar a secretaria para resolver esse caso."
        assert _should_escalate_by_ai_response(response) is True

    def test_secretaria_presencialmente_triggers_escalation(self):
        response = "Voce pode ir ate a secretaria presencialmente para resolver."
        assert _should_escalate_by_ai_response(response) is True

    def test_entrar_em_contato_com_a_secretaria_triggers_escalation(self):
        response = "Sugiro entrar em contato com a secretaria para mais informacoes."
        assert _should_escalate_by_ai_response(response) is True

    def test_normal_ai_response_does_not_trigger(self):
        response = "Sua nota em calculo e 7.5. Precisa de mais informacoes?"
        assert _should_escalate_by_ai_response(response) is False

    def test_ai_escalation_is_case_insensitive(self):
        response = "PROCURAR A SECRETARIA para resolver."
        assert _should_escalate_by_ai_response(response) is True

    def test_empty_ai_response_does_not_trigger(self):
        assert _should_escalate_by_ai_response("") is False


class TestChatSessionModelFields:
    """HI-10: ChatSession model has 4-value status + assigned_staff_id + escalated_at fields."""

    def test_model_has_assigned_staff_id_field(self):
        assert hasattr(ChatSession, "assigned_staff_id")

    def test_model_has_escalated_at_field(self):
        assert hasattr(ChatSession, "escalated_at")

    def test_model_status_check_constraint_includes_four_values(self):
        """Verify the CHECK constraint text contains all 4 status values."""
        check_constraints = [
            c for c in ChatSession.__table_args__
            if hasattr(c, "name") and c.name == "ck_chat_sessions_status"
        ]
        assert len(check_constraints) == 1
        # sqltext contains all four statuses
        constraint_text = str(check_constraints[0].sqltext)
        assert "active" in constraint_text
        assert "closed" in constraint_text
        assert "human_needed" in constraint_text
        assert "human_active" in constraint_text

    def test_model_has_student_relationship(self):
        assert hasattr(ChatSession, "student")

    def test_escalation_ack_message_defined(self):
        assert ESCALATION_ACK_MESSAGE == "Vou transferir voce para um atendente. Aguarde um momento."
