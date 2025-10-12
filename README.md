# tim

A new Flutter plugin project.

## Getting Started

This repository consumes native binaries produced by the private
`tim_frb` project. The compiled artifacts are published to the public
repository [`mobius-toy/tim_artifacts`](https://github.com/mobius-toy/tim_artifacts)
and are downloaded automatically during the build.

## Native artifact workflow

### Android

The Gradle build reads `timFrbVersion` from `android/gradle.properties` and
downloads `tim_frb-artifacts-v<version>.zip` during the `preBuild` phase. The
extracted `.so` files are placed under `android/build/timFrb/jniLibs` and wired
into the `jniLibs` source set automatically. To update to a new release, bump
`timFrbVersion` and rebuild.

### iOS / macOS

Both `ios/tim.podspec` and `macos/tim.podspec` download the published static
library during `pod install`. By default they use the same version (`0.1.0`),
but you can override it via the `TIM_FRB_VERSION` environment variable:

```bash
TIM_FRB_VERSION=0.1.0 pod install
```

The prepare step creates `Frameworks/libtim_frb.a` (for iOS it merges device
and simulator slices using `lipo`) and registers it as a vendored library.

### Development workflow

1. Update `tim_frb` and publish a new artifact archive to
   `mobius-toy/tim_artifacts` (e.g. `v0.1.1`).
2. Adjust `android/gradle.properties#timFrbVersion` and optionally set
   `TIM_FRB_VERSION` when running `pod install`.
3. Run `flutter pub get` and build as usual; Gradle/Pods will fetch the
   required binaries automatically.

## Further reading

For general Flutter plugin guidance, see the
[Flutter plugin documentation](https://docs.flutter.dev/packages-and-plugins/plugin).
