import 'dart:io';

void main() {
  final dir = Directory('lib/features/explorer/presentation/widgets');
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      // revert bad replacements
      content = content.replaceAll("import '../../../models/file_item.dart';", "import '../../models/file_item.dart';");
      content = content.replaceAll("import '../../../../media/data/media_service.dart';", "import '../../../media/data/media_service.dart';");
      file.writeAsStringSync(content);
    }
  }

  // Also in server config screen
  final configScreenFile = File('lib/features/server_config/presentation/server_config_screen.dart');
  var configContent = configScreenFile.readAsStringSync();
  configContent = configContent.replaceAll("if (!context.mounted) return;", "if (!mounted) return;"); // Riverpod ConsumerState has its own mounted property. context.mounted is not needed here and actually caused warning.
  configScreenFile.writeAsStringSync(configContent);

  // Explorer Screen context.mounted
  final explorerFile = File('lib/features/explorer/presentation/explorer_screen.dart');
  var explorerContent = explorerFile.readAsStringSync();
  explorerContent = explorerContent.replaceAll("if (!context.mounted) return;", "if (!mounted) return;");
  explorerContent = explorerContent.replaceAll("if (context.mounted)", "if (mounted)");
  explorerContent = explorerContent.replaceAll("if (success && context.mounted)", "if (success && mounted)");
  explorerContent = explorerContent.replaceAll("else if (context.mounted)", "else if (mounted)");
  explorerFile.writeAsStringSync(explorerContent);
}
