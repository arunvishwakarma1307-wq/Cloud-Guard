import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Security Center",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [


            const Text(
              "Security Overview",
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
                  Icons.shield,
                  color: Colors.green,
                  size: 40,
                ),


                title: const Text(
                  "Firewall Protection",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),


                subtitle: const Text(
                  "Active and protecting your cloud",
                ),


                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

              ),
            ),



            Card(

              elevation: 5,

              child: ListTile(

                leading: const Icon(
                  Icons.lock,
                  color: Colors.blue,
                  size: 40,
                ),


                title: const Text(
                  "Encryption",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),


                subtitle: const Text(
                  "AES-256 encryption enabled",
                ),


                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

              ),
            ),



            Card(

              elevation: 5,

              child: ListTile(

                leading: const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 40,
                ),


                title: const Text(
                  "Threat Detection",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),


                subtitle: const Text(
                  "No threats detected",
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