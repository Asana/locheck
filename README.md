# Locheck

[![Swift 5.4](https://img.shields.io/badge/swift-5.4-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Build](https://github.com/stevelandeyasana/locheck/actions/workflows/tests.yml/badge.svg)](https://github.com/stevelandeyasana/locheck/actions/workflows/tests.yml)

An Xcode and Android localization file validator. Make sure your `.strings`, `.stringsdict`, and `strings.xml` files do not have any errors!

## What does it do?

Locheck can perform many kinds of checks on localization files. The simplest one is making sure all strings appear in both the base language and translations, but it can also make sure all your format specifiers are consistent, even in `.stringsdict` files.

Consider this string:

```swift
"Send %d donuts to %@" = "%@ to donuts %d send";
```

```xml
<!-- values/strings.xml -->
<string name="send_donuts">Send %d donuts to %s</string>
<!-- values-translation/strings.xml -->
<string name="send_donuts">%s to donuts %d send</string>
```

The translation reads naturally on its own, but this would crash your app when iOS or Android tries to format a number as a string and a string as a number. Instead, the translation should look like this:

```swift
"Send %d donuts to %@" = "%1$@ to donuts %2$d send";
```

```xml
<!-- values-translation/strings.xml -->
<string name="send_donuts">%2$s to donuts %1$d send</string>
```

Locheck will make sure you get it right.

In the example above, the key happens to be equal to the base translation. But you might have special cases where you manually define your string in `Localizable.strings`, so the key's format string doesn't match the value:

```swift
// in en.lproj/Localizable.strings:
"send-donuts" = "Send %d donuts to %@";

// in backwards.lproj/Localizable.strings:
"send-donuts" = "%@ to donuts %d send";
```

In these cases, Locheck will use the base translation's _value_ (not its key) as the authoritative string, and would catch the error in the example above.

## Installation

### Using [Mint](https://github.com/yonaskolb/Mint)

```sh
mint install Asana/locheck
mint run locheck [...]

# or link it to /usr/local/bin
mint install Asana/locheck --link
locheck [...]
```

Other install methods may be added upon request as we discover people's needs. This project is very new and setting up new installation methods takes time.

## Usage

There are a few ways to invoke `locheck` depending on how much magic you want. In all cases, Locheck will write to stderr for Xcode integration, and stdout for a human-readable summary. Pull requests for additional output formats will probably be accepted.

### `discoverlproj`

The simplest way to use Locheck with Xcode is to use `discoverlproj` and point to a directory containing all your `.lproj` files:

```sh
locheck discoverlproj "MyApp/Supporting Files" --default en # use English as the base language
```

If you use a language besides English as your base, you'll need to pass it as an argument as shown in the example. Locheck does not try to read your xcodeproj file to figure it out.

### `discovervalues`

The simplest way to use Locheck on Android is to use `discovervalues` and point to a directory containing all your `values[-*]` directories, i.e. your `res/` directory.

```sh
locheck discovervalues ./commons/src/main/res
```

### Other ways

Run `locheck --help` to see a list of all commands. The rest of the commands just let you directly compare individual files of different types.

## Example output

## Contributing

GitHub issues and pull requests are very welcome! Please format your code with `swiftformat Sources Tests` before opening your PR, otherwise tests will fail and we cannot merge your branch. We also run SwiftLint to help ensure best practices.

The simplest way to install SwiftFormat and SwiftLint is to use [Mint](https://github.com/yonaskolb/Mint): 

```sh
brew install mint
mint bootstrap --link`
```

You can then run both tools locally:

```sh
swiftformat Sources Tests
swiftlint lint --quiet
```

## Further reading

- [Localizing Strings that Contain Plurals](https://developer.apple.com/documentation/xcode/localizing-strings-that-contain-plurals)
- [Stringsdict File Format](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html)
