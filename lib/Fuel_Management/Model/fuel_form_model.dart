class FuelEntries {
  final String bill_no;
  final String vehicle_type;
  final String vehicle_number;
  final String liters;
  final String price_per_liter;
  final String project;
  final String vendor;
  final String timestamp;
  final String beforeImage;
  final String afterImage;
  final String vehcileImage;

  FuelEntries({
    required this.bill_no,
    required this.vehicle_type,
    required this.vehicle_number,
    required this.liters,
    required this.price_per_liter,
    required this.project,
    required this.vendor,
    required this.beforeImage,
    required this.afterImage,
    required this.vehcileImage,
    String? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toIso8601String();
  Map<String, dynamic> toMap() {
    return {
      'BILL_NO': bill_no,
      'VEHICLE_TYPE': vehicle_type,
      'VEHICLE_NUMBER': vehicle_number,
      'LITERS': liters,
      'PRICE_PER_LITRE': price_per_liter,
      'PROJECT': project,
      'Vendor': vendor,
      'timestamp': timestamp,
      'beforeImage': beforeImage,
      'afterImage': afterImage,
      'vehcileImage': vehcileImage,
    };
  }

  factory FuelEntries.fromMap(Map<String, dynamic> map) {
    return FuelEntries(
      bill_no: map["bill_no"],
      vehicle_type: map["vehicle_type"],
      vehicle_number: map["vehicle_number"],
      liters: map["liters"],
      price_per_liter: map["price_per_liter"],
      project: map["project"],
      vendor: map["vendor"],
      beforeImage: map['beforeImage'],
      afterImage: map['afterImage'],
      vehcileImage: map['vehcileImage'],
    );
  }
}
