import 'package:flutter/material.dart';

import '../../models/tutor_profile.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import 'tutor_profile_view_screen.dart';

class TutorCard extends StatelessWidget {
  const TutorCard({super.key, required this.tutor});
  final TutorProfile tutor;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => TutorProfileViewScreen(tutorId: tutor.tutorId)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: tutor.name, photoUrl: tutor.photoUrl, radius: 27),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(tutor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    Pill(tutor.ratingLabel,
                        icon: Icons.star_rounded, color: AppColors.warning, iconColor: Colors.amber.shade600),
                  ]),
                  const SizedBox(height: 3),
                  Text(tutor.subjectsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill('${formatPeso(tutor.rateCents)} / session'),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tutor.availableDays.length == 7 ? 'Every day' : tutor.availableDays.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
