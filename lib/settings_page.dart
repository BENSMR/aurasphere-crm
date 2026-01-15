import 'package:flutter/material.dart';
import 'theme/modern_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: ModernTheme.headline3),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(ModernTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              const Text('Account', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              _buildSettingsCard(
                title: 'Email Address',
                subtitle: 'user@example.com',
                onTap: () => _showDialog('Change Email'),
              ),
              _buildSettingsCard(
                title: 'Password',
                subtitle: 'Last changed 3 months ago',
                onTap: () => _showDialog('Change Password'),
              ),
              const SizedBox(height: ModernTheme.spacingXL),

              // White-Label Settings
              const Text('Branding', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              _buildSettingsCard(
                title: 'Organization Name',
                subtitle: 'AuraSphere Demo',
                onTap: () => _showDialog('Update Organization Name'),
              ),
              _buildSettingsCard(
                title: 'Primary Color',
                subtitle: '#007BFF (Electric Blue)',
                onTap: () => _showColorPicker(),
              ),
              _buildSettingsCard(
                title: 'Custom Logo',
                subtitle: 'Upload your company logo',
                onTap: () => _showDialog('Upload Logo'),
              ),
              const SizedBox(height: ModernTheme.spacingXL),

              // Backup Settings
              const Text('Backups & Data', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              _buildBackupCard(),
              const SizedBox(height: ModernTheme.spacingXL),

              // Preferences
              const Text('Preferences', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              _buildToggleCard(
                title: 'Notifications',
                subtitle: 'Receive email and push notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildToggleCard(
                title: 'Dark Mode',
                subtitle: 'Use dark theme for the app',
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                },
              ),
              _buildDropdownCard(
                title: 'Language',
                subtitle: _language,
                options: ['English', 'French', 'Spanish', 'German'],
                onChanged: (value) {
                  setState(() => _language = value);
                },
              ),
              const SizedBox(height: ModernTheme.spacingXL),

              // Security
              const Text('Security', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              _buildSettingsCard(
                title: 'Two-Factor Authentication',
                subtitle: 'Not enabled',
                onTap: () => _showDialog('Enable 2FA'),
              ),
              _buildSettingsCard(
                title: 'Login Attempts',
                subtitle: '0 failed attempts in last 30 days',
                onTap: () {},
              ),
              const SizedBox(height: ModernTheme.spacingXL),

              // FinOps & Business Section
              const Text('Business Tools', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(ModernTheme.spacingM),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                  color: Colors.blue.shade50,
                ),
                child: ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.blueAccent),
                  title: const Text('CloudGuard FinOps', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Monitor cloud costs, detect waste & optimize spending'),
                  trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
                  onTap: () => Navigator.pushNamed(context, '/cloudguard'),
                ),
              ),
              const SizedBox(height: ModernTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(ModernTheme.spacingM),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                  color: Colors.green.shade50,
                ),
                child: ListTile(
                  leading: const Icon(Icons.handshake, color: Colors.green),
                  title: const Text('Partner Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage reseller program, commissions & training'),
                  trailing: const Icon(Icons.arrow_forward, color: Colors.green),
                  onTap: () => Navigator.pushNamed(context, '/partner-portal'),
                ),
              ),
              const SizedBox(height: ModernTheme.spacingXL),

              // Danger Zone
              const Text('Danger Zone', style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(ModernTheme.spacingM),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                  color: Colors.red.shade50,
                ),
                child: ListTile(
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Permanently delete your account and all data'),
                  trailing: const Icon(Icons.delete, color: Colors.red),
                  onTap: () => _showDeleteConfirmation(),
                ),
              ),
              const SizedBox(height: ModernTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.spacingM,
          vertical: ModernTheme.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          side: const BorderSide(color: ModernTheme.lightBorder),
        ),
        title: Text(title, style: ModernTheme.bodyLarge),
        subtitle: Text(subtitle, style: ModernTheme.bodyMedium),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.spacingM,
          vertical: ModernTheme.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          side: const BorderSide(color: ModernTheme.lightBorder),
        ),
        title: Text(title, style: ModernTheme.bodyLarge),
        subtitle: Text(subtitle, style: ModernTheme.bodyMedium),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF007BFF),
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String title,
    required String subtitle,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
      padding: const EdgeInsets.symmetric(
        horizontal: ModernTheme.spacingM,
        vertical: ModernTheme.spacingS,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        border: Border.all(color: ModernTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ModernTheme.bodyLarge),
          const SizedBox(height: ModernTheme.spacingS),
          DropdownButton<String>(
            value: subtitle,
            isExpanded: true,
            underline: const SizedBox(),
            items: options
                .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                })
                .toList(),
            onChanged: (String? value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        border: Border.all(color: ModernTheme.lightBorder),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Automated Backups', style: ModernTheme.bodyLarge),
          const SizedBox(height: ModernTheme.spacingS),
          const Text(
            'Backups are created automatically daily. Last backup: 2 hours ago',
            style: ModernTheme.bodyMedium,
          ),
          const SizedBox(height: ModernTheme.spacingM),
          ElevatedButton.icon(
            icon: const Icon(Icons.backup),
            label: const Text('Backup Now'),
            onPressed: () => _showDialog('Backup created successfully!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BFF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildColorOption('Electric Blue', 0xFF007BFF),
            _buildColorOption('Dark Blue', 0xFF0056B3),
            _buildColorOption('Green', 0xFF28A745),
            _buildColorOption('Red', 0xFFDC3545),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String name, int color) {
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Color(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(name),
      onTap: () {
        Navigator.pop(context);
        _showDialog('Color changed to $name');
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDialog('Account deletion initiated');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
