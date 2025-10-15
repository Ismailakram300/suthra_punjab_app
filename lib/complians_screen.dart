import 'dart:convert';
import 'package:figma_practice_project/Services/complaints_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'complaint_details_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  String _selectedFilter = "pending";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    final complaints = await ComplaintServices.getComplaintsData();
    setState(() {
      _complaints = complaints;
      _filteredComplaints = complaints;
      _isLoading = false;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == "pending") {
        _filteredComplaints = _complaints;
      } else {
        _filteredComplaints = _complaints
            .where(
              (c) => (c["status"]?.toString().toLowerCase() ?? "").contains(
                filter.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Complaints"),
        backgroundColor: Colors.blue,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(value: "pending", child: Text("Pending")),
              const PopupMenuItem(value: "resolved", child: Text("Resolved")),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
          ? const Center(child: Text("No complaints assigned to you"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredComplaints.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final complaint = _filteredComplaints[index];
                      final base64Image = complaint["before_picture"];
                      ImageProvider? imageProvider;

                      if (base64Image != null && base64Image.isNotEmpty) {
                        try {
                          imageProvider = MemoryImage(
                            base64Decode(base64Image),
                          );
                        } catch (e) {
                          imageProvider = const AssetImage('assets/error.png');
                        }
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ComplaintDetailsScreen(complaint: complaint),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: imageProvider != null
                                ? CircleAvatar(
                                    //borderRadius: BorderRadius.circular(10),
                                    child: Image(
                                      image: imageProvider,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            title: Text(
                              "Complaint ID: ${complaint["id"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            subtitle: complaint.containsKey("status")
                                ? Text("Status: ${complaint["status"]}")
                                : null,
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: [
                              if (imageProvider != null)
                                // ClipRRect(
                                //   borderRadius: BorderRadius.circular(10),
                                //   child: Image(
                                //     image: imageProvider,
                                //     height: 180,
                                //     width: double.infinity,
                                //     fit: BoxFit.cover,
                                //   ),
                                // ),
                              const SizedBox(height: 10),
                              if (complaint.containsKey("address"))
                                Text(
                                  "Description: ${complaint["address"]}",
                                ),
                              if (complaint.containsKey("name"))
                                Text(
                                  "Assigned by: ${complaint["name"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              if (complaint.containsKey("number"))
                                Text(
                                  "Phone no: ${complaint["number"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              if (complaint.containsKey("tehsil_name"))
                                Text(
                                  "Tehsil: ${complaint["tehsil_name"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              if (complaint.containsKey("created_at"))
                                Text(
                                  "Created at: ${complaint["created_at"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Here we go Again",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
    );
  }
}
