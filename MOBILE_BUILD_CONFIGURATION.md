# 📱 Mobile Build Configuration Guide

## iOS Build Configuration

### Step 1: Update Version Numbers

**File**: `ios/Runner/Info.plist`
```xml
<dict>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <!-- Other keys... -->
</dict>
```

**Or in Xcode**:
```
1. Open ios/Runner.xcworkspace (NOT .xcodeproj)
2. Select Runner in Project Navigator
3. General tab:
   - Version: 1.0.0
   - Build: 1
```

### Step 2: Configure App Icons

**Replace these files**:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
- Icon-App-20x20@1x.png (20x20)
- Icon-App-20x20@2x.png (40x40)
- Icon-App-20x20@3x.png (60x60)
- Icon-App-29x29@1x.png (29x29)
- Icon-App-29x29@2x.png (58x58)
- Icon-App-29x29@3x.png (87x87)
- Icon-App-40x40@1x.png (40x40)
- Icon-App-40x40@2x.png (80x80)
- Icon-App-40x40@3x.png (120x120)
- Icon-App-60x60@2x.png (120x120)
- Icon-App-60x60@3x.png (180x180)
- Icon-App-76x76@1x.png (76x76)
- Icon-App-76x76@2x.png (152x152)
- Icon-App-83.5x83.5@2x.png (167x167)
- Icon-App-1024x1024@1x.png (1024x1024)
```

### Step 3: Set Team ID for Code Signing

In Xcode:
```
1. Select Runner project
2. Targets → Runner
3. Signing & Capabilities
4. Team: Select your Apple Developer Team
5. Bundle Identifier: com.aurasphere.crm
```

### Step 4: Add Capabilities (if using push notifications)

```
Signing & Capabilities → + Capability
- Push Notifications
- Background Modes (if needed)
- HomeKit (optional)
```

### Step 5: Build for Release

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build iOS archive
flutter build ios --release

# Or build for specific device
flutter build ios --release --no-codesign
```

### Step 6: Create App Store Connect Entry

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "+ New App"
3. Fill in:
   - Platform: iOS
   - Name: AuraSphere CRM
   - Bundle ID: com.aurasphere.crm
   - SKU: aurasphere-crm-001
   - User Access: Full Access (for now)

### Step 7: Upload to App Store

**Option A: Using Transporter**
```bash
# Download Transporter from App Store
# Drag and drop your .ipa file into Transporter
# Click "Deliver"
```

**Option B: Using Xcode**
```
1. Open Xcode
2. Window → Organizer
3. Select your archive
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow steps
```

---

## Android Build Configuration

### Step 1: Update Version Numbers

**File**: `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.aurasphere.crm"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1        // Increment for each release
        versionName "1.0.0"
        
        // ... other configs
    }
}
```

### Step 2: Configure App Icons

**Replace these files**:
```
android/app/src/main/res/mipmap-*/
- mipmap-hdpi/ic_launcher.png (72x72)
- mipmap-mdpi/ic_launcher.png (48x48)
- mipmap-xhdpi/ic_launcher.png (96x96)
- mipmap-xxhdpi/ic_launcher.png (144x144)
- mipmap-xxxhdpi/ic_launcher.png (192x192)
```

Also create adaptive icons:
```
- mipmap-anydpi-v26/ic_launcher.xml
- mipmap-anydpi-v26/ic_launcher_round.xml
```

**File**: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_bg"/>
  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

### Step 3: Create Keystore

```bash
# One-time: Create keystore file
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# Follow prompts:
# - Keystore password: [choose strong password]
# - Key password: [same or different]
# - First and Last Name: AuraSphere
# - Organization: AuraSphere
# - Country: [your country]
```

### Step 4: Configure Signing

**File**: `android/key.properties`
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**File**: `android/app/build.gradle`
```gradle
android {
    // ... other config
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 5: Update App Manifest

**File**: `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.aurasphere.crm">
    
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    
    <application
        android:label="AuraSphere CRM"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:usesCleartextTraffic="false">
        
        <!-- Activity configuration -->
        <activity
            android:name=".MainActivity"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### Step 6: Build Release Bundle

```bash
# Clean
flutter clean

# Get dependencies
flutter pub get

# Build app bundle (for Play Store)
flutter build appbundle --release

# Or build APK (for direct distribution)
flutter build apk --release --split-per-abi
```

### Step 7: Create Google Play Console Entry

1. Go to [Google Play Console](https://play.google.com/console)
2. Click "Create app"
3. Fill in:
   - App name: AuraSphere CRM
   - Default language: English
   - App category: Business
   - Choose content rating questionnaire

### Step 8: Upload to Play Store

1. Go to your app in Play Console
2. Release → Production
3. Create new release
4. Upload AAB file (from `build/app/outputs/bundle/release/app-release.aab`)
5. Add release notes
6. Review and submit

---

## Download Limits by Plan

### Supabase Migration

**File**: `database/migrations/create_app_downloads_table.sql`
```sql
CREATE TABLE app_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id VARCHAR NOT NULL, -- 'solo', 'team', 'workshop'
  device_type VARCHAR NOT NULL, -- 'ios', 'android', 'web'
  device_name VARCHAR,
  app_version VARCHAR NOT NULL,
  os_version VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, device_type, created_at)
);

CREATE INDEX idx_app_downloads_user_month 
ON app_downloads(user_id, DATE_TRUNC('month', created_at), device_type);

-- Enable RLS
ALTER TABLE app_downloads ENABLE ROW LEVEL SECURITY;

-- Users can only see their own downloads
CREATE POLICY "Users can view own downloads"
ON app_downloads FOR SELECT
USING (auth.uid() = user_id);

-- Only app backend can insert
CREATE POLICY "App can insert downloads"
ON app_downloads FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

### Plan Limits Configuration

**File**: `lib/services/plan_limits_service.dart`
```dart
class PlanLimits {
  final String planId;
  final int maxUsers;
  final int aiCallsPerMonth;
  final int iosDownloadsPerMonth;
  final int androidDownloadsPerMonth;
  final int webDownloadsPerMonth;
  final int dataStorageGB;
  
  const PlanLimits({
    required this.planId,
    required this.maxUsers,
    required this.aiCallsPerMonth,
    required this.iosDownloadsPerMonth,
    required this.androidDownloadsPerMonth,
    required this.webDownloadsPerMonth,
    required this.dataStorageGB,
  });
}

class PlanLimitsService {
  static const Map<String, PlanLimits> limits = {
    'solo': PlanLimits(
      planId: 'solo',
      maxUsers: 1,
      aiCallsPerMonth: 500,
      iosDownloadsPerMonth: 2,
      androidDownloadsPerMonth: 2,
      webDownloadsPerMonth: 5,
      dataStorageGB: 5,
    ),
    'team': PlanLimits(
      planId: 'team',
      maxUsers: 3,
      aiCallsPerMonth: 1000,
      iosDownloadsPerMonth: 5,
      androidDownloadsPerMonth: 5,
      webDownloadsPerMonth: 10,
      dataStorageGB: 25,
    ),
    'workshop': PlanLimits(
      planId: 'workshop',
      maxUsers: 7,
      aiCallsPerMonth: 1500,
      iosDownloadsPerMonth: 15,
      androidDownloadsPerMonth: 15,
      webDownloadsPerMonth: 25,
      dataStorageGB: 100,
    ),
  };
  
  static Future<bool> canDownloadApp(String planId, String deviceType) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    
    final plan = limits[planId];
    if (plan == null) return false;
    
    // Get current month start
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Count downloads this month
    final response = await supabase
        .from('app_downloads')
        .select('id')
        .eq('user_id', userId)
        .eq('device_type', deviceType)
        .gte('created_at', monthStart.toIso8601String());
    
    final downloadCount = response.length ?? 0;
    
    // Get limit
    final limit = deviceType == 'ios' 
        ? plan.iosDownloadsPerMonth
        : deviceType == 'android'
            ? plan.androidDownloadsPerMonth
            : plan.webDownloadsPerMonth;
    
    return downloadCount < limit;
  }
  
  static Future<void> recordDownload(String planId, String deviceType) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    
    final packageInfo = await PackageInfo.fromPlatform();
    
    await supabase.from('app_downloads').insert({
      'user_id': userId,
      'plan_id': planId,
      'device_type': deviceType,
      'app_version': packageInfo.version,
      'os_version': Platform.operatingSystemVersion,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### Download Button Implementation

**In your App Download Page**:
```dart
class AppDownloadPage extends StatefulWidget {
  @override
  State<AppDownloadPage> createState() => _AppDownloadPageState();
}

class _AppDownloadPageState extends State<AppDownloadPage> {
  bool _canDownloadIOS = true;
  bool _canDownloadAndroid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDownloadLimits();
  }

  Future<void> _checkDownloadLimits() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/sign-in');
      return;
    }
    
    final org = await supabase
        .from('organizations')
        .select('plan')
        .eq('owner_id', user.id)
        .single();
    
    final planId = org['plan'] as String;
    
    final canIOS = await PlanLimitsService.canDownloadApp(planId, 'ios');
    final canAndroid = await PlanLimitsService.canDownloadApp(planId, 'android');
    
    setState(() {
      _canDownloadIOS = canIOS;
      _canDownloadAndroid = canAndroid;
    });
  }

  Future<void> _downloadApp(String platform) async {
    final supabase = Supabase.instance.client;
    final planId = 'solo'; // Get from user org
    
    if (platform == 'ios' && !_canDownloadIOS) {
      setState(() => _errorMessage = 'iOS download limit reached this month');
      return;
    }
    
    if (platform == 'android' && !_canDownloadAndroid) {
      setState(() => _errorMessage = 'Android download limit reached this month');
      return;
    }
    
    try {
      // Record download
      await PlanLimitsService.recordDownload(planId, platform);
      
      // Redirect to app store
      final url = platform == 'ios'
          ? 'https://apps.apple.com/app/aurasphere-crm'
          : 'https://play.google.com/store/apps/details?id=com.aurasphere.crm';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Container(
                color: Colors.red,
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _canDownloadIOS 
                  ? () => _downloadApp('ios')
                  : null,
              child: const Text('Download for iOS'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _canDownloadAndroid
                  ? () => _downloadApp('android')
                  : null,
              child: const Text('Download for Android'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Pre-Launch Checklist

- [ ] iOS version numbers updated
- [ ] Android version numbers updated
- [ ] App icons created (all sizes)
- [ ] App signing configured (iOS)
- [ ] Keystore created (Android)
- [ ] AndroidManifest.xml updated
- [ ] TestFlight build uploaded (iOS)
- [ ] Internal testing release uploaded (Android)
- [ ] App Store Connect entry created
- [ ] Play Console entry created
- [ ] Privacy Policy URL added
- [ ] Screenshots prepared (iOS & Android)
- [ ] Description written
- [ ] Download limits configured
- [ ] Database migrations applied
- [ ] Download tracking implemented

---

## Build Commands Quick Reference

```bash
# iOS
flutter build ios --release

# Android
flutter build appbundle --release
flutter build apk --release --split-per-abi

# Web (for reference)
flutter build web --release

# View build status
flutter devices
flutter pub get
```

---

**Last Updated**: January 4, 2026  
**Status**: Ready for App Store Submission
