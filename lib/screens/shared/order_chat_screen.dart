import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/chat_message.dart';
import '../../models/order.dart';
import '../../models/report.dart';
import '../../services/cloudinary_service.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import '../client/checkout_screen.dart';

/// Order status plus the order-specific chat thread. Shared by client and
/// tutor; the admin opens it read-only when reviewing a dispute.
class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _text = TextEditingController();
  bool _uploading = false;
  bool _showDetails = true;
  late final Stream<TutoringOrder?> _orderStream = Db.instance.streamOrder(widget.orderId);
  late final Stream<List<ChatMessage>> _messageStream = Db.instance.streamMessages(widget.orderId);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(TutoringOrder order, AppUser me) async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _text.clear();
    await guard(context, () => Db.instance.sendMessage(order: order, sender: me, text: text));
  }

  Future<void> _attach(TutoringOrder order, AppUser me) async {
    setState(() => _uploading = true);
    await guard(context, () async {
      final file = await CloudinaryService.pickAndUploadFile(folder: 'orders/${order.id}');
      if (file == null) return;
      await Db.instance.sendMessage(
          order: order, sender: me, fileUrl: file.url, fileName: file.name, isImage: file.isImage);
    });
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _report(TutoringOrder order, AppUser me, {ChatMessage? message}) async {
    final reason = await promptText(
        context, message == null ? 'Report this order' : 'Report this message', 'What went wrong?');
    if (reason == null || !mounted) return;
    final otherId = me.uid == order.clientId ? order.tutorId : order.clientId;
    await guard(
      context,
      () => Db.instance.reportContent(
        reporter: me,
        type: message == null ? ReportType.order : ReportType.message,
        targetUserId: message?.senderId ?? otherId,
        targetLabel: message?.senderName ?? order.otherName(me.uid),
        orderId: order.id,
        messageText: message == null ? '' : (message.text.isNotEmpty ? message.text : message.fileName),
        reason: reason,
      ),
      success: 'Report sent to the LearnHub admin.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return StreamBuilder<TutoringOrder?>(
      stream: _orderStream,
      builder: (context, snap) {
        final order = snap.data;
        if (order == null) {
          return Scaffold(
            appBar: brandAppBar(title: 'Order'),
            body: snap.hasError
                ? const EmptyState(icon: Icons.lock_outline, message: 'You cannot view this order.')
                : const Center(child: CircularProgressIndicator()),
          );
        }
        final isParticipant = me.uid == order.clientId || me.uid == order.tutorId;
        // Hide the order card while typing so the chat keeps its space.
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        if (isParticipant && order.hasUnreadFor(me.uid)) {
          Db.instance.markRead(order.id, me.uid);
        }
        return Scaffold(
          appBar: brandAppBar(
            title: 'Order ${order.number}',
            subtitle: isParticipant ? order.otherName(me.uid) : '${order.clientName} → ${order.tutorName}',
            actions: [
              IconButton(
                tooltip: _showDetails ? 'Hide details' : 'Show details',
                icon: Icon(_showDetails ? Icons.expand_less : Icons.info_outline),
                onPressed: () => setState(() => _showDetails = !_showDetails),
              ),
              if (isParticipant)
                PopupMenuButton<String>(
                  onSelected: (_) => _report(order, me),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        Icon(Icons.flag_outlined, size: 20, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text('Report order'),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _showDetails && !keyboardOpen
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: _OrderHeader(order: order, me: me),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: StreamView<List<ChatMessage>>(
                  stream: _messageStream,
                  builder: (context, messages) {
                    if (messages.isEmpty) {
                      return const EmptyState(
                          icon: Icons.chat_bubble_outline,
                          message: 'No messages yet.\nSay hi and agree on the session details.');
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[messages.length - 1 - i];
                        return _Bubble(
                          message: m,
                          mine: m.senderId == me.uid,
                          onReport:
                              isParticipant && m.senderId != me.uid ? () => _report(order, me, message: m) : null,
                        );
                      },
                    );
                  },
                ),
              ),
              if (isParticipant) _composer(order, me),
            ],
          ),
        );
      },
    );
  }

  Widget _composer(TutoringOrder order, AppUser me) {
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide(color: Colors.transparent),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Attach file',
                style: IconButton.styleFrom(backgroundColor: AppColors.tint, foregroundColor: AppColors.primary),
                onPressed: _uploading ? null : () => _attach(order, me),
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.attach_file),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    isDense: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: pill,
                    enabledBorder: pill,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onSubmitted: (_) => _send(order, me),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                  child: InkWell(
                    onTap: () => _send(order, me),
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order summary with the actions available to the viewer at this status.
class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, required this.me});
  final TutoringOrder order;
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    final isClient = me.uid == order.clientId;
    final isTutor = me.uid == order.tutorId;
    final actions = <Widget>[];

    if (isTutor && order.status == OrderStatus.pending) {
      actions.addAll([
        Expanded(
          child: OutlinedButton(
            onPressed: () => guard(context, () => Db.instance.respondToOrder(order.id, OrderStatus.declined),
                success: 'Order declined.'),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => guard(context, () => Db.instance.respondToOrder(order.id, OrderStatus.confirmed),
                success: 'Order accepted. The client can now pay.'),
            child: const Text('Accept'),
          ),
        ),
      ]);
    } else if (isTutor && order.status == OrderStatus.paid) {
      actions.add(Expanded(
        child: FilledButton.icon(
          onPressed: () async {
            if (await confirmDialog(
                    context, 'Mark as completed?', 'Confirm that the tutoring session has taken place.') &&
                context.mounted) {
              await guard(context, () => Db.instance.completeOrder(order), success: 'Session completed.');
            }
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark as Completed'),
        ),
      ));
    } else if (isClient && order.status == OrderStatus.pending) {
      actions.add(Expanded(
        child: OutlinedButton(
          onPressed: () async {
            if (await confirmDialog(context, 'Cancel order?', 'The tutor will no longer see this request.',
                    confirm: 'Cancel order') &&
                context.mounted) {
              await guard(context, () => Db.instance.cancelOrder(order.id));
            }
          },
          child: const Text('Cancel Request'),
        ),
      ));
    } else if (isClient && order.status == OrderStatus.confirmed) {
      actions.add(Expanded(
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CheckoutScreen(order: order))),
          icon: const Icon(Icons.payment),
          label: Text('Pay ${formatPeso(order.amountCents)}'),
        ),
      ));
    } else if (isClient && order.status == OrderStatus.completed && order.rating == null) {
      actions.add(Expanded(
        child: FilledButton.icon(
          onPressed: () => _rate(context),
          icon: const Icon(Icons.star_rounded),
          label: const Text('Rate this session'),
        ),
      ));
    }

    Widget meta(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink)),
            ),
          ]),
        );

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(order.subject,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            Pill(formatPeso(order.amountCents)),
            const SizedBox(width: 6),
            StatusChip(order.status),
          ]),
          meta(Icons.event, formatDateTime(order.scheduleAt)),
          if (order.notes.isNotEmpty) meta(Icons.notes, order.notes),
          if (order.rating != null)
            meta(Icons.star_rounded, 'Rated ${'★' * order.rating!}${'☆' * (5 - order.rating!)}'),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: actions),
          ],
        ],
      ),
    );
  }

  Future<void> _rate(BuildContext context) async {
    var stars = 5;
    final picked = await showDialog<int>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          scrollable: true,
          title: Text('Rate ${order.tutorName}', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your ${order.subject} session?',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),
              StarRatingPicker(value: stars, onChanged: (v) => setState(() => stars = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () => Navigator.pop(c, stars),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await guard(context, () => Db.instance.rateOrder(order, picked), success: 'Thanks for your rating!');
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, this.onReport});
  final ChatMessage message;
  final bool mine;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : AppColors.ink;
    Widget content;
    if (message.hasFile && message.isImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(message.fileUrl,
            width: 210,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Text(message.fileName, style: TextStyle(color: fg))),
      );
    } else if (message.hasFile) {
      content = Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mine ? Colors.white.withValues(alpha: 0.2) : AppColors.tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.insert_drive_file, color: mine ? Colors.white : AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(message.fileName,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
        ),
      ]);
    } else {
      content = Text(message.text, style: TextStyle(color: fg, fontSize: 14.5, height: 1.3));
    }

    const r = Radius.circular(18);
    const tail = Radius.circular(5);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: message.hasFile ? () => openUrl(context, message.fileUrl) : null,
        onLongPress: onReport,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
          decoration: BoxDecoration(
            gradient: mine ? AppColors.gradient : null,
            color: mine ? null : Colors.white,
            border: mine ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: mine ? r : tail,
              bottomRight: mine ? tail : r,
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: mine ? 0.18 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              const SizedBox(height: 3),
              Text(
                message.createdAt == null ? 'Sending…' : timeAgo(message.createdAt),
                style: TextStyle(fontSize: 10.5, color: mine ? Colors.white70 : AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
