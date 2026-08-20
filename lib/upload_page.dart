import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? selectedFileName;
  int? selectedFileSize;

  html.File? selectedFile;

  bool isUploading = false;
  double uploadProgress = 0;

  // =====================================================
  // CHOOSE FILE
  // =====================================================

  void pickFile() {
    final input = html.FileUploadInputElement();

    input.accept = '.pdf';

    input.click();

    input.onChange.listen((event) {
      final files = input.files;

      if (files != null && files.isNotEmpty) {
        final file = files.first;

        setState(() {
          selectedFile = file;
          selectedFileName = file.name;
          selectedFileSize = file.size;
          uploadProgress = 0;
        });
      }
    });
  }

  // =====================================================
  // UPLOAD FILE TO FIREBASE STORAGE
  // =====================================================

  Future<void> uploadFile() async {
    if (selectedFile == null) {
      showMessage("Please choose a PDF first");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage("Please login first");
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0;
    });

    try {
      final file = selectedFile!;

      // Each user's files will be stored separately.
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("users")
          .child(user.uid)
          .child("files")
          .child(file.name);

      // Create upload task
      final uploadTask = storageRef.putBlob(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          setState(() {
            uploadProgress =
                snapshot.bytesTransferred /
                    snapshot.totalBytes;
          });
        }
      });

      // Wait until upload finishes
      await uploadTask;

      if (!mounted) return;

      setState(() {
        isUploading = false;
        uploadProgress = 1;
      });

      showMessage(
        "File uploaded successfully!",
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      String message = "Upload failed";

      if (e.code == 'unauthorized') {
        message = "You don't have permission to upload";
      } else if (e.code == 'canceled') {
        message = "Upload cancelled";
      } else if (e.code == 'quota-exceeded') {
        message = "Storage quota exceeded";
      } else if (e.code == 'object-not-found') {
        message = "Storage location not found";
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      showMessage(
        "Something went wrong during upload",
      );
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Upload Files",

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Select a PDF file to upload to Cloud Guard",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
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
                  mainAxisAlignment:
                      MainAxisAlignment.center,

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
                      onPressed:
                          isUploading
                              ? null
                              : pickFile,

                      icon: const Icon(
                        Icons.upload_file,
                      ),

                      label: const Text(
                        "Choose PDF",
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

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    getFileSize(),
                  ),

                  trailing: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
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
                  onPressed:
                      isUploading
                          ? null
                          : uploadFile,

                  icon: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload,
                        ),

                  label: Text(
                    isUploading
                        ? "Uploading..."
                        : "Upload to Cloud",
                  ),
                ),
              ),

            // =================================================
            // PROGRESS
            // =================================================

            if (isUploading) ...[
              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: uploadProgress,
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  "${(uploadProgress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 25),

            // =================================================
            // RECENT UPLOADS
            // =================================================

            const Text(
              "Recent Uploads",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                ),

                title: const Text(
                  "report.pdf",
                ),

                subtitle: const Text(
                  "Demo file",
                ),

                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}