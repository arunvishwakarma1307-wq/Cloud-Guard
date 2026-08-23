import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'pdf_file_validation.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? selectedFileName;
  int? selectedFileSize;

  PlatformFile? selectedFile;
  bool isSelectingFile = false;

  // =====================================================
  // CHOOSE FILE
  // =====================================================

  Future<void> pickFile() async {
    setState(() {
      isSelectingFile = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted || file == null) {
        return;
      }

      final fileSize = await file.length();
      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        // Some platforms do not expose file bytes until a later operation.
      }

      final validationMessage = validatePdfFile(
        fileName: file.name,
        fileSize: fileSize,
        bytes: bytes,
      );

      if (validationMessage != null) {
        showMessage(validationMessage);
        return;
      }

      setState(() {
        selectedFile = file;
        selectedFileName = file.name;
        selectedFileSize = fileSize;
      });
    } catch (_) {
      if (mounted) {
        showMessage("Unable to select a PDF file. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          isSelectingFile = false;
        });
      }
    }
  }

  void removeSelection() {
    setState(() {
      selectedFile = null;
      selectedFileName = null;
      selectedFileSize = null;
    });
  }

  void showStorageUnavailable() {
    showMessage(
      "Cloud upload is unavailable because Firebase Storage is not configured or enabled.",
    );
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =====================================================
  // FILE SIZE
  // =====================================================

  String getFileSize() {
    if (selectedFileSize == null) {
      return "";
    }

    final size = selectedFileSize!;

    if (size < 1024) {
      return "$size bytes";
    }

    if (size < 1024 * 1024) {
      return "${(size / 1024).toStringAsFixed(2)} KB";
    }

    return "${(size / (1024 * 1024)).toStringAsFixed(2)} MB";
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cloud Upload",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Upload Files",

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Select a PDF file to upload to Cloud Guard",

                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 30),

              // =================================================
              // CHOOSE FILE CARD
              // =================================================
              Card(
                elevation: 5,

                child: SizedBox(
                  width: double.infinity,
                  height: 220,

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 55,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Select a PDF to upload",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: isSelectingFile ? null : pickFile,
                        icon: isSelectingFile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          isSelectingFile ? "Selecting..." : "Choose PDF",
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // SELECTED FILE
              // =================================================
              if (selectedFileName != null)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 35,
                    ),

                    title: Text(
                      selectedFileName!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    subtitle: Text(getFileSize()),

                    trailing: IconButton(
                      tooltip: "Remove selected file",
                      onPressed: removeSelection,
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // =================================================
              // UPLOAD BUTTON
              // =================================================
              if (selectedFile != null)
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: showStorageUnavailable,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload to Cloud"),
                  ),
                ),

              if (selectedFile != null) ...[
                const SizedBox(height: 15),
                const Text(
                  "Cloud upload is unavailable because Firebase Storage is not configured or enabled.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],

              const SizedBox(height: 25),

              // =================================================
              // RECENT UPLOADS
              // =================================================
              const Text(
                "Recent Uploads",

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),

                  title: const Text("No recent cloud uploads"),

                  subtitle: const Text(
                    "Live cloud listings and cloud uploads are unavailable because Firebase Storage is not enabled or configured.",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
