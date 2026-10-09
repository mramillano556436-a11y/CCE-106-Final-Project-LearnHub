import 'package:flutter/material.dart';

import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';

/// Every subject offered by [tutors], most common first.
List<String> subjectsOf(List<TutorProfile> tutors) {
  final counts = <String, int>{};
  final display = <String, String>{};
  for (final t in tutors) {
    for (final s in t.subjects) {
      final key = s.trim().toLowerCase();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      display.putIfAbsent(key, () => s.trim());
    }
  }
  final keys = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return [for (final k in keys) display[k]!];
}

/// Upper end of the price slider: the highest rate rounded up to ₱100 (at least ₱500).
int priceCeilingCents(List<TutorProfile> tutors) {
  final highest = tutors.fold(0, (m, t) => t.rateCents > m ? t.rateCents : m);
  final rounded = ((highest + 9999) ~/ 10000) * 10000;
  return rounded < 50000 ? 50000 : rounded;
}

IconData _slotIcon(TimeSlot s) => switch (s) {
      TimeSlot.morning => Icons.wb_twilight,
      TimeSlot.afternoon => Icons.wb_sunny_outlined,
      TimeSlot.evening => Icons.nights_stay_outlined,
    };

String _slotHours(TimeSlot s) => switch (s) {
      TimeSlot.morning => '6 AM – 12 PM',
      TimeSlot.afternoon => '12 – 5 PM',
      TimeSlot.evening => '5 – 10 PM',
    };

/// Subject, price, availability, and rating controls.
class TutorFilterPanel extends StatelessWidget {
  const TutorFilterPanel({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.subjects,
    required this.ceilingCents,
  });

  final TutorFilter filter;
  final ValueChanged<TutorFilter> onChanged;
  final List<String> subjects;
  final int ceilingCents;

  Widget _heading(String title, {String? value}) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const Spacer(),
          if (value != null)
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
      );

  Set<T> _toggle<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final ceiling = ceilingCents / 100;
    final low = ((filter.minRateCents ?? 0) / 100).clamp(0, ceiling).toDouble();
    final high = ((filter.maxRateCents ?? ceilingCents) / 100).clamp(low, ceiling).toDouble();
    final priceLabel = filter.hasPrice
        ? '${formatPeso((low * 100).round())} – ${formatPeso((high * 100).round())}${high >= ceiling ? '+' : ''}'
        : 'Any price';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Subject', value: filter.subjects.isEmpty ? 'Any' : '${filter.subjects.length} selected'),
        if (subjects.isEmpty)
          const Text('No subjects listed yet.', style: TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                FilterChip(
                  label: Text(s),
                  selected: filter.subjects.any((x) => x.toLowerCase() == s.toLowerCase()),
                  onSelected: (_) {
                    final existing = filter.subjects.where((x) => x.toLowerCase() == s.toLowerCase());
                    onChanged(filter.copyWith(
                      subjects: existing.isEmpty
                          ? {...filter.subjects, s}
                          : ({...filter.subjects}..removeAll(existing.toList())),
                    ));
                  },
                ),
            ],
          ),
        _heading('Price per session', value: priceLabel),
        RangeSlider(
          values: RangeValues(low, high),
          max: ceiling,
          divisions: (ceiling / 50).round().clamp(1, 200),
          labels: RangeLabels(formatPeso((low * 100).round()), formatPeso((high * 100).round())),
          onChanged: (v) => onChanged(filter.copyWith(
            minRateCents: () => v.start <= 0 ? null : (v.start * 100).round(),
            maxRateCents: () => v.end >= ceiling ? null : (v.end * 100).round(),
          )),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            Text(formatPeso(0), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const Spacer(),
            Text('${formatPeso(ceilingCents)}+', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        _heading('Available on', value: filter.days.isEmpty ? 'Any day' : null),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: [
            for (final d in weekDays)
              FilterChip(
                label: Text(d),
                selected: filter.days.contains(d),
                onSelected: (_) => onChanged(filter.copyWith(days: _toggle(filter.days, d))),
              ),
          ],
        ),
        _heading('Time of day', value: filter.timeSlot == null ? 'Any time' : _slotHours(filter.timeSlot!)),
        Row(children: [
          for (final s in TimeSlot.values) ...[
            Expanded(child: _SlotCard(
              slot: s,
              selected: filter.timeSlot == s,
              onTap: () => onChanged(filter.copyWith(timeSlot: () => filter.timeSlot == s ? null : s)),
            )),
            if (s != TimeSlot.values.last) const SizedBox(width: 8),
          ],
        ]),
        _heading('Minimum rating'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in const [0.0, 3.0, 4.0, 4.5])
              ChoiceChip(
                avatar: r == 0 ? null : Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                label: Text(r == 0 ? 'Any' : '${r == r.roundToDouble() ? r.toInt() : r}+'),
                selected: filter.minRating == r,
                onSelected: (_) => onChanged(filter.copyWith(minRating: r)),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.selected, required this.onTap});
  final TimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.tint : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Icon(_slotIcon(slot), color: selected ? AppColors.primary : AppColors.muted),
              const SizedBox(height: 4),
              Text(slot.label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.ink)),
            ]),
          ),
        ),
      );
}

/// Opens the filter sheet. Returns the new filter, or null if dismissed.
Future<TutorFilter?> showTutorFilterSheet(
  BuildContext context, {
  required TutorFilter initial,
  required List<TutorProfile> tutors,
}) =>
    showModalBottomSheet<TutorFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: initial, tutors: tutors),
    );

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.tutors});
  final TutorFilter initial;
  final List<TutorProfile> tutors;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TutorFilter _filter = widget.initial;
  late final _subjects = subjectsOf(widget.tutors);
  late final _ceiling = priceCeilingCents(widget.tutors);

  @override
  Widget build(BuildContext context) {
    final count = Db.searchTutors(widget.tutors, _filter).length;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(children: [
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const Spacer(),
              TextButton(
                onPressed: _filter.activeCount == 0 ? null : () => setState(() => _filter = _filter.cleared()),
                child: const Text('Reset all'),
              ),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TutorFilterPanel(
                filter: _filter,
                subjects: _subjects,
                ceilingCents: _ceiling,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _filter),
                  child: Text(count == 0 ? 'No tutors match' : 'Show $count tutor${count == 1 ? '' : 's'}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square "tune" button with a badge showing how many filters are on.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.primary,
        offset: const Offset(-4, 4),
        child: Material(
          color: count > 0 ? AppColors.primary : AppColors.tint,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.tune_rounded, color: count > 0 ? Colors.white : AppColors.primary),
            ),
          ),
        ),
      );
}

/// Removable chips summarising the filters currently applied.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({super.key, required this.filter, required this.onChanged});
  final TutorFilter filter;
  final ValueChanged<TutorFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final s in filter.subjects)
        _chip(s, () => onChanged(filter.copyWith(subjects: {...filter.subjects}..remove(s)))),
      if (filter.hasPrice)
        _chip(
          '${filter.minRateCents == null ? 'Up to' : formatPeso(filter.minRateCents!)}'
          '${filter.minRateCents != null && filter.maxRateCents != null ? ' – ' : ' '}'
          '${filter.maxRateCents == null ? 'and up' : formatPeso(filter.maxRateCents!)}',
          () => onChanged(filter.copyWith(minRateCents: () => null, maxRateCents: () => null)),
        ),
      if (filter.days.isNotEmpty)
        _chip(weekDays.where(filter.days.contains).join(', '), () => onChanged(filter.copyWith(days: const {}))),
      if (filter.timeSlot != null)
        _chip(filter.timeSlot!.label, () => onChanged(filter.copyWith(timeSlot: () => null))),
      if (filter.minRating > 0)
        _chip('${filter.minRating.toStringAsFixed(filter.minRating % 1 == 0 ? 0 : 1)}+ stars',
            () => onChanged(filter.copyWith(minRating: 0))),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 10),
        children: [
          for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c),
          TextButton(onPressed: () => onChanged(filter.cleared()), child: const Text('Clear all')),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDeleted) => InputChip(
        label: Text(label),
        selected: true,
        onPressed: onDeleted,
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        visualDensity: VisualDensity.compact,
      );
}

/// "Sort: …" dropdown for result lists.
class SortButton extends StatelessWidget {
  const SortButton({super.key, required this.sort, required this.onChanged});
  final TutorSort sort;
  final ValueChanged<TutorSort> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<TutorSort>(
        initialValue: sort,
        onSelected: onChanged,
        itemBuilder: (_) => [
          for (final s in TutorSort.values)
            PopupMenuItem(
              value: s,
              child: Row(children: [
                Icon(s == sort ? Icons.check_rounded : null, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(s.label),
              ]),
            ),
        ],
        child: Pill(sort.label, icon: Icons.swap_vert_rounded),
      );
}

/// Results heading with a count and the sort dropdown.
class ResultsHeader extends StatelessWidget {
  const ResultsHeader({super.key, required this.count, required this.sort, required this.onSort});
  final int count;
  final TutorSort sort;
  final ValueChanged<TutorSort> onSort;

  @override
  Widget build(BuildContext context) => SectionTitle(
        '$count tutor${count == 1 ? '' : 's'} found',
        trailing: SortButton(sort: sort, onChanged: onSort),
      );
}
