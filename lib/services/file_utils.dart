import 'dart:io';

class FileUtils {
  /// Open a file using the platform's default handler.
  /// Returns true if the command was executed.
  static Future<bool> openFile(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', '"$path"']);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      } else {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
