import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/company_profile_service.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final supabase = Supabase.instance.client;
  final profileService = CompanyProfileService();

  late TextEditingController companyNameCtrl;
  late TextEditingController registrationCtrl;
  late TextEditingController taxNumberCtrl;
  late TextEditingController businessTypeCtrl;
  late TextEditingController industryCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController zipCtrl;
  late TextEditingController countryCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController websiteCtrl;

  Map<String, dynamic> profile = {};
  bool loading = true;
  bool isSaving = false;
  String? orgId;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initialize();
  }

  void _initControllers() {
    companyNameCtrl = TextEditingController();
    registrationCtrl = TextEditingController();
    taxNumberCtrl = TextEditingController();
    businessTypeCtrl = TextEditingController();
    industryCtrl = TextEditingController();
    addressCtrl = TextEditingController();
    cityCtrl = TextEditingController();
    stateCtrl = TextEditingController();
    zipCtrl = TextEditingController();
    countryCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    websiteCtrl = TextEditingController();
  }

  Future<void> _initialize() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Get org ID
      final orgMember = await supabase
          .from('org_members')
          .select('org_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (orgMember != null) {
        orgId = orgMember['org_id'];
      }

      // Check if user is owner
      final org = await supabase
          .from('organizations')
          .select('owner_id')
          .eq('id', orgId ?? '')
          .maybeSingle();

      if (org?['owner_id'] != userId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only company owner can edit profile')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Load profile
      if (orgId != null) {
        profile = await profileService.getCompanyProfile(orgId!);
        _populateControllers();
      }

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      print('❌ Error initializing: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  void _populateControllers() {
    companyNameCtrl.text = profile['company_name'] ?? '';
    registrationCtrl.text = profile['company_registration'] ?? '';
    taxNumberCtrl.text = profile['tax_number'] ?? '';
    businessTypeCtrl.text = profile['business_type'] ?? '';
    industryCtrl.text = profile['industry'] ?? '';
    addressCtrl.text = profile['address'] ?? '';
    cityCtrl.text = profile['city'] ?? '';
    stateCtrl.text = profile['state'] ?? '';
    zipCtrl.text = profile['zip_code'] ?? '';
    countryCtrl.text = profile['country'] ?? '';
    phoneCtrl.text = profile['phone_number'] ?? '';
    emailCtrl.text = profile['email'] ?? '';
    websiteCtrl.text = profile['website'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!profileService.validateCompanyDetails(
      companyName: companyNameCtrl.text,
      taxNumber: taxNumberCtrl.text,
      email: emailCtrl.text,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (orgId == null) return;

    setState(() => isSaving = true);
    try {
      final result = await profileService.updateCompanyProfile(
        orgId: orgId!,
        companyName: companyNameCtrl.text,
        companyRegistration: registrationCtrl.text,
        taxNumber: taxNumberCtrl.text,
        businessType: businessTypeCtrl.text,
        industry: industryCtrl.text,
        address: addressCtrl.text,
        city: cityCtrl.text,
        state: stateCtrl.text,
        zipCode: zipCtrl.text,
        country: countryCtrl.text,
        phoneNumber: phoneCtrl.text,
        email: emailCtrl.text,
        website: websiteCtrl.text,
        logoUrl: profile['logo_url'] ?? '',
        primaryColor: profile['primary_color'] ?? '#007BFF',
        secondaryColor: profile['secondary_color'] ?? '#6C757D',
        accentColor: profile['accent_color'] ?? '#28A745',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    companyNameCtrl.dispose();
    registrationCtrl.dispose();
    taxNumberCtrl.dispose();
    businessTypeCtrl.dispose();
    industryCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    zipCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Logo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (profile['logo_url'] != null)
                      Image.network(
                        profile['logo_url'],
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logo upload coming soon')),
                        );
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Logo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Company Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: companyNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Company Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: registrationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Company Registration *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: taxNumberCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tax Number *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: businessTypeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Business Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'e.g., Freelancer, Small Business, Enterprise',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: industryCtrl,
                      decoration: InputDecoration(
                        labelText: 'Industry',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'e.g., Construction, Technology, Services',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stateCtrl,
                            decoration: InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: zipCtrl,
                            decoration: InputDecoration(
                              labelText: 'Zip Code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: countryCtrl,
                            decoration: InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: websiteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'https://example.com',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : _saveProfile,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Company Profile'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
