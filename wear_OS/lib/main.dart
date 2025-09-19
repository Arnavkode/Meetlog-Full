import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:is_wear/is_wear.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear/wear.dart';

late final bool isWear;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  isWear = (await IsWear().check()) ?? false;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WatchConnectivityBase _watch;

  var _supported = false;
  var _paired = false;
  var _reachable = false;
  var _context = <String, dynamic>{};
  var _receivedContexts = <Map<String, dynamic>>[];
  final _log = <String>[];
  bool isBLE = false;

  Timer? timer;

  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  UserAccelerometerEvent? _userAccelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;
  StreamSubscription<AccelerometerEvent>? _accelerometerStream;
  StreamSubscription<GyroscopeEvent>? _gyroscopeStream;
  StreamSubscription<MagnetometerEvent>? _magnetometerStream;
  StreamSubscription<UserAccelerometerEvent>? _useraccelerometerStream;

  @override
  void initState() {
    super.initState();
    _watch = WatchConnectivity();
    _watch.messageStream
        .listen((e) => setState(() => _log.add('Received message: $e')));
    initPlatformState();

    _accelerometerStream =
        accelerometerEventStream(samplingPeriod: Duration(milliseconds: 100))
            .listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerEvent = event;
      });
    });

    _useraccelerometerStream = userAccelerometerEventStream(
            samplingPeriod: Duration(milliseconds: 100))
        .listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerEvent = event;
      });
    });

    _gyroscopeStream =
        gyroscopeEventStream(samplingPeriod: Duration(milliseconds: 100))
            .listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeEvent = event;
      });
    });

    _magnetometerStream =
        magnetometerEventStream(samplingPeriod: Duration(milliseconds: 100))
            .listen((MagnetometerEvent event) {
      setState(() {
        _magnetometerEvent = event;
      });
    });
  }

  @override
  void dispose() {
    _useraccelerometerStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();
    _magnetometerStream?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void initPlatformState() async {
    _supported = await _watch.isSupported;
    _paired = await _watch.isPaired;
    _reachable = await _watch.isReachable;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final home = Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Supported: $_supported'),
                  Text('Paired: $_paired'),
                  Text('Reachable: $_reachable'),
                  TextButton(
                    onPressed: initPlatformState,
                    child: const Text('Refresh'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Send'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: toggleBackgroundMessaging,
                        child: Text(
                          '${timer == null ? 'Start' : 'Stop'} background messaging',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                      'user Accelerometer: ${_userAccelerometerEvent?.toString()}'),
                  Text(
                      'Accelerometer: ${_accelerometerEvent?.toString()}'),
                  Text('Gyroscope: ${_gyroscopeEvent?.toString()}'),
                  Text('Magnetometer: ${_magnetometerEvent?.toString()}'),
                  const Text('Log'),
                  Text(isBLE
                      ? "BLE Peripheral is active"
                      : "BLE Peripheral is inactive"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ListView(
                          shrinkWrap: true,
                          children:
                              _log.reversed.map((log) => Text(log)).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return MaterialApp(
      home: isWear
          ? AmbientMode(
              builder: (context, mode, child) => child!,
              child: home,
            )
          : home,
    );
  }

  void toggleBackgroundMessaging() {
    if (timer == null) {
      timer = Timer.periodic(
          const Duration(milliseconds: 100), (_) => sendMessage());
    } else {
      timer?.cancel();
      timer = null;
    }
    setState(() {});
  }

  void sendMessage() {
    final message = {
      'Timestamp': DateTime.now().toIso8601String(),
      'accelerometer': {
        'x': _accelerometerEvent?.x,
        'y': _accelerometerEvent?.y,
        'z': _accelerometerEvent?.z,
      },
      // 'accelerometer': {
      //   'x': _userAccelerometerEvent?.x,
      //   'y': _userAccelerometerEvent?.y,
      //   'z': _userAccelerometerEvent?.z,
      // },
      'gyroscope': {
        'x': _gyroscopeEvent?.x,
        'y': _gyroscopeEvent?.y,
        'z': _gyroscopeEvent?.z,
      },
      'magnetometer': {
        'x': _magnetometerEvent?.x,
        'y': _magnetometerEvent?.y,
        'z': _magnetometerEvent?.z,
      }
    };
    _watch.sendMessage(message);
    // setState(() => _log.add('Sent message: $message'));
  }
}
