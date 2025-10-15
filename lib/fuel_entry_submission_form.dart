import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:figma_practice_project/Custom_Widgets/CustomButton.dart';
import 'package:figma_practice_project/Fuel_Management/Model/fuel_form_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FuelEntrySubmissionForm extends StatefulWidget {
  const FuelEntrySubmissionForm({super.key});

  @override
  State<FuelEntrySubmissionForm> createState() =>
      _FuelEntrySubmissionFormState();
}

class _FuelEntrySubmissionFormState extends State<FuelEntrySubmissionForm> {
  String? _image;
  String? _imageAfter;
  String? _imageVehicle;
  final ImagePicker _pickImage = ImagePicker();
  Future<void> _pickedImage(String type) async {
    final XFile? image = await _pickImage.pickImage(source: ImageSource.camera);
    if (image != null) {
      final byte = await File(image.path).readAsBytes();
      final base64String = base64Encode(byte);
      setState(() {
        if (type == "before") {
          _image = base64String;
        } else if (type == "after") {
          _imageAfter = base64String;
        } else {
          _imageVehicle = base64String;
        }
      });
    }
  }

  Future<void> formSubmit() async {
    if (_formKey.currentState!.validate()) {

      print ("Berfore Image $_image");
      print ("after Image $_imageAfter");
      print ("vehicle Image $_imageVehicle"
          "");
      final entries = FuelEntries(
        bill_no: _billNo.text.trim(),
        vehicle_type: _vehicleType.text.trim(),
        vehicle_number: _vehicleNumber.text.trim(),
        liters: _liters.text.trim(),
        price_per_liter: _pricePerLiter.text.trim(),
        project: "Chakwal",
        vendor: _vendor.text.trim(),
        beforeImage: _image ?? "",
        afterImage: "",
        vehcileImage:  "",
      );
      setState(() {
        _fuelentries.add(entries);
        _billNo.clear();
        _vehicleNumber.clear();
        _vehicleType.clear();
        _liters.clear();
        _pricePerLiter.clear();
        _project.clear();
        _vendor.clear();
        _image = null;
        _imageAfter = null;
        _imageVehicle = null;
      });

      try {
        await FirebaseFirestore.instance
            .collection("fuel_entries")
            .add(entries.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Entry added successfully!")),
        );
      } catch (e) {
        print("❌ Error adding to Firestore: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed to add entry: $e")));
      }
      //
      // await FirebaseFirestore.instance.collection("fuel_entries").add(entries.toMap());
      //
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("✅ Entry added successfully!")),
      // );
    }
  }

  final _billNo = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _vehicleType = TextEditingController();
  final _liters = TextEditingController();
  final _pricePerLiter = TextEditingController();
  final _vendor = TextEditingController();
  final _project = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final List<FuelEntries> _fuelentries = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fuel Submission Form")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_image == null)
              GestureDetector(
                onTap: () {
                  _pickedImage("before");
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => ComplaintForm()),
                  // );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: DottedBorder(
                    color: Colors.black87,
                    strokeWidth: 1.5,
                    borderType: BorderType.RRect,
                    radius: Radius.circular(12),
                    dashPattern: [6, 4],
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt),
                          SizedBox(width: 10),
                          Text(
                            "Add Meter Picture",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageBox(
                        label: "Before",
                        image: _image,
                        onTap: () => _pickedImage("before"),
                      ),
                      _buildImageBox(
                        label: "After",
                        image: _imageAfter,
                        onTap: () => _pickedImage("after"),
                      ),
                      _buildImageBox(
                        label: "Vehicle",
                        image: _imageVehicle,
                        onTap: () => _pickedImage("vehicle"),
                      ),
                    ],
                    // children: [
                    //   Expanded(
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(8.0),
                    //       child: ClipRRect(
                    //         child: _image!= null? Image.memory(
                    //           base64Decode(_image!),
                    //           height: 60,
                    //           width: 60,
                    //         ):SizedBox(),
                    //       ),
                    //     ),
                    //   ),
                    //   GestureDetector(
                    //     onTap: (){
                    //       _pickedImage("after");
                    //     },
                    //     child: Expanded(
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(8.0),
                    //         child: ClipRRect(
                    //           child: _imageAfter != null  ?Image.memory(base64Decode(_imageAfter!), height: 60, width: 60): Icon(Icons.add),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    //   Expanded(
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(8.0),
                    //       child: ClipRRect(
                    //         child: _imageVehicle != null  ?  Image.memory(base64Decode(_imageVehicle!) , height: 60, width: 60):Icon(Icons.add),
                    //       ),
                    //     ),
                    //   ),
                    // ],
                  ),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(_billNo, "Bill no"),
                        CustomTextField(_vehicleNumber, "Vehicle Number"),
                        CustomTextField(_vehicleType, "Vehicle Type"),
                        CustomTextField(_pricePerLiter, "Price per Liter"),
                        CustomTextField(_liters, "Liter"),
                        CustomTextField(_project, "Project"),
                        CustomTextField(_vendor, "Vender"),
                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: formSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_fuelentries.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fuelentries.length,
                      itemBuilder: (context, index) {
                        final item = _fuelentries[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(child: Text("${index + 1}")),
                            title: Text("Vehicle No: ${item.vehicle_number}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Bill No: ${item.bill_no}"),
                                Text("Type: ${item.vehicle_type}"),
                                Text("Liters: ${item.liters}"),
                                Text("Price: ${item.price_per_liter}"),
                                Text("Vendor: ${item.vendor}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _fuelentries.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget CustomTextField(TextEditingController _controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _controller,
        validator: (value) => value!.isEmpty ? "Required Field" : null,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

//
// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:figma_practice_project/Fuel_Management/Model/fuel_form_model.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class FuelEntrySubmissionForm extends StatefulWidget {
//   const FuelEntrySubmissionForm({super.key});
//
//   @override
//   State<FuelEntrySubmissionForm> createState() =>
//       _FuelEntrySubmissionFormState();
// }

// class _FuelEntrySubmissionFormState extends State<FuelEntrySubmissionForm> {
//   String? _imageBefore;
//   String? _imageAfter;
//   String? _imageVehicle;
//
//   final ImagePicker _picker = ImagePicker();
//
//   // 🔹 Pick Image Function (Handles all types)
//   Future<void> _pickImage(String type) async {
//     try {
//       final XFile? image = await _picker.pickImage(source: ImageSource.camera);
//       if (image != null) {
//         final bytes = await File(image.path).readAsBytes();
//         final base64String = base64Encode(bytes);
//         setState(() {
//           if (type == "before") {
//             _imageBefore = base64String;
//           } else if (type == "after") {
//             _imageAfter = base64String;
//           } else if (type == "vehicle") {
//             _imageVehicle = base64String;
//           }
//         });
//       }
//     } catch (e) {
//       print("❌ Image pick error: $e");
//     }
//   }
//
//   // 🔹 Controllers
//   final _billNo = TextEditingController();
//   final _vehicleNumber = TextEditingController();
//   final _vehicleType = TextEditingController();
//   final _liters = TextEditingController();
//   final _pricePerLiter = TextEditingController();
//   final _vendor = TextEditingController();
//   final _project = TextEditingController();
//
//   final _formKey = GlobalKey<FormState>();
//   final List<FuelEntries> _fuelEntries = [];
//
//   // 🔹 Submit Form
//   Future<void> _formSubmit() async {
//     if (!_formKey.currentState!.validate()) return;
//     print("vvvvvv$_imageAfter");
//     print(_imageVehicle);
//     print(_imageBefore);
//     final entry = FuelEntries(
//       bill_no: _billNo.text.trim(),
//       vehicle_type: _vehicleType.text.trim(),
//       vehicle_number: _vehicleNumber.text.trim(),
//       liters: _liters.text.trim(),
//       price_per_liter: _pricePerLiter.text.trim(),
//       project: _project.text.trim().isEmpty ? "Chakwal" : _project.text.trim(),
//       vendor: _vendor.text.trim(),
//       beforeImage: _imageBefore ?? "",
//       afterImage: _imageAfter ?? "",
//       vehcileImage: _imageVehicle ?? "",
//     );
//
//     try {
//       await FirebaseDatabase.instance
//           .ref("fuel_entries")
//           .push()
//           .set(entry.toMap());
//
//       setState(() {
//         _fuelEntries.add(entry);
//         _clearForm();
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("✅ Entry added successfully!")),
//       );
//     } catch (e) {
//       print("❌ Error adding entry: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("❌ Failed to add entry: $e")),
//       );
//     }
//   }
//
//   // 🔹 Clear form fields
//   void _clearForm() {
//     _billNo.clear();
//     _vehicleNumber.clear();
//     _vehicleType.clear();
//     _liters.clear();
//     _pricePerLiter.clear();
//     _vendor.clear();
//     _project.clear();
//     _imageBefore = null;
//     _imageAfter = null;
//     _imageVehicle = null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Fuel Submission Form")),
//       body: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//
//               // 🔹 Image Row
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildImageBox(
//                     label: "Before",
//                     image: _imageBefore,
//                     onTap: () => _pickImage("before"),
//                   ),
//                   _buildImageBox(
//                     label: "After",
//                     image: _imageAfter,
//                     onTap: () => _pickImage("after"),
//                   ),
//                   _buildImageBox(
//                     label: "Vehicle",
//                     image: _imageVehicle,
//                     onTap: () => _pickImage("vehicle"),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 10),
//
//               _buildTextField(_billNo, "Bill No"),
//               _buildTextField(_vehicleNumber, "Vehicle Number"),
//               _buildTextField(_vehicleType, "Vehicle Type"),
//               _buildTextField(_pricePerLiter, "Price per Liter"),
//               _buildTextField(_liters, "Liters"),
//               _buildTextField(_project, "Project"),
//               _buildTextField(_vendor, "Vendor"),
//
//               const SizedBox(height: 10),
//
//               ElevatedButton(
//                 onPressed: _formSubmit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey.shade800,
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: const Text(
//                   "Submit",
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//
//               if (_fuelEntries.isNotEmpty)
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _fuelEntries.length,
//                   itemBuilder: (context, index) {
//                     final item = _fuelEntries[index];
//                     return Card(
//                       margin: const EdgeInsets.all(8),
//                       elevation: 2,
//                       child: ListTile(
//                         title: Text("Vehicle: ${item.vehicle_number}"),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text("Bill: ${item.bill_no}"),
//                             Text("Type: ${item.vehicle_type}"),
//                             Text("Liters: ${item.liters}"),
//                             Text("Price: ${item.price_per_liter}"),
//                             Text("Vendor: ${item.vendor}"),
//                           ],
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () {
//                             setState(() => _fuelEntries.removeAt(index));
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // 🔹 Image Box Widget
Widget _buildImageBox({
  required String label,
  required String? image,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: DottedBorder(
      color: Colors.grey,
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      dashPattern: const [6, 3],
      child: Container(
        height: 100,
        width: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.black54),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(base64Decode(image), fit: BoxFit.cover),
              ),
      ),
    ),
  );
}

//   // 🔹 Custom Text Field
//   Widget _buildTextField(TextEditingController controller, String hintText) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: TextFormField(
//         controller: controller,
//         validator: (value) =>
//         value == null || value.isEmpty ? "Required Field" : null,
//         decoration: InputDecoration(
//           hintText: hintText,
//           filled: true,
//           fillColor: Colors.grey.shade100,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//       ),
//     );
//   }
// }
