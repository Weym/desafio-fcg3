import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_member_model.dart';

/// Full-screen form for staff create/edit (D-28, D-29).
/// If [member] is null → create mode. If provided → edit mode.
/// Placeholder — will be fully implemented in Task 3.
class StaffMemberFormScreen extends ConsumerStatefulWidget {
  final StaffMemberModel? member;
  const StaffMemberFormScreen({super.key, this.member});

  @override
  ConsumerState<StaffMemberFormScreen> createState() =>
      _StaffMemberFormScreenState();
}

class _StaffMemberFormScreenState extends ConsumerState<StaffMemberFormScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? 'Novo Staff' : 'Editar Staff'),
      ),
      body: const Center(child: Text('Form placeholder')),
    );
  }
}
