# Locheck

[![Swift 5.4](https://img.shields.io/badge/swift-5.4-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Build](https://github.com/stevelandeyasana/locheck/actions/workflows/tests.yml/badge.svg)](https://github.com/stevelandeyasana/locheck/actions/workflows/tests.yml)

An Xcode localization file validator. Make sure your `.strings` files do not have any errors!

## What does it do?

Locheck can perform two kinds of checks on `.strings` files.
1. A string appears in `Localizable.strings` for your base language but is missing elsewhere. This is a source of UI bugs.
2. A translated string uses incorrect arguments, for example a mismatched specifier or invalid position. This is a source of crashes:

Consider this string:

```swift
"Send %d donuts to %@" = "%@ to donuts %d send";
```

The translation reads naturally on its own, but this would crash your app when iOS tries to format a number as an Objective-C object and and Objective-C object as a number. Instead, it should look like this:

```swift
"Send %d donuts to %@" = "%1$@ to donuts %2$d send";
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

Other install methods may be added upon request as we discover people's needs.

## Usage

There are three ways to invoke `locheck` depending on how much magic you want.

### `discover`

The simplest way is to use `discover` and point to a directory containing all your `.lproj` files:

```sh
locheck discover "MyApp/Supporting Files" --default en # use English as the base language
```

If you use a language besides English as your base, you'll need to pass it as an argument as shown in the example. Locheck does not try to read your xcodeproj file to figure it out.

### `lproj`

You can pass a list of `lproj` files to `locheck lproj`, starting with the base language.

```sh
locheck lproj MyApp/en.lproj MyApp/fr.lproj
```

### `strings`

You can directly compare `.strings` files against each other. Again, pass the base language first, followed by the rest.

```sh
locheck xcstrings MyApp/en.lproj/Localizable.strings MyApp/fr.lproj/Localizable.strings
```

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
