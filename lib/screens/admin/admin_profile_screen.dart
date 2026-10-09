import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cloudinary_service.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../widgets/common.dart';
import '../shared/account_settings_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<Session>().currentUser.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _update(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    await guard(context, action, success: success);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(title: 'Admin Profile'),
      body: PageBody(
        children: [
          ProfileHeader(
            name: me.name,
            photoUrl: me.photoUrl,
            caption: 'System Admin · ${me.email}',
            onEditPhoto: _busy
                ? null
                : () => _update(() async {
                      final f = await CloudinaryService.pickAndUploadImage(folder: 'avatars');
                      if (f != null) await Db.instance.updateClientProfile(me.uid, {'photoUrl': f.url});
                    }),
          ),
          const SectionTitle('Account information'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                enabled: false,
                controller: TextEditingController(text: me.email),
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _name.text.trim().isEmpty
                    ? null
                    : () => _update(() => Db.instance.updateClientProfile(me.uid, {'name': _name.text.trim()}),
                        success: 'Profile saved.'),
                child: const Text('Save Changes'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const LogOutButton(),
        ],
      ),
    );
  }
}
