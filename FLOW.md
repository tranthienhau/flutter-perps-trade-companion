# Regenerating screenshots and demo GIFs

## Screenshots (iOS simulator)

```sh
xcrun simctl boot "iPhone 17 Pro"
flutter pub get
flutter drive \
  --driver test_driver/integration_test.dart \
  --target integration_test/screenshot_test.dart \
  -d "iPhone 17 Pro"
```

How it works:
- `test_driver/integration_test.dart` uses `integrationDriver(onScreenshot:)` to write each PNG into `screenshots/`.
- `integration_test/screenshot_test.dart` runs the real app, freezes the price feed and walks `demoSteps()` from
  `lib/demo/autopilot.dart` (the same script the demo recording uses). It calls `binding.convertFlutterSurfaceToImage()`
  once, then `binding.takeScreenshot()` per step, with fixed `pump(Duration)` so the live ticker never blocks a frame.
- The demo clock is fixed (`kNow` in `lib/data/mock_data.dart`); steps move it forward to show the 5-day warning and expiry.
- Captures are downscaled 50% and compressed with `pngquant --quality 75-92` before committing.

## Demo GIFs

`--dart-define=DEMO=true` walks the whole flow hands-free (about 32 s) after launch.

iOS:

```sh
flutter build ios --simulator --debug --dart-define=DEMO=true
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl io booted recordVideo --codec h264 --force /tmp/ios-demo.mp4 &
xcrun simctl launch booted com.tranthienhau.dispatchTrade
# wait ~45 s, then Ctrl-C the recorder
ffmpeg -y -ss 2 -i /tmp/ios-demo.mp4 -vf "fps=10,tpad=stop_mode=clone:stop_duration=2.5" /tmp/ios-trim.mp4
```

Android:

```sh
emulator -avd Medium_Phone_API_36.2 &
flutter build apk --release --dart-define=DEMO=true
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 shell screenrecord --time-limit 44 --size 540x1200 /sdcard/ademo.mp4 &
adb -s emulator-5554 shell am start -n com.tranthienhau.dispatch_trade/.MainActivity
sleep 46 && adb -s emulator-5554 pull /sdcard/ademo.mp4 /tmp/ademo.mp4
```

Convert (10 fps, 280 px, 96 colours keeps each GIF under 3 MB):

```sh
ffmpeg -y -i in.mp4 -vf "fps=10,scale=280:-1:flags=lanczos,palettegen=max_colors=96:stats_mode=diff" /tmp/pal.png
ffmpeg -y -i in.mp4 -i /tmp/pal.png -lavfi "fps=10,scale=280:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" screenshots/demo.gif
```
