import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../explorer/models/file_item.dart';

class PdfViewerWidget extends StatefulWidget {
  final FileItem item;

  const PdfViewerWidget({super.key, required this.item});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final _storage = SecureStorageService();
  String? _url;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final baseUrl = await _storage.getBaseUrl();
    final token = await _storage.getToken();
    
    if (baseUrl != null) {
      final url = '$baseUrl/api/media/stream/${Uri.encodeComponent(widget.item.relativePath)}';
      setState(() {
        _url = url;
        _token = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return SfPdfViewer.network(
      _url!,
      headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
      canShowScrollHead: false,
      canShowScrollStatus: false,
    );
  }
}
