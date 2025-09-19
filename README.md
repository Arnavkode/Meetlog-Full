## Components

### 1. **WearOS Watch App**
- Collects IMU sensor data at 10Hz
- Streams to phone using `wear_connectivity` package

### 2. **eSense BLE Peripheral**
- Sends high-fidelity IMU data to mobile via BLE
- Managed using `flutter_blue_plus` and custom buffer logic

### 3. **Mobile Client App (Flutter)**
- Buffers both data streams
- Aligns timestamps using a dynamic matching strategy
- Forms a feature vector for model input
- Runs ONNX model locally for classification
- Logs predictions and transmits attention state to server

### 4. **Flask Backend**
- Handles `/attention` and `/attention-poke` endpoints
- Maintains attention state counters per userID
- Provides analytics and logging support

## Machine Learning
- Trained XGBoost model converted to ONNX for deployment
- Windowed classification using buffered sensor data
- Dynamic thresholding applied to suppress uncertain predictions

## Optimizations
- Reduced app RAM usage from ~600MB to ~250MB
- Decreased payload size by 50% with poke-based server hits
- Eliminated latency from server by moving inference on-device
- Fixed memory leaks from uncapped sensor listeners and excessive logs

## Usage
1. Install WearOS app on smartwatch
2. Install mobile app on Android phone
3. Pair and start eSense device
4. Start data stream from both devices
5. Real-time predictions and logs are saved locally and optionally sent to server


