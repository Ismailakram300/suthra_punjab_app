import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PersonalInfoForm extends StatefulWidget {
  const PersonalInfoForm({super.key});

  @override
  State<PersonalInfoForm> createState() => _PersonalInforFormState();
}

class _PersonalInforFormState extends State<PersonalInfoForm> {
  @override
  final Map<String, List<String>> CountryMap = {
    "Pakistan": ["Lahore", "karachi", "Rawalpindi"],
    "India ": ["Dehli", "Mumbai", "Newyourk"],
    "Us": ["Washington dc", "New jerdy", "Midel town"],
  };
  String? selectedCountry;
  String? selectedCity;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Personal Infromation")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                label: Text("Name"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),

            TextFormField(
              decoration: InputDecoration(
                label: Text("Phone"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),

            TextFormField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SizedBox(height: 10),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                label: Text("Cnic"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text("Year"),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text("Day"),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text("Month"),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                suffixIcon: Icon(Icons.lock),
                label: Text("Password"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                suffixIcon: Icon(Icons.lock),
                label: Text("confrim Password"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Nationality",
                  ),
                  value: selectedCountry,
                  items: CountryMap[selectedCountry]!.map((city) {
                    return DropdownMenuItem(child: Text(city), value: city);
                  }).toList(),
                  onChanged: (value){
                    setState(() {
                      selectedCountry=value;

                    });
                  },
                ),
                SizedBox(width: 10,),
                DropdownButtonFormField<String>(
                    items: CountryMap.keys.map((country)
                    {
                      return DropdownMenuItem(child: Text(""),
                      value: country,);

                    }).toList(),
                    onChanged: (value){
                      setState(() {
                        selectedCountry=value;
                      });
                    })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
