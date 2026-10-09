import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import '../shared/order_chat_screen.dart';

/// Booking form: subject, preferred schedule, and session notes.
class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key, required this.tutor});
  final TutorProfile tutor;

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String? _subject;
  DateTime? _schedule;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.tutor.subjects.length == 1) _subject = widget.tutor.subjects.first;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: _schedule ?? now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _schedule != null ? TimeOfDay.fromDateTime(_schedule!) : const TimeOfDay(hour: 15, minute: 0),
    );
    if (time == null) return;
    setState(() => _schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schedule == null) {
      showSnack(context, 'Choose a preferred schedule.');
      return;
    }
    if (!widget.tutor.availableDays.contains(weekDays[_schedule!.weekday - 1]) &&
        !await confirmDialog(context, 'Outside availability',
            '${widget.tutor.name} is usually available ${widget.tutor.availabilityLabel}. Send the request anyway?',
            confirm: 'Send anyway')) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    final client = context.read<Session>().currentUser;
    String? orderId;
    final ok = await guard(context, () async {
      orderId = await Db.instance.placeOrder(
        client: client,
        tutor: widget.tutor,
        subject: _subject!,
        scheduleAt: _schedule!,
        notes: _notes.text.trim(),
      );
    }, success: 'Request sent! Waiting for ${widget.tutor.name} to confirm.');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: orderId!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutor = widget.tutor;
    return Scaffold(
      appBar: brandAppBar(title: 'Place an Order', subtitle: 'with ${tutor.name}'),
      body: Form(
        key: _formKey,
        child: PageBody(
          children: [
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                UserAvatar(name: tutor.name, photoUrl: tutor.photoUrl, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tutor.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                    Text(tutor.availabilityLabel, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ]),
                ),
                Pill(formatPeso(tutor.rateCents)),
              ]),
            ),
            const SectionTitle('Session details'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _subject,
                    decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.menu_book)),
                    items: [for (final s in tutor.subjects) DropdownMenuItem(value: s, child: Text(s))],
                    onChanged: (v) => setState(() => _subject = v),
                    validator: (v) => v == null ? 'Choose a subject' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickSchedule,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Preferred Schedule',
                        prefixIcon: Icon(Icons.event),
                        suffixIcon: Icon(Icons.chevron_right),
                      ),
                      child: Text(
                        _schedule == null ? 'Tap to choose date and time' : formatDateTime(_schedule),
                        style: TextStyle(color: _schedule == null ? AppColors.muted : AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Session Notes',
                      hintText: 'Topics you need help with, your level, etc.',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              color: AppColors.tint,
              borderColor: AppColors.primary.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Session price', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    SizedBox(height: 2),
                    Text('You pay after the tutor accepts.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ]),
                ),
                Text(formatPeso(tutor.rateCents),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
