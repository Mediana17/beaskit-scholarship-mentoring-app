import 'package:flutter/material.dart';

import '../../models/scholarship.dart';
import '../../services/scholarship_admin_service.dart';

class ScholarshipFormScreen extends StatefulWidget {
  const ScholarshipFormScreen({super.key, this.scholarship});

  final Scholarship? scholarship;

  @override
  State<ScholarshipFormScreen> createState() => _ScholarshipFormScreenState();
}

class _ScholarshipFormScreenState extends State<ScholarshipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _organizer = TextEditingController();
  final _description = TextEditingController();
  final _requirements = TextEditingController();
  final _requiredDocuments = TextEditingController();
  final _applicationUrl = TextEditingController();
  final _service = ScholarshipAdminService();
  DateTime? _deadline;
  bool _isSaving = false;

  bool get _isEditing => widget.scholarship != null;

  String get _deadlineText {
    final deadline = _deadline;
    if (deadline == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${deadline.day} ${months[deadline.month - 1]} ${deadline.year}';
  }

  @override
  void initState() {
    super.initState();
    final scholarship = widget.scholarship;
    if (scholarship != null) {
      _title.text = scholarship.title;
      _organizer.text = scholarship.organizer;
      _description.text = scholarship.description;
      _requirements.text = scholarship.requirements;
      _requiredDocuments.text = scholarship.requiredDocuments.join('\n');
      _applicationUrl.text = scholarship.applicationUrl;
      _deadline = scholarship.deadline;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _organizer.dispose();
    _description.dispose();
    _requirements.dispose();
    _requiredDocuments.dispose();
    _applicationUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = _deadline;
    final selected = await showDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(DateTime(1900))
          ? today
          : current,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Pilih tenggat beasiswa',
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final original = widget.scholarship;
    final data = Scholarship(
      id: original?.id ?? '',
      title: _title.text.trim(),
      organizer: _organizer.text.trim(),
      description: _description.text.trim(),
      requirements: _requirements.text.trim(),
      requiredDocuments: _requiredDocuments.text
          .split('\n')
          .map((document) => document.trim())
          .where((document) => document.isNotEmpty)
          .toList(),
      applicationUrl: _applicationUrl.text.trim(),
      status: original?.status ?? 'published',
      deadline: _deadline,
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (original == null) {
        await _service.create(data);
      } else {
        await _service.update(original.id, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Beasiswa berhasil disimpan.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : 'Beasiswa gagal disimpan. Periksa koneksi, lalu coba lagi.';
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Beasiswa' : 'Tambah Beasiswa'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul*',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Judul'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizer,
                  decoration: const InputDecoration(
                    labelText: 'Penyelenggara*',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Penyelenggara'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _requirements,
                  decoration: const InputDecoration(
                    labelText: 'Persyaratan',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _requiredDocuments,
                  decoration: const InputDecoration(
                    labelText: 'Dokumen yang dibutuhkan',
                    hintText: 'Satu dokumen per baris',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_deadline),
                  readOnly: true,
                  onTap: _pickDeadline,
                  initialValue: _deadlineText,
                  decoration: InputDecoration(
                    labelText: 'Tenggat*',
                    hintText: 'Pilih tanggal tenggat',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Pilih tanggal tenggat',
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (_) =>
                      _deadline == null ? 'Tenggat wajib dipilih.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _applicationUrl,
                  decoration: const InputDecoration(
                    labelText: 'Tautan resmi',
                    hintText: 'https://contoh.id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isEmpty) return null;
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      return 'Tautan harus diawali http:// atau https://.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
