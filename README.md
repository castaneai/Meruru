# Meruru

A Simple [Mirakurun](https://github.com/Chinachu/Mirakurun)/[mirakc](https://github.com/mirakc/mirakc) Client for macOS.

![Meruru](Meruru.png)

## Requirements

- macOS v14+ (Sonoma)

## Build

You can build Meruru using [Swift Bundler](https://swiftbundler.dev/) in macOS environment.

```shell
swift build -c release
swift bundler bundle -o . -c release -u
cp -r .build/release/VLCKit.framework Meruru.app/Contents/Frameworks
open Meruru.app
```

## License

[Apache License, Version 2.0](LICENSE)
