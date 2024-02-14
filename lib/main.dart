import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // for json decoding
import 'package:flutter/services.dart';
import 'package:studypharm/firebase_options.dart'; // import for rootBundle

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(NavigatorApp());

}

class Drug {
  final String id;
  final String brandName;
  final String genericName;
  final String? drugClass;
  final String? indication;
  final String? schedule;
  final String? notes;

  Drug({
    required this.id,
    required this.brandName,
    required this.genericName,
    required this.drugClass,
    required this.indication,
    required this.schedule,
    required this.notes,
  });
}

final db = FirebaseFirestore.instance;

class NavigatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const MyApp(),
          );
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Firestore Data Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              addDrugData();
              fetchDrugList(context); // Pass the context to fetchDrugList
            },
            child: Text('Fetch Data'),
          ),
        ),
      ),
    );
  }

  void addDrugData() async {
    final drugsCollection = db.collection("drugs");

    try {
      QuerySnapshot querySnapshot = await drugsCollection.get();
      int drugCount = querySnapshot.size;
      if (drugCount == 0 || drugCount < 200) {
        final drugsString =
            await rootBundle.loadString('lib/top_200_drugs.json');
        final Map<String, dynamic> jsonData = json.decode(drugsString);
        final Map<String, dynamic> drugsData = jsonData['drugs'];

        drugsData.forEach((key, drug) {
          final Map<String, dynamic> drugData = {
            "brandName": drug['brandName'],
            "genericName": drug['genericName'],
            "drugClass": drug['drugClass'] ?? '',
            "indication": drug['indication'] ?? '',
            "schedule": drug['schedule'] ?? '',
            "notes": drug['notes'] ?? 'Enter your notes here:',
          };
          drugsCollection.add(drugData);
        });
        print('Data added success');
      } else {
        print('Collection not empty and at least 200 drugs');
      }
    } catch (e) {
      print("Error loading JSON file: $e");
    }
  }

  void fetchDrugList(BuildContext context) {
    db.collection('drugs').get().then(
      (querySnapshot) {
        print("Successfully completed");
        List<Drug> drugsList = [];

        for (var docSnapshot in querySnapshot.docs) {
          Map<String, dynamic> data =
              docSnapshot.data();
          Drug drug = Drug(
            id: docSnapshot.id,
            brandName: data['brandName'] ,
            genericName: data['genericName'],
            drugClass: data['drugClass'],
            indication: data['indication'],
            schedule: data['schedule'],
            notes: data['notes'],
          );
          drugsList.add(drug);
        }

        // Display the list of drugs
        displayDrugList(drugsList, context); // Pass the context
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  void displayDrugList(List<Drug> drugsList, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrugListPage(drugsList: drugsList),
      ),
    );
  }
}

class DrugListPage extends StatelessWidget {
  final List<Drug> drugsList;

  DrugListPage({required this.drugsList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drug List'),
      ),
      body: ListView.builder(
        itemCount: drugsList.length,
        itemBuilder: (context, index) {
          Drug drug = drugsList[index];
          return ListTile(
            title: Text(drug.brandName),
            onTap: () {
              // Navigate to the drug details page
              navigateToDrugDetails(context, drug); // Pass the context
            },
          );
        },
      ),
    );
  }

  void navigateToDrugDetails(BuildContext context, Drug drug) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrugDetailsPage(drug: drug),
      ),
    );
  }
}

class DrugDetailsPage extends StatelessWidget {
  final Drug drug;

  DrugDetailsPage({required this.drug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drug.brandName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generic Name: ${drug.genericName}'),
          Text('Drug Class: ${drug.drugClass}'),
          Text('Indication: ${drug.indication}'),
          Text('Schedule: ${drug.schedule}'),
          Text('Notes: ${drug.notes}'),
          // Add more details as needed
        ],
      ),
    );
  }
}