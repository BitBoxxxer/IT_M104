import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/_system/account_model.dart';
import '../../services/_account/account_manager_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final Account account;

  const AccountSettingsScreen({super.key, required this.account});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final AccountManagerService _accountManager = AccountManagerService();
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  Future<void> _renameAccount() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _account.fullName);
        return AlertDialog(
          title: Text('Переименовать аккаунт'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Имя',
              hintText: 'Введите новое имя',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != _account.fullName) {
      final updatedAccount = _account.copyWith(fullName: newName);
      await _accountManager.updateAccount(updatedAccount);
      setState(() {
        _account = updatedAccount;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Имя аккаунта изменено'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки аккаунта'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _account.photoPath.isNotEmpty
                  ? NetworkImage(_account.photoPath)
                  : null,
              child: _account.photoPath.isEmpty
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(_account.fullName),
            subtitle: Text(_account.username),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: _renameAccount,
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('Группа'),
            subtitle: Text(_account.groupName),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Последний вход'),
            subtitle: Text('${_account.lastLogin.day}.${_account.lastLogin.month}.${_account.lastLogin.year} '
                '${_account.lastLogin.hour}:${_account.lastLogin.minute}'),
          ),
          ListTile(
            leading: Icon(Icons.tag),
            title: Text('ID аккаунта'),
            subtitle: Text(_account.id),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: _account.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ID скопирован')),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.sync, color: Colors.blue),
            title: Text('Синхронизировать данные'),
            onTap: () {
              // TODO: Реализовать синхронизацию для этого аккаунта
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Синхронизация запущена')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Удалить аккаунт', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Удалить аккаунт?'),
                  content: Text('Вы уверены, что хотите удалить аккаунт ${_account.fullName}? '
                      'Это действие нельзя отменить.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Удалить', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await _accountManager.removeAccount(_account.id);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}