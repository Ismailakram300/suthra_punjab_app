import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class ShowFuelEntries extends StatefulWidget {
  const ShowFuelEntries({super.key});

  @override
  State<ShowFuelEntries> createState() => _ShowFuelEntriesState();
}

class _ShowFuelEntriesState extends State<ShowFuelEntries> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fuel Details"),

      ),
     body: SingleChildScrollView(
       child: Column(
         children: [

         ],
       ),
     ),
    );
  }
}
