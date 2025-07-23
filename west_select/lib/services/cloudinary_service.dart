import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UploadedImage {
  final String url;
  final String? publicId;

  UploadedImage({required this.url, this.publicId});
}

class CloudinaryService {
  static final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static final String _apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static final String _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  final cloudinary = CloudinaryObject.fromCloudName(
    cloudName: 'CLOUDINARY_CLOUD_NAME'
  );

  /// Uploads an image to Cloudinary
  static Future<UploadedImage?> uploadImage(File file) async {
    if (!file.existsSync()) {
      print("[CloudinaryService] File does not exist");
      return null;
    }

    try {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', fileExtension),
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        return UploadedImage(
          url: data['secure_url'],
          publicId: data['public_id'],
        );
      } else {
        print("[CloudinaryService] Upload failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[CloudinaryService] Exception during upload: $e");
      return null;
    }
  }

  /// Deletes an image from Cloudinary using the public ID.
  static Future<bool> deleteImage(String publicId) async {
    print('delete image here!');
    print('$publicId');
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/resources/image/upload',
    );

    final credentials = base64Encode(utf8.encode("$_apiKey:$_apiSecret"));

    // Convert to form fields: public_ids[]=id1, public_ids[]=id2, etc.
    final formData = <String, String>{};
    // for (var id in publicId) {
    //   formData['public_ids[]'] = id;
    // }

    formData['public_ids[]'] = publicId;

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
        body: formData,
      );

      print("[CloudinaryService] Delete response status: ${response.statusCode}");
      print("[CloudinaryService] Delete response body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // body['deleted'] should contain the deleted ids
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("[CloudinaryService] Exception during deletion: $e");
      return false;
    }
  }

  /// Attempts to extract public_id from secure_url.
  static String? extractPublicIdFromUrl(String secureUrl) {
    try {
      final uri = Uri.parse(secureUrl);
      final path = uri.path; // e.g. /drlvci7kt/image/upload/v1234567890/filename.jpg
      final parts = path.split('/');
      final filenameWithExt = parts.last;
      final publicIdWithExt = filenameWithExt.split('.').first;

      // Attempt to reconstruct public_id
      final publicIdParts = parts.skipWhile((p) => p != 'upload').skip(1).toList(); // skip 'upload' and version
      publicIdParts.removeLast(); // remove filename
      publicIdParts.add(publicIdWithExt); // add public_id

      return publicIdParts.join('/');
    } catch (e) {
      print("[CloudinaryService] Failed to parse public_id: $e");
      return null;
    }
  }
}
