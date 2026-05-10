---
status: diagnosed
trigger: "Deletar confirmation on resource cards executes a toggle (disable) instead of actually deleting the resource"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Backend DELETE /resources/{id} endpoint implements soft-delete (is_available=False) which is identical behavior to toggle — Flutter frontend correctly calls deleteResource but backend just flips availability
test: Read backend controller + service for DELETE endpoint
expecting: If backend sets is_available=False, that explains why "delete" looks like "toggle"
next_action: Return diagnosis — root cause confirmed

## Symptoms

expected: Tapping Deletar and confirming should permanently remove (or truly soft-delete) the resource from the list
actual: Confirming deletion just changes the resource's availability state (is_available=False), making it appear as a toggle
errors: No errors — the operation "succeeds" but does the wrong thing
reproduction: 3-dot menu → Deletar → Confirm → resource becomes unavailable instead of disappearing
started: Since implementation

## Eliminated

- hypothesis: Flutter _handleDelete method calls toggleAvailability instead of deleteResource
  evidence: Code at line 403 of staff_resources_screen.dart clearly calls `deleteResource(resource.id)`. The switch/case at line 327 correctly dispatches to `_handleDelete` for the 'delete' case.
  timestamp: 2026-05-09

- hypothesis: staffResourceService.deleteResource sends PUT instead of DELETE
  evidence: Code at line 77 of staff_resource_service.dart uses `_client.dio.delete('/resources/$id')` — correct HTTP method
  timestamp: 2026-05-09

## Evidence

- timestamp: 2026-05-09
  checked: Flutter screen PopupMenuButton onSelected (lines 319-329)
  found: case 'delete' correctly calls _handleDelete(context, ref, resource)
  implication: Frontend dispatch is correct

- timestamp: 2026-05-09
  checked: Flutter _handleDelete method (lines 376-421)
  found: After dialog confirmation, calls ref.read(staffResourceServiceProvider).deleteResource(resource.id) — correct method
  implication: Frontend calls the right service method

- timestamp: 2026-05-09
  checked: StaffResourceService.deleteResource (line 76-78)
  found: Uses _client.dio.delete('/resources/$id') — correct HTTP DELETE verb
  implication: Frontend sends correct HTTP request to backend

- timestamp: 2026-05-09
  checked: Backend controller DELETE /resources/{id} (controllers.py lines 126-137)
  found: Calls resource_service.soft_delete_resource(db, resource_id) — named "soft-delete"
  implication: Backend endpoint is designed as soft-delete, not actual delete

- timestamp: 2026-05-09
  checked: Backend service soft_delete_resource (services.py lines 132-150)
  found: Implementation is just `resource.is_available = False` — exactly the same as what toggleAvailability does via PUT with {is_available: false}
  implication: ROOT CAUSE CONFIRMED — DELETE endpoint does the exact same thing as toggle-off

## Resolution

root_cause: The backend `DELETE /resources/{id}` endpoint calls `soft_delete_resource()` which only sets `is_available=False` on the database row — this is functionally identical to the toggle-off operation (`PUT /resources/{id}` with `{is_available: false}`), making "Deletar" indistinguishable from "Desativar" to the user.
fix: (not yet applied)
verification: (not yet verified)
files_changed: []
