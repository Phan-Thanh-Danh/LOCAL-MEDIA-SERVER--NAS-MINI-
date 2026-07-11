import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../explorer/models/file_item.dart';

class TextViewerWidget extends StatefulWidget {
  final FileItem item;

  const TextViewerWidget({super.key, required this.item});

  @override
  State<TextViewerWidget> createState() => _TextViewerWidgetState();
}

class _TextViewerWidgetState extends State<TextViewerWidget> {
  final _storage = SecureStorageService();
  String? _textContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    try {
      final baseUrl = await _storage.getBaseUrl();
      final token = await _storage.getToken();
      
      if (baseUrl != null) {
        final encodedPath = Uri.encodeComponent(widget.item.relativePath).replaceAll('%2F', '/');
        final url = '$baseUrl/api/media/file/$encodedPath';
        final dio = Dio();
        final response = await dio.get(
          url,
          options: Options(
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
            responseType: ResponseType.plain,
          ),
        );
        
        setState(() {
          _textContent = response.data?.toString() ?? 'Tệp rỗng';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Lỗi cấu hình Base URL';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể tải nội dung tệp: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: SingleChildScrollView(
        child: Text(
          _textContent ?? '',
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
