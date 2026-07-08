import 'dart:io';

void main() {
  // Fix explorer widgets
  final dir = Directory('lib/features/explorer/presentation/widgets');
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      content = content.replaceAll("'../../../core", "'../../../../core");
      content = content.replaceAll("import '../../models/file_item.dart';", "import '../../../models/file_item.dart';");
      content = content.replaceAll("import '../../../media/data/media_service.dart';", "import '../../../../media/data/media_service.dart';");
      file.writeAsStringSync(content);
    }
  }

  // Fix media viewer widgets
  final mediaDir = Directory('lib/features/media/presentation/widgets');
  for (final file in mediaDir.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      content = content.replaceAll("import '../data/media_service.dart';", "import '../../data/media_service.dart';");
      content = content.replaceAll("import '../../explorer/models/file_item.dart';", "import '../../../explorer/models/file_item.dart';");
      file.writeAsStringSync(content);
    }
  }

  // Fix explorer_controller.dart
  final controllerFile = File('lib/features/explorer/presentation/explorer_controller.dart');
  var controllerContent = controllerFile.readAsStringSync();
  controllerContent = controllerContent.replaceAll("import '../data/vault_service.dart';", "import '../../vault/data/vault_service.dart';");
  controllerFile.writeAsStringSync(controllerContent);

  // Fix media_preview_screen.dart (remove unused imports)
  final mediaPreviewFile = File('lib/features/media/presentation/media_preview_screen.dart');
  var mediaPreviewContent = mediaPreviewFile.readAsStringSync();
  mediaPreviewContent = mediaPreviewContent.replaceAll("import '../../../core/constants/app_colors.dart';\n", "");
  mediaPreviewContent = mediaPreviewContent.replaceAll("import '../data/media_service.dart';\n", "");
  mediaPreviewFile.writeAsStringSync(mediaPreviewContent);
  
  // Fix download_helper.dart (remove unused and deprecated)
  final downloadFile = File('lib/core/utils/download_helper.dart');
  var downloadContent = downloadFile.readAsStringSync();
  downloadContent = downloadContent.replaceAll("import 'dart:io';\n", "");
  downloadContent = downloadContent.replaceAll("import '../network/api_client.dart';\n", "");
  downloadContent = downloadContent.replaceAll("Share.shareXFiles", "Share.shareXFiles"); // Wait, it said use SharePlus... Wait Share is from SharePlus. I will ignore deprecated warnings for now, or just use Share.shareXFiles
  downloadFile.writeAsStringSync(downloadContent);
}
