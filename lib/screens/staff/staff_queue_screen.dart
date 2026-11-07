import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/status_pill.dart';

Future<void> showUpdateStatusSheet(BuildContext context, Incident incident) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.ground,
    builder: (_) => UpdateStatusSheet(incident: incident),
  );
}

/// Staff-only sheet: choose the new status and leave a note for reporters.
class UpdateStatusSheet extends StatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late IncidentStatus _status;

  @override
  void initState() {
    super.initState();
    _status = switch (widget.incident.status) {
      IncidentStatus.submitted => IncidentStatus.inProgress,
      IncidentStatus.inProgress => IncidentStatus.resolved,
      final other => other,
    };
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<IncidentProvider>();
    final ok = await provider.updateStatus(widget.incident, _status, _note.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showMessage(context, 'Status set to ${_status.label}.');
    } else {
      showMessage(context, provider.error ?? 'Couldn\'t update the status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<IncidentProvider>().busy;
    final unchanged = _status == widget.incident.status;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${widget.incident.title} · ${widget.incident.location}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text('Update status', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                const FieldLabel('New status'),
                for (final s in IncidentStatus.values) ...[
                  _StatusOption(
                    status: s,
                    selected: _status == s,
                    current: widget.incident.status == s,
                    onTap: () => setState(() => _status = s),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                const FieldLabel('Note to reporters (required)'),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.statusNote,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Technician assigned, expected fix by 2 pm',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  label: unchanged ? 'Add note' : 'Save as ${_status.label.toLowerCase()}',
                  loading: busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({required this.status, required this.selected, required this.current, required this.onTap});

  final IncidentStatus status;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.slate : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.foreground,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [BoxShadow(color: status.foreground.withValues(alpha: 0.25), spreadRadius: 4)]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(status.hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (current) const TagPill('Current'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}