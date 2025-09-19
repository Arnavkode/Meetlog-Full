import 'dart:collection';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flame/components.dart' as flame;
import 'package:esense_flutter/esense.dart';
import 'package:ditredi/ditredi.dart' as ditredi;
import 'package:vector_math/vector_math_64.dart' as v64;

import 'package:wear_os/esense/device.dart';
import 'package:wear_os/globals/connection.dart' as g;
import 'package:wear_os/esense_graph.dart';
import 'package:wear_os/globals.dart' as globals;
import 'package:wear_os/math/remap.dart';
import 'package:wear_os/util/callback.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});
  @override
  CalibrationScreenState createState() => CalibrationScreenState();
}

class CalibrationScreenState extends State<CalibrationScreen> {
  static const int _maxLen = 60 * 1;
  static final _calibrationColorLeft = Colors.orange.withAlpha(180);
  static final _calibrationColorRight = Colors.yellow.withAlpha(180);
  static final v64.Aabb3 _bounds = v64.Aabb3.minMax(
    v64.Vector3(-1, -1, -1),
    v64.Vector3(1, 1, 1),
  );
  static const _accelColor = Colors.purple;

  var _lastAccels = ListQueue<v64.Vector3>(_maxLen);
  var _lastGyros = ListQueue<v64.Vector3>(_maxLen);
  var _deviceState = g.device.state;

  v64.Vector3? _calibrateLeft = g.angler.calibrateLeft != null
      ? v64.Vector3(g.angler.calibrateLeft!.x, g.angler.calibrateLeft!.y,
          g.angler.calibrateLeft!.z)
      : null;

  v64.Vector3? _calibrateRight = g.angler.calibrateRight != null
      ? v64.Vector3(g.angler.calibrateRight!.x, g.angler.calibrateRight!.y,
          g.angler.calibrateRight!.z)
      : null;

  final _controllerFront = ditredi.DiTreDiController(
    rotationX: -90,
    rotationY: 90,
    rotationZ: 0,
    userScale: 1.8,
    minUserScale: 1.5,
    maxUserScale: 3,
  );

  Closer? _sensorCallbackCloser;
  Closer? _stateCallbackCloser;

  List liss = [];

  @override
  void initState() {
    super.initState();

    _stateCallbackCloser = g.device.registerStateCallback((state) {
      if (state == _deviceState) return;
      setState(() {
        _deviceState = state;
        if (state != DeviceState.initialized) {
          _lastAccels = ListQueue<v64.Vector3>(_maxLen);
          _lastGyros = ListQueue<v64.Vector3>(_maxLen);
        }
      });
    });

    _sensorCallbackCloser = g.device.registerSensorCallback((event) {
      final gyroScale = g.device.deviceConfig?.gyroRange?.sensitivityFactor;
      final accelScale = g.device.deviceConfig?.accRange?.sensitivityFactor;
      if (gyroScale == null || accelScale == null) return;

      liss = [
        DateTime.now().millisecondsSinceEpoch,
        event.accel?[0],
        event.accel?[1],
        event.accel?[2],
        event.gyro?[0],
        event.gyro?[1],
        event.gyro?[2],
      ];
      globals.gloaballatestEsenseData = liss;
      globals.globalupdateEsenseStream(liss);
      globals.datalistesense.add(liss + globals.activity);
      globals.etimes.add(DateTime.now().millisecondsSinceEpoch);
      var gyro = event.gyro != null
          ? v64.Vector3.array(event.gyro!.map((e) => e.toDouble()).toList())
          : null;
      var accel = event.accel != null
          ? v64.Vector3.array(event.accel!.map((e) => e.toDouble()).toList())
          : null;

      if (gyro == null || accel == null) return;

      setState(() {
        if (_lastGyros.length > _maxLen) _lastGyros.removeFirst();
        if (_lastAccels.length > _maxLen) _lastAccels.removeFirst();
        _lastGyros.addLast(gyro / gyroScale);
        _lastAccels.addLast(accel / accelScale);
      });
    });
  }

  @override
  void dispose() {
    _sensorCallbackCloser?.call();
    _stateCallbackCloser?.call();
    globals.datalistUpdateTimer?.cancel();
    super.dispose();
  }

  List<ditredi.Point3D> _generateAccelPoints() {
    final len = _lastAccels.length;
    return _lastAccels.mapIndexed((v, i) {
      final alpha = (i / len).remap(0, 1, 0, 150).floor();
      return ditredi.Point3D(v, width: 2, color: _accelColor.withAlpha(alpha));
    }).toList();
  }

  List<ditredi.Line3D> _generateAccelLine() {
    if (_lastAccels.isEmpty) return [];
    return [
      ditredi.Line3D(
        v64.Vector3.zero(),
        _lastAccels.last,
        width: 2,
        color: _accelColor,
      )
    ];
  }

  List<ditredi.Line3D> _generateCalibrationLines() {
    final zero = v64.Vector3.zero();
    var buffer = <ditredi.Line3D>[];

    if (_calibrateLeft != null) {
      buffer.add(ditredi.Line3D(
        zero,
        _calibrateLeft!.normalized(),
        width: 2,
        color: _calibrationColorLeft,
      ));
    }

    if (_calibrateRight != null) {
      buffer.add(ditredi.Line3D(
        zero,
        _calibrateRight!.normalized(),
        width: 2,
        color: _calibrationColorRight,
      ));
    }

    return buffer;
  }

  Future<void> _generateCsvFile() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final csvData =
        globals.datalistesense.map((list) => list.join(',')).join('\n');
    final csvString = 'x,y,z\n$csvData';

    String directory;
    if (Platform.isIOS) {
      final dir = await getDownloadsDirectory();
      directory = dir?.path ?? '/';
    } else {
      final dir1 = Directory("/storage/emulated/0/Download/");
      final dir2 = Directory("/storage/emulated/0/Downloads/");
      directory = await dir1.exists() ? dir1.path : dir2.path;
    }

    final file = File('$directory/dataensense.csv');
    await file.writeAsString(csvString);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('CSV file saved in downloads as dataensense.csv')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _generateAccelPoints();
    final figures = <ditredi.Model3D>[
      ditredi.PointPlane3D(2, ditredi.Axis3D.y, 0.1, v64.Vector3.zero()),
      ...points,
      ..._generateAccelLine(),
      ..._generateCalibrationLines(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 200,
            color: Colors.blueGrey,
            child: ditredi.DiTreDiDraggable(
              controller: _controllerFront,
              child: ditredi.DiTreDi(
                bounds: _bounds,
                config: const ditredi.DiTreDiConfig(),
                figures: figures,
                controller: _controllerFront,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("To generate the CSV click below:"),
                  const SizedBox(height: 10),
                  Text(liss.toString(),
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _generateCsvFile,
                      child: const Text('Generate CSV'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => EGraphs()));
                    },
                    child: const Text('Graphs'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
