import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/format.dart';

// ------------------------------------------------------------------ headers

/// Blue gradient app bar with rounded bottom corners, used on every screen.
PreferredSizeWidget brandAppBar({
  required String title,
  String? subtitle,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) =>
    AppBar(
      backgroundColor: Colors.transparent,
      toolbarHeight: subtitle == null ? 60 : 68,
      title: subtitle == null
          ? Text(title)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.82))),
              ],
            ),
      actions: [...?actions, const SizedBox(width: 4)],
      bottom: bottom,
      flexibleSpace: const _HeaderBackground(),
    );

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  static const _radius = BorderRadius.vertical(bottom: Radius.circular(26));

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: const ClipRRect(
          borderRadius: _radius,
          child: Stack(children: [
            Positioned(right: -36, top: -52, child: Orb(size: 150, opacity: 0.09)),
            Positioned(right: 70, bottom: -60, child: Orb(size: 110, opacity: 0.06)),
          ]),
        ),
      );
}

/// Segmented, pill-style tabs that sit inside the gradient header.
PreferredSizeWidget brandTabBar(List<String> labels) => PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            tabs: [for (final l in labels) Tab(text: l, height: 36)],
            indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white,
            labelStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w500, fontSize: 13.5),
            splashBorderRadius: BorderRadius.circular(10),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
      ),
    );

/// Translucent white circle used as a decorative accent on blue surfaces.
class Orb extends StatelessWidget {
  const Orb({super.key, required this.size, this.opacity = 0.08});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );
}

// --------------------------------------------------------------- containers

/// The standard white container: rounded, thin blue-grey border, soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor ?? AppColors.border, width: borderColor == null ? 1 : 1.4),
    );
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: color ?? Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Gradient summary card for headline numbers (earnings, totals).
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.value, required this.label, this.icon, this.footer, this.onTap});
  final String value;
  final String label;
  final IconData? icon;
  final String? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(children: [
            const Positioned(right: -26, top: -34, child: Orb(size: 124, opacity: 0.1)),
            const Positioned(right: 56, bottom: -44, child: Orb(size: 92, opacity: 0.07)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                if (icon != null) ...[
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(value,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      if (footer != null) ...[
                        const SizedBox(height: 4),
                        Text(footer!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.8)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Small rounded square holding an icon on a light-blue tint.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 40, this.color = AppColors.primary});
  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color == AppColors.primary ? AppColors.tint : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}

/// Small tinted label, e.g. a price or rating.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.color = AppColors.primary, this.iconColor});
  final String text;
  final IconData? icon;
  final Color color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color == AppColors.primary ? AppColors.tint : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// Icon + label + value row used on detail pages.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, this.value, this.child});
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  child ??
                      Text(value ?? '—',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
            ),
          ],
        ),
      );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photoUrl = '', this.radius = 22, this.ring = false});

  final String name;
  final String photoUrl;
  final double radius;

  /// Adds a white ring and shadow, for profile headers.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tint,
      foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
      child: Text(initialOf(name),
          style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: AppColors.primary)),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16)],
      ),
      child: avatar,
    );
  }
}

/// Avatar with a small camera button for changing the photo.
class EditableAvatar extends StatelessWidget {
  const EditableAvatar({super.key, required this.name, required this.photoUrl, this.onEdit});
  final String name;
  final String photoUrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Stack(children: [
        UserAvatar(name: name, photoUrl: photoUrl, radius: 46, ring: true),
        Positioned(
          right: 2,
          bottom: 2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ]);
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  static Color colorFor(String status) => switch (status) {
        OrderStatus.pending || 'pending approval' || 'new' => AppColors.warning,
        OrderStatus.confirmed || 'approved' || 'active' => AppColors.primary,
        OrderStatus.paid => AppColors.teal,
        OrderStatus.completed || 'resolved' => AppColors.success,
        'incomplete' => AppColors.muted,
        _ => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          status[0].toUpperCase() + status.substring(1),
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label, required this.icon, this.onTap});
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              IconBadge(icon, size: 36),
              const Spacer(),
              if (onTap != null) const Icon(Icons.arrow_outward, size: 16, color: AppColors.muted),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      );
}

/// Two-column grid of [StatCard]s.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 124,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: children,
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ],
      ),
    );
    // Scrolls instead of overflowing when space is tight (e.g. keyboard open).
    return LayoutBuilder(
      builder: (context, constraints) => !constraints.hasBoundedHeight
          ? Center(child: content)
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight, minWidth: constraints.maxWidth),
                child: Center(child: content),
              ),
            ),
    );
  }
}

/// Section heading with a short blue accent bar.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          ?trailing,
        ]),
      );
}

/// Centers page content and limits its width on large screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24)});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: padding, children: children),
        ),
      );
}

/// StreamBuilder with standard loading and error states.
class StreamView<T> extends StatelessWidget {
  const StreamView({super.key, required this.stream, required this.builder});
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(icon: Icons.error_outline, message: AuthService.describeError(snap.error!));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return builder(context, snap.data as T);
        },
      );
}

/// White bottom navigation with a soft shadow, shared by all role shells.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
}

// ------------------------------------------------------------------ helpers

void showSnack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

/// Runs [action], showing a snackbar with a friendly error if it fails.
Future<bool> guard(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, AuthService.describeError(e));
    return false;
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String confirm = 'Confirm'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Asks for free text (e.g. a report reason). Returns null if cancelled.
Future<String?> promptText(BuildContext context, String title, String hint) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      // Scrolls instead of overflowing when the keyboard leaves little room.
      scrollable: true,
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () {
            if (controller.text.trim().isNotEmpty) Navigator.pop(c, controller.text.trim());
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}

Future<void> openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showSnack(context, 'Could not open the file.');
}

/// A card summarising an order, used across client, tutor, and admin screens.
/// [footer] (e.g. Accept/Decline buttons) is shown inside the same card.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.viewerId, this.onTap, this.trailing, this.footer});
  final TutoringOrder order;
  final String viewerId;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isParticipant = viewerId == order.clientId || viewerId == order.tutorId;
    final name = isParticipant ? order.otherName(viewerId) : '${order.clientName} → ${order.tutorName}';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(children: [
            UserAvatar(name: name, photoUrl: isParticipant ? order.otherPhoto(viewerId) : ''),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('${order.subject} · ${order.number}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
            trailing ?? StatusChip(order.status),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.event, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(formatDateTime(order.scheduleAt),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
              ),
            ]),
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}

/// Centered avatar, name, and caption at the top of profile pages.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.name, required this.photoUrl, required this.caption, this.onEditPhoto});
  final String name;
  final String photoUrl;
  final String caption;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        child: Center(
          child: Column(children: [
            EditableAvatar(name: name, photoUrl: photoUrl, onEdit: onEditPhoto),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Pill(caption),
          ]),
        ),
      );
}

/// Signed-in user's avatar for the header of home screens.
class HeaderAvatar extends StatelessWidget {
  const HeaderAvatar({super.key, required this.name, required this.photoUrl, this.onTap});
  final String name;
  final String photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
            ),
            child: UserAvatar(name: name, photoUrl: photoUrl, radius: 17),
          ),
        ),
      );
}

/// Tappable 1–5 star picker that shrinks to fit any width.
class StarRatingPicker extends StatelessWidget {
  const StarRatingPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const labels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final size = (constraints.maxWidth / 5 - 6).clamp(20.0, 40.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Flexible(
                    child: InkResponse(
                      onTap: () => onChanged(i),
                      radius: size * 0.7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                        child: Icon(
                          i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber.shade600,
                          size: size,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Text(labels[value - 1],
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
        ],
      );
}
