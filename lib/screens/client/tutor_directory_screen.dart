import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../widgets/common.dart';
import 'tutor_card.dart';
import 'tutor_filters.dart';

/// Client home: searchable tutor directory with a filter sheet
/// (subject, price, availability, rating) and quick subject chips.
class TutorDirectoryScreen extends StatefulWidget {
  const TutorDirectoryScreen({super.key, this.onOpenProfile});
  final VoidCallback? onOpenProfile;

  @override
  State<TutorDirectoryScreen> createState() => _TutorDirectoryScreenState();
}

class _TutorDirectoryScreenState extends State<TutorDirectoryScreen> {
  final _stream = Db.instance.streamPublishedTutors();
  TutorFilter _filter = const TutorFilter();

  Future<void> _openFilters(List<TutorProfile> tutors) async {
    final result = await showTutorFilterSheet(context, initial: _filter, tutors: tutors);
    if (result != null) setState(() => _filter = result);
  }

  void _toggleSubject(String s) {
    final selected = _filter.subjects.any((x) => x.toLowerCase() == s.toLowerCase());
    setState(() => _filter = _filter.copyWith(
          subjects: selected
              ? ({..._filter.subjects}..removeWhere((x) => x.toLowerCase() == s.toLowerCase()))
              : {..._filter.subjects, s},
        ));
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(
        title: 'Find a Tutor',
        subtitle: 'Hi ${me.name.split(' ').first}, what will you learn today?',
        actions: [HeaderAvatar(name: me.name, photoUrl: me.photoUrl, onTap: widget.onOpenProfile)],
      ),
      body: StreamView<List<TutorProfile>>(
        stream: _stream,
        builder: (context, tutors) {
          final results = Db.searchTutors(tutors, _filter);
          final topRated = [...tutors.where((t) => t.ratingCount > 0)]..sort((a, b) => b.rating.compareTo(a.rating));
          final subjects = subjectsOf(tutors).take(8).toList();
          return PageBody(
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Search by subject or tutor name...'),
                    onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
                  ),
                ),
                const SizedBox(width: 10),
                FilterButton(count: _filter.activeCount, onPressed: () => _openFilters(tutors)),
              ]),
              if (_filter.activeCount > 0)
                ActiveFilterChips(filter: _filter, onChanged: (f) => setState(() => _filter = f))
              else if (subjects.isNotEmpty)
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => FilterChip(
                      label: Text(subjects[i]),
                      selected: false,
                      onSelected: (_) => _toggleSubject(subjects[i]),
                    ),
                  ),
                ),
              if (tutors.isEmpty)
                const EmptyState(icon: Icons.person_search, message: 'No tutors are listed yet. Check back soon!')
              else if (!_filter.isSearching) ...[
                const SizedBox(height: 6),
                HeroCard(
                  icon: Icons.auto_awesome,
                  value: '${tutors.length} tutor${tutors.length == 1 ? '' : 's'}',
                  label: 'Ready to help you learn',
                  footer: 'Tap the filter button to narrow by price or schedule',
                ),
                if (topRated.isNotEmpty) ...[
                  const SectionTitle('Featured tutors'),
                  for (final t in topRated.take(3)) TutorCard(tutor: t),
                ],
                ResultsHeader(
                  count: tutors.length,
                  sort: _filter.sort,
                  onSort: (s) => setState(() => _filter = _filter.copyWith(sort: s)),
                ),
                for (final t in tutors) TutorCard(tutor: t),
              ] else ...[
                ResultsHeader(
                  count: results.length,
                  sort: _filter.sort,
                  onSort: (s) => setState(() => _filter = _filter.copyWith(sort: s)),
                ),
                if (results.isEmpty)
                  const EmptyState(
                      icon: Icons.search_off, message: 'No tutors match.\nTry removing a filter or widening the price.'),
                for (final t in results) TutorCard(tutor: t),
              ],
            ],
          );
        },
      ),
    );
  }
}
