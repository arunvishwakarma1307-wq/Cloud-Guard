import 'package:flutter/material.dart';

class StoragePage extends StatelessWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Cloud Storage",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              "Storage Overview",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 20),


            Card(

              elevation: 5,

              child: ListTile(

                leading: const Icon(
                  Icons.cloud,
                  color: Colors.blue,
                  size: 40,
                ),


                title: const Text(
                  "Cloud Space",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),


                subtitle: const Text(
                  "45 GB used / 100 GB total",
                ),

              ),
            ),


            const SizedBox(height: 20),


            const Text(
              "Files",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),


            Card(
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text("report.pdf"),
              ),
            ),


            Card(
              child: ListTile(
                leading: Icon(Icons.folder),
                title: Text("Backup Folder"),
              ),
            ),


          ],
          ),
        ),
      ),
    );
  }
}
