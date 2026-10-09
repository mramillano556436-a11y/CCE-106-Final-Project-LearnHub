import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tutor_profile.dart';
import '../../services/cloudinary_service.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import '../shared/account_settings_screen.dart';

/// Tutor's public listing. Shown as "Step 2 of 2" right after registration
/// ([onboarding]) and as the Profile tab afterwards.
class TutorProfileSetupScreen extends StatefulWidget {
  const TutorProfileSetupScreen({super.key, required this.onboarding});
  final bool onboarding;

  @override
  State<TutorProfileSetupScreen> createState() => _TutorProfileSetupScreenState();
}

class _TutorProfileSetupScreenState extends State<TutorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _subjects = TextEditingController();
  final _rate = TextEditingController();
  final _about = TextEditingController();
  final _days = <String>{};
  TimeOfDay? _from;
  TimeOfDay? _to;
  String _photoUrl = '';
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = context.read<Session>().currentUser;
    final p = await Db.instance.getTutorProfile(me.uid);
    if (!mounted) return;
    setState(() {
      _name.text = me.name;
      _photoUrl = me.photoUrl;
      if (p != null) {
        _subjects.text = p.subjects.join(', ');
        _rate.text = p.rateCents > 0 ? (p.rateCents / 100).toStringAsFixed(2) : '';
        _about.text = p.about;
        _days.addAll(p.availableDays);
        _from = _parseTime(p.timeFrom);
        _to = _parseTime(p.timeTo);
        if (p.photoUrl.isNotEmpty) _photoUrl = p.photoUrl;
      }
      _loading = false;
    });
  }

  TimeOfDay? _parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$').firstMatch(s);
    if (m == null) return null;
    final h = int.parse(m[1]!) % 12 + (m[3] == 'PM' ? 12 : 0);
    return TimeOfDay(hour: h, minute: int.parse(m[2]!));
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  void dispose() {
    for (final c in [_name, _subjects, _rate, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _busy = true);
    await guard(context, () async {
      final file = await CloudinaryService.pickAndUploadImage(folder: 'avatars');
      if (file != null) setState(() => _photoUrl = file.url);
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickTime(bool from) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (from ? _from : _to) ?? TimeOfDay(hour: from ? 14 : 20, minute: 0),
    );
    if (t != null) setState(() => from ? _from = t : _to = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      showSnack(context, 'Select at least one available day.');
      return;
    }
    if (_from == null || _to == null) {
      showSnack(context, 'Set your available hours.');
      return;
    }
    final me = context.read<Session>().currentUser;
    final subjects = _subjects.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
    setState(() => _busy = true);
    await guard(
      context,
      () => Db.instance.updateTutorProfile(
        uid: me.uid,
        name: _name.text.trim(),
        photoUrl: _photoUrl,
        subjects: subjects,
        rateCents: pesosToCents(_rate.text)!,
        availableDays: weekDays.where(_days.contains).toList(),
        timeFrom: _formatTime(_from),
        timeTo: _formatTime(_to),
        about: _about.text.trim(),
      ),
      success: widget.onboarding ? 'Profile submitted for admin approval.' : 'Profile saved.',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final rate = pesosToCents(_rate.text);
    return Scaffold(
      appBar: brandAppBar(
        title: widget.onboarding ? 'Set Up Your Profile' : 'My Tutor Profile',
        subtitle: widget.onboarding ? 'Step 2 of 2 · Your public listing' : 'What clients see in the directory',
        actions: [
          if (widget.onboarding)
            TextButton(
              onPressed: () => context.read<Session>().signOut(),
              child: const Text('Log out', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              tooltip: 'Account settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountSettingsScreen())),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: PageBody(
                children: [
                  if (!widget.onboarding) _ApprovalBanner(uid: context.read<Session>().currentUser.uid),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                    child: Column(children: [
                      EditableAvatar(name: _name.text, photoUrl: _photoUrl, onEdit: _busy ? null : _pickPhoto),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        decoration:
                            const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.badge_outlined)),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                      ),
                    ]),
                  ),
                  const SectionTitle('Teaching'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _subjects,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Subjects Taught',
                            hintText: 'e.g. Mathematics, Calculus, Physics',
                            prefixIcon: Icon(Icons.menu_book),
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter at least one subject' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Rate per Session',
                            prefixText: '₱ ',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => pesosToCents(v ?? '') == null ? 'Enter a valid amount' : null,
                        ),
                        if (rate != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You receive ${formatPeso(tutorPayoutCents(rate))} per session '
                                  '(${formatPeso(platformFeeCents(rate))} platform fee).',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SectionTitle('Availability'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final d in weekDays)
                              FilterChip(
                                label: Text(d),
                                selected: _days.contains(d),
                                onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTime(true),
                              icon: const Icon(Icons.schedule, size: 18),
                              label: Text(_from == null ? 'From' : _formatTime(_from)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('to', style: TextStyle(color: AppColors.muted)),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTime(false),
                              icon: const Icon(Icons.schedule, size: 18),
                              label: Text(_to == null ? 'To' : _formatTime(_to)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SectionTitle('About You'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _about,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'About / Teaching Style',
                        hintText: 'Your background and how you teach',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v ?? '').trim().length < 20 ? 'Write at least 20 characters' : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.onboarding ? 'Submit for Approval' : 'Save Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) => StreamBuilder<TutorProfile?>(
        stream: Db.instance.streamTutorProfile(uid),
        builder: (context, snap) {
          final p = snap.data;
          if (p == null) return const SizedBox.shrink();
          final (title, detail, status, icon) = p.approved
              ? ('Your profile is live', 'Clients can find you in the tutor directory.', 'approved', Icons.verified)
              : p.rejected
                  ? ('Not approved', 'Edit your profile and save to resubmit.', 'rejected', Icons.block)
                  : ('Waiting for approval', 'An admin will review your profile soon.', 'pending approval',
                      Icons.hourglass_top);
          final color = StatusChip.colorFor(status);
          return AppCard(
            color: color.withValues(alpha: 0.06),
            borderColor: color.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              IconBadge(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  Text(detail, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                ]),
              ),
            ]),
          );
        },
      );
}
