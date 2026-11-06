import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../common/incident_details_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.initialCategory});

  final IncidentCategory? initialCategory;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  static const _maxPhotos = 3;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _room = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  String? _building;
  Urgency _urgency = Urgency.medium;
  bool _hideName = true;
  bool _categoryError = false;
  final List<Uint8List> _photos = [];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _description.addListener(() => setState(() {})); // live character count
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 75);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photos.add(bytes));
    } catch (_) {
      if (mounted) showMessage(context, 'Couldn\'t open the camera or gallery.');
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!formOk || _category == null) return;

    final provider = context.read<IncidentProvider>();
    final ok = await provider.submit(
      title: _title.text,
      description: _description.text,
      category: _category!,
      building: _building!,
      room: _room.text,
      urgency: _urgency,
      hideName: _hideName,
      photos: List.of(_photos),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showMessage(context, 'Report submitted. You\'ll see updates on the Reports tab.');
    } else {
      showMessage(context, provider.error ?? 'Couldn\'t submit the report.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final similar = (_category != null && _building != null)
        ? provider.similarOpen(_category!, _building!)
        : const <Incident>[];

    return Scaffold(
      appBar: AppBar(title: const Text('New report')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const FieldLabel('What kind of issue?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in IncidentCategory.values)
                    SelectChip(
                      label: c.label,
                      icon: c.icon,
                      selected: _category == c,
                      onTap: () => setState(() {
                        _category = c;
                        _categoryError = false;
                      }),
                    ),
                ],
              ),
              if (_categoryError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text('Choose a category', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              const SizedBox(height: 20),
              const FieldLabel('Title'),
              TextFormField(
                controller: _title,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.title,
                decoration: const InputDecoration(hintText: 'e.g. Sockets dead in Library L2', counterText: ''),
              ),
              const SizedBox(height: 16),
              FieldLabel('Description',
                  trailing: Text('${_description.text.length} / 500',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted))),
              TextFormField(
                controller: _description,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.description,
                decoration: const InputDecoration(
                  hintText: 'What happened, since when, who is affected?',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Building'),
                        DropdownButtonFormField<String>(
                          initialValue: _building,
                          isExpanded: true,
                          hint: const Text('Select'),
                          items: [
                            for (final b in kCampusBuildings) DropdownMenuItem(value: b, child: Text(b)),
                          ],
                          validator: (v) => v == null ? 'Pick a building' : null,
                          onChanged: (v) => setState(() => _building = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Floor / room'),
                        TextFormField(
                          controller: _room,
                          decoration: const InputDecoration(hintText: 'Optional'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (similar.isNotEmpty) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  icon: Icons.people_outline,
                  background: AppColors.submittedBg,
                  foreground: AppColors.submittedFg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${similar.length} similar open report${similar.length == 1 ? '' : 's'} in this building. '
                        'Add yourself as affected instead?',
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => IncidentDetailsScreen(incidentId: similar.first.id),
                        )),
                        child: Text('View "${similar.first.title}"',
                            style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const FieldLabel('How urgent?'),
              SegmentedButton<Urgency>(
                showSelectedIcon: false,
                segments: [
                  for (final u in Urgency.values) ButtonSegment(value: u, label: Text(u.label)),
                ],
                selected: {_urgency},
                onSelectionChanged: (s) => setState(() => _urgency = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.slate,
                  selectedForegroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              const SizedBox(height: 20),
              const FieldLabel('Photos (optional, up to 3)'),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _photos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _PhotoThumb(bytes: _photos[i], onRemove: () => setState(() => _photos.removeAt(i))),
                      ),
                    if (_photos.length < _maxPhotos) _AddPhotoButton(onTap: _addPhoto),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: SwitchListTile(
                  value: _hideName,
                  onChanged: (v) => setState(() => _hideName = v),
                  activeTrackColor: AppColors.slate,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Hide my name from other students',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Staff can still see who reported it.', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(label: 'Submit report', loading: provider.busy, onPressed: _submit),
              if (provider.busy && _photos.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Uploading photos…', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(bytes, width: 84, height: 84, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: AppColors.ink.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.white, semanticLabel: 'Remove photo'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8E979A), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.slate),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}