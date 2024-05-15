import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

void main() {
  runApp(TemperatureGraphApp());
}

class TemperatureGraphApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Temperature Graph'),
        ),
        body: TemperatureGraphForm(),
      ),
    );
  }
}

class TemperatureGraphForm extends StatefulWidget {
  @override
  _TemperatureGraphFormState createState() => _TemperatureGraphFormState();
}

class _TemperatureGraphFormState extends State<TemperatureGraphForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final String devId = "00000000000000bb"; // Read-only value
  List<DataPoint> dataPoints = [];
  bool isLoading = false; // Variable to track loading state

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: TextEditingController(text: devId),
                  readOnly: true,
                  style: TextStyle(color: Colors.grey),
                  decoration: InputDecoration(labelText: 'Device ID'),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateFromController,
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a from date';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'From Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2015, 8),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _dateFromController.text =
                                '${picked.year}-${_formatDateComponent(picked.month)}-${_formatDateComponent(picked.day)} ${time.hour}:${time.minute}:00';
                              });
                            }
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _dateToController,
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a to date';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'To Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2015, 8),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                _dateToController.text =
                                '${picked.year}-${_formatDateComponent(picked.month)}-${_formatDateComponent(picked.day)} ${time.hour}:${time.minute}:00';
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Form is valid, now you can submit it
                      fetchData();
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
          if (isLoading) // Show loader if loading
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (dataPoints.isNotEmpty) ...[
            SizedBox(height: 20),
            Expanded(
              child: TemperatureChart(dataPoints: dataPoints),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });

    final String endpoint = 'https://airsense.site/databydevid'; // Define API endpoint

    final Map<String, dynamic> requestData = {
      'dev_id': devId,
      'dateFrom': _dateFromController.text,
      'dateTo': _dateToController.text,
    }; // Define request data

    final Uri uri = Uri.parse(endpoint); // Parse endpoint URI

    try {
      final http.Response response = await http.post( // Make POST request
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode([requestData]),
      );

      if (response.statusCode == 200) {
        // Successfully fetched data, you can process it here
        final List<dynamic> jsonData = jsonDecode(response.body); // Decode response body
        List<DataPoint> fetchedDataPoints = [];
        for (var data in jsonData) {
          fetchedDataPoints.add(DataPoint.fromJson(data)); // Add fetched data points
        }
        // Now you can pass the fetched data to the chart or any other widget
        setState(() {
          dataPoints = fetchedDataPoints; // Update data points
          isLoading = false; // Set loading state to false
        });
      } else {
        throw Exception('Failed to fetch data'); // Throw exception for failed request
      }
    } catch (error) {
      print('Error fetching data: $error'); // Print error message
      // Handle error appropriately, such as displaying an error message to the user
      setState(() {
        isLoading = false; // Set loading state to false
      });
    }
  }

  String _formatDateComponent(int component) {
    return component.toString().padLeft(2, '0'); // Format date component
  }
}

class DataPoint {
  final DateTime time; // Define time property
  final double temperature; // Define temperature property
  final double humidity; // Define humidity property
  final int co2; // Define CO2 property
  final double batteryLevel; // Define battery level property

  DataPoint({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.batteryLevel,
  }); // Constructor

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      time: DateTime.parse(json['datetime']), // Parse time from JSON
      temperature: json['temp'].toDouble(), // Parse temperature from JSON
      humidity: json['humidity'].toDouble(), // Parse humidity from JSON
      co2: json['co2'], // Parse CO2 from JSON
      batteryLevel: json['batt'].toDouble(), // Parse battery level from JSON
    );
  } // Factory method to create DataPoint object from JSON
}

class TemperatureChart extends StatelessWidget {
  final List<DataPoint> dataPoints; // Define data points property

  TemperatureChart({required this.dataPoints}); // Constructor

  LineTooltipItem _getTooltipItem(String text) {
    return LineTooltipItem(
      text,
      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  } // Method to get tooltip item

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) return Container(); // Return empty container if dataPoints is empty

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 300,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Temperature vs Humidity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Temperature (°C)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints.map((dataPoint) {
                            return FlSpot(
                                dataPoint.humidity, dataPoint.temperature);
                          }).toList(),
                          isCurved: true,
                          colors: [Colors.blue],
                          barWidth: 2,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (double value) => const TextStyle(
                              color: Colors.black, fontSize: 12),
                          getTitles: (value) => '$value%', // Adjust label to display humidity
                          margin: 8,
                          reservedSize: 30,
                          interval: 10,
                        ),
                        leftTitles: SideTitles(
                          showTitles: true,
                          getTextStyles: (double value) => const TextStyle(
                              color: Colors.black, fontSize: 12),
                          getTitles: (value) => '$value°C', // Adjust label to display temperature
                          margin: 8,
                          reservedSize: 30,
                          interval: 5,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 0.5),
                      ),
                      minX: dataPoints
                          .map((e) => e.humidity)
                          .reduce((a, b) => min(a, b)), // Fix min calculation
                      maxX: dataPoints
                          .map((e) => e.humidity)
                          .reduce((a, b) => max(a, b)), // Fix max calculation
                      minY: dataPoints
                          .map((e) => e.temperature)
                          .reduce((a, b) => min(a, b)), // Fix min calculation
                      maxY: dataPoints
                          .map((e) => e.temperature)
                          .reduce((a, b) => max(a, b)), // Fix max calculation
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blueAccent,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final dataPoint =
                              dataPoints[barSpot.x.toInt()];
                              return LineTooltipItem(
                                'Temperature: ${dataPoint.temperature}°C\n'
                                    'Humidity: ${dataPoint.humidity.toInt()}%\n'
                                    'CO2: ${dataPoint.co2}\n'
                                    'Battery Level: ${dataPoint.batteryLevel}V',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Humidity (%)',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
