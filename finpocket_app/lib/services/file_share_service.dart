import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

/// Thin wrapper around the native `com.finpocket/share` MethodChannel.
///
/// Opens WhatsApp directly with a file attached (no share-sheet detour),
/// saves a copy to the device Downloads folder, and opens files with the system chooser.
class FileShareService {
  static const MethodChannel _channel = MethodChannel('com.finpocket/share');

  /// Opens WhatsApp directly with [filePath] attached. When [phone] is a
  /// valid 10-digit Indian number, the app targets WhatsApp specifically.
  static Future<bool> shareFileToWhatsApp({
    required String filePath,
    String? phone,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareFileToWhatsApp', {
        'filePath': filePath,
        'phone': phone ?? '',
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[FileShareService] share failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[FileShareService] share error: $e');
      return false;
    }
  }

  /// Copies [filePath] into the device Downloads folder so it appears in
  /// the Downloads app and Files browser.
  static Future<String?> downloadToDownloads(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>('downloadToDownloads', {
        'filePath': filePath,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FileShareService] download failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[FileShareService] download error: $e');
      return null;
    }
  }

  /// Opens [filePath] using Android's system app chooser (PDF viewer for PDF,
  /// Excel/Office spreadsheet viewer for CSV/Excel).
  static Future<bool> openFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('openFile', {
        'filePath': filePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[FileShareService] openFile failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[FileShareService] openFile error: $e');
      return false;
    }
  }
}
