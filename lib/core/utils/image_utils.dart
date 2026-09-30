import 'package:gea_app/core/network/dio_client.dart';

class ImageUtils {
  static String? getFullUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    
    // Remove leading slash if exists
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // The backend serves files at /api/archivos/public/
    // Since baseUrl is http://.../api, we just need to append the path
    // But check if the path already contains 'archivos/public'
    if (cleanPath.contains('archivos/public')) {
       return '${DioClient.baseUrl}/$cleanPath';
    }
    
    return '${DioClient.baseUrl}/archivos/public/$cleanPath';
  }
}
