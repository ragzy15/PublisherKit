# Publisher Kit

![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-333333.svg)
![Languages](https://img.shields.io/badge/languages-swift-orange.svg)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

## Overview

PublisherKit provides a declarative Swift API for processing asynchronous events over time. It is an open source version of Apple’s Combine Framework with many other additions.

The goal of this project is to provide a compatible, reliable and efficient implementation of Combine Framework that can be used on Apple’s operating systems older than macOS 10.15, iOS 13, tvOS 13 and watchOS 6.

To know more about Combine Framework, refer to Apple's Documentation [here](https://developer.apple.com/documentation/combine).

## Supported Platforms

* Xcode 11 and above

### Deployment Targets

* iOS 8 and above
* macOS (OS X) 10.10 and above
* tvOS 9 and above
* watchOS 3 and above

## Installation

### Swift Package Manager

To integrate PublisherKit into your project using [Swift Package Manager](https://swift.org/package-manager/), you can add the library as a dependency in Xcode (11 and above) – see the [docs](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). The package repository URL is:

```bash
https://github.com/ragzy15/PublisherKit.git
```

Alternatively, you can add PublisherKit as a dependency in your `Package.swift` file. For example:

```swift
// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YourPackage",
    products: [
        .library(
            name: "YourPackage",
            targets: ["YourPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ragzy15/PublisherKit.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "YourPackage",
            dependencies: ["PublisherKit"]),
    ]
)
```

You can install by using swift package manager built into Xcode or clone the repository and add a sub project into your project.

## Usage

```swift
searchTextField.textDidChangePublisher
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .compactMap { (text) -> String? in
        text.isEmpty ? nil : text
    }
    .removeDuplicates()
    .flatMap { (text) -> AnyPublisher<SearchResults, Never> in
        self.search(with: text)
    }
    .receive(on: DispatchQueue.main)
    .sink { (results) in
        print(results)
    }
    .store(in: &cancellables)

```
There is also a demo project included.

## Communication

* Please open an issue if you find a bug or have a feature request.
* Please submit a pull request if you would like to contribute (some tests would be nice).

Thanks ;)
