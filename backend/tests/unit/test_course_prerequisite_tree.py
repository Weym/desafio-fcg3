from __future__ import annotations

from uuid import UUID, uuid4

from src.features.courses.services import CourseService


def _collect_descendant_ids(tree):
    ids: list[UUID] = []
    for node in tree:
        ids.append(node.id)
        ids.extend(_collect_descendant_ids(node.prerequisites))
    return ids


def test_build_prerequisite_tree_never_reinserts_root_course_in_cycle() -> None:
    root_id = uuid4()
    child_id = uuid4()
    grandchild_id = uuid4()

    rows = [
        (child_id, "B", "Algorithms I", root_id, 1),
        (grandchild_id, "C", "Algorithms II", child_id, 2),
        (root_id, "A", "Intro to Computing", grandchild_id, 3),
    ]

    tree = CourseService._build_prerequisite_tree(root_id, rows)

    assert [node.code for node in tree] == ["B"]
    assert [node.code for node in tree[0].prerequisites] == ["C"]
    assert root_id not in _collect_descendant_ids(tree)
    assert all(node.code != "A" for node in tree[0].prerequisites)


def test_build_prerequisite_tree_preserves_acyclic_nested_order() -> None:
    root_id = uuid4()
    child_id = uuid4()
    grandchild_id = uuid4()

    rows = [
        (child_id, "B", "Data Structures", root_id, 1),
        (grandchild_id, "C", "Discrete Math", child_id, 2),
    ]

    tree = CourseService._build_prerequisite_tree(root_id, rows)

    assert len(tree) == 1
    assert tree[0].id == child_id
    assert tree[0].code == "B"
    assert len(tree[0].prerequisites) == 1
    assert tree[0].prerequisites[0].id == grandchild_id
    assert tree[0].prerequisites[0].code == "C"
    assert tree[0].prerequisites[0].prerequisites == []
