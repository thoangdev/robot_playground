# Mobile Testing With AppiumLibrary

This project includes an opt-in Appium starter suite at
`tests/mobile/appium_smoke_tests.robot`. Normal local and CI runs stay fast
because mobile tests skip unless `RUN_MOBILE_TESTS=true`.

## Requirements

- Appium 2 server installed and running
- Android emulator, iOS simulator, or real device
- App under test available as an `.apk`, `.app`, `.ipa`, or installed package
- `robotframework-appiumlibrary` from `requirements.txt`

## Android

```bash
appium --base-path /

RUN_MOBILE_TESTS=true \
MOBILE_PLATFORM=android \
MOBILE_APPIUM_SERVER=http://127.0.0.1:4723 \
ANDROID_DEVICE_NAME="Android Emulator" \
ANDROID_APP=/absolute/path/to/app-debug.apk \
MOBILE_STARTUP_LOCATOR=accessibility_id=Home \
make test-mobile
```

Use `ANDROID_APP_PACKAGE` and `ANDROID_APP_ACTIVITY` instead of `ANDROID_APP`
when testing an already installed application.

## iOS

```bash
appium --base-path /

RUN_MOBILE_TESTS=true \
MOBILE_PLATFORM=ios \
MOBILE_APPIUM_SERVER=http://127.0.0.1:4723 \
IOS_DEVICE_NAME="iPhone 15" \
IOS_APP=/absolute/path/to/MyApp.app \
MOBILE_STARTUP_LOCATOR=accessibility_id=Home \
make test-mobile
```

Use `IOS_BUNDLE_ID` instead of `IOS_APP` when testing an already installed app.

## Adding Tests

Put reusable Appium keywords in `tests/resources/mobile.robot`, then add suites
under `tests/mobile/` with the `mobile` tag. Keep `Require Mobile Test
Environment` as the suite setup so device-dependent suites skip cleanly when a
developer or CI runner does not have Appium available.
