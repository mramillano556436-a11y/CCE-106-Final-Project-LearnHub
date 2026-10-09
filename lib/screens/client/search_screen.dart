import 'package:flutter/material.dart';

import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'tutor_card.dart';
import 'tutor_filters.dart';

/// Search & Filter Results page: every filter shown inline, results below.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _stream = Db.instance.streamPublishedTutors();
  final _query = TextEditingController();
  TutorFilter _filter = const TutorFilter();
  bool _showFilters = true;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _query.clear();
        _filter = const TutorFilter();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(
        title: 'Search Tutors',
        subtitle: 'Filter by subject, price, and availability',
        actions: [
          TextButton(onPressed: _reset, child: const Text('Reset', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: StreamView<List<TutorProfile>>(
        stream: _stream,
        builder: (context, tutors) {
          final results = Db.searchTutors(tutors, _filter);
          return PageBody(
            children: [
              TextField(
                controller: _query,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Subject or tutor name',
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _query.clear();
                            _filter = _filter.copyWith(query: '');
                          }),
                        ),
                ),
                onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
              ),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          const IconBadge(Icons.tune_rounded, size: 34),
                          const SizedBox(width: 10),
                          const Text('Filters',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          const SizedBox(width: 8),
                          if (_filter.activeCount > 0) Pill('${_filter.activeCount} on'),
                          const Spacer(),
                          Icon(_showFilters ? Icons.expand_less : Icons.expand_more, color: AppColors.muted),
                        ]),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: _showFilters
                          ? TutorFilterPanel(
                              filter: _filter,
                              subjects: subjectsOf(tutors),
                              ceilingCents: priceCeilingCents(tutors),
                              onChanged: (f) => setState(() => _filter = f),
                            )
                          : ActiveFilterChips(filter: _filter, onChanged: (f) => setState(() => _filter = f)),
                    ),
                  ],
                ),
              ),
              ResultsHeader(
                count: results.length,
                sort: _filter.sort,
                onSort: (s) => setState(() => _filter = _filter.copyWith(sort: s)),
              ),
              if (results.isEmpty)
                const EmptyState(
                    icon: Icons.search_off, message: 'No tutors match these filters.\nTry removing one of them.'),
              for (final t in results) TutorCard(tutor: t),
            ],
          );
        },
      ),
    );
  }
}
