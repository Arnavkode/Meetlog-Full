library globals;

import 'dart:async';

import 'package:wear_os/esenseconnect.dart';

String currentActivity = "Not Selected";

bool pages = false;
bool isEsenseConnected = false;
bool isSmartwatchConnected = false;

bool stop = false;

String devicenm = "none";
List<String> options = [];
List<String> activity = [];
Map<String, bool> values = {};

List<dynamic> currentData = [];

List<dynamic> times = [];
List<dynamic> etimes = [];
List<dynamic> datalist = [];


List<dynamic> datalistesense = [];

// StreamController<List<dynamic>> _datalistStreamController =
//     StreamController<List<dynamic>>.broadcast();
// Stream<List<dynamic>> get datalistStream => _datalistStreamController.stream;

// void updateDatalist(List<dynamic> newData) {
//   _datalistStreamController.add(datalist);
// }




// StreamController<List<dynamic>> _EdatalistStreamController =
//     StreamController<List<dynamic>>.broadcast();
// Stream<List<dynamic>> get EdatalistStream => _EdatalistStreamController.stream;

// void EupdateDatalist(List<dynamic> newData) {
//   _EdatalistStreamController.add(datalistesense);
// }

// StreamController<Map<String, dynamic>> _watchDataStreamController =
//     StreamController<Map<String, dynamic>>.broadcast();
// Stream<Map<String, dynamic>> get watchDataStream => _watchDataStreamController.stream;

// void updateWatchData(Map<String, dynamic> data) {
//   _watchDataStreamController.add(data);
// }

// void dispose() {
//   _datalistStreamController.close();
//   _EdatalistStreamController.close();
//   _watchDataStreamController.close(); // Added for watch data stream
// }

Timer? datalistUpdateTimer;

// void startDatalistUpdates() {
//   datalistUpdateTimer?.cancel(); // Cancel if already running
//   datalistUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
//     updateDatalist(datalist);
//   });
// }

void stopDatalistUpdates() {
  datalistUpdateTimer?.cancel();
  datalistUpdateTimer = null;
}





// NEW IMPLEMENT

String? Model;

Map<String, dynamic> globallatestWatchData = {};
List<dynamic> gloaballatestEsenseData = [];

void globalupdateWatchData(Map<String, dynamic> data){ 
  globallatestWatchData = data;
}

final _EsensestreamController = StreamController<List<dynamic>>();



    Stream<List<dynamic>>  get globalEsensestream => _EsensestreamController.stream;


void globalupdateEsenseStream(List<dynamic> esenseEvent){
  _EsensestreamController.add(esenseEvent);
}
