# Locheck

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
locheck strings MyApp/en.lproj/Localizable.strings MyApp/fr.lproj/Localizable.strings
```
