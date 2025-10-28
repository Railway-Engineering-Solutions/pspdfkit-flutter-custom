///
///  Copyright © 2023-2025 PSPDFKit GmbH. All rights reserved.
///
///  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
///  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
///  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
///  This notice may not be removed from this file.
///

/// Stub implementation of NutrientWeb for non-web platforms.
class NutrientWeb {
  static String get version => 'Not available on this platform';

  static Future<void> setLicenseKey(String? licenseKey) async {
    // No-op for non-web platforms
  }

  static String get authorName => '';

  static List<dynamic> get defaultToolbarItems => [];
}

/// Stub implementation of NutrientWebToolbarItem for non-web platforms.
class NutrientWebToolbarItem {
  // Stub implementation
}
