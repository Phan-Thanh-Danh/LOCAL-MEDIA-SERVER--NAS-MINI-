import 'dart:io';

void main() {
  final explorerFile = File('lib/features/explorer/presentation/explorer_screen.dart');
  var content = explorerFile.readAsStringSync();
  content = content.replaceAll("if (mounted) {", "if (context.mounted) {");
  content = content.replaceAll("if (success && mounted)", "if (success && context.mounted)");
  content = content.replaceAll("else if (mounted)", "else if (context.mounted)");
  content = content.replaceAll("if (!mounted) return;", "if (!context.mounted) return;");
  explorerFile.writeAsStringSync(content);

  final configScreenFile = File('lib/features/server_config/presentation/server_config_screen.dart');
  var configContent = configScreenFile.readAsStringSync();
  configContent = configContent.replaceAll("if (!mounted) return;", "if (!context.mounted) return;");
  configScreenFile.writeAsStringSync(configContent);
}
