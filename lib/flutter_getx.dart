import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FlutterGetx extends StatelessWidget {
  const FlutterGetx({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text("Hello World"),
      ),

      body:  Column(
        children: [
          Card(
            child: ListTile(
              title: Text("Dialog"),
              subtitle: Text("this ne ttouilr"),
              onTap: (){
                Get.defaultDialog(
                  title: "Delete Alert",
                  middleText: "",
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
Get.snackbar("Error", "");
      }),
    );
  }
}
