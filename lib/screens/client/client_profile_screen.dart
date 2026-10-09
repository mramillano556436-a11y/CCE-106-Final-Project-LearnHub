import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cloudinary_service.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../widgets/common.dart';
import '../shared/account_settings_screen.dart';

/// Client's personal information: name, phone, and profile photo.
class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<Session>().currentUser;
    _name.text = me.name;
    _phone.text = me.phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final uid = context.read<Session>().currentUser.uid;
    setState(() => _busy = true);
    await guard(context, () async {
      final file = await CloudinaryService.pickAndUploadImage(folder: 'avatars');
      if (file != null) await Db.instance.updateClientProfile(uid, {'photoUrl': file.url});
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final me = context.read<Session>().currentUser;
    final changes = <String, Object?>{
      if (_name.text.trim() != me.name) 'name': _name.text.trim(),
      if (_phone.text.trim() != me.phone) 'phone': _phone.text.trim(),
    };
    if (changes['name'] == '') {
      showSnack(context, 'Name cannot be empty.');
      return;
    }
    setState(() => _busy = true);
    await guard(context, () => Db.instance.updateClientProfile(me.uid, changes),
        success: changes.isEmpty ? 'Nothing to update.' : 'Profile saved.');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            tooltip: 'Account settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AccountSettingsScreen())),
          ),
        ],
      ),
      body: PageBody(
        children: [
          ProfileHeader(
            name: me.name,
            photoUrl: me.photoUrl,
            caption: 'Client since ${me.createdAt?.year ?? DateTime.now().year}',
            onEditPhoto: _busy ? null : _changePhoto,
          ),
          const SectionTitle('Personal information'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                enabled: false,
                controller: TextEditingController(text: me.email),
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _save, child: const Text('Save Changes')),
            ]),
          ),
          const SizedBox(height: 12),
          const LogOutButton(),
        ],
      ),
    );
  }
}
