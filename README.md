# Home Assistant Legacy

This is a jailbreak-oriented companion shell for iOS 4 through iOS 14. It is a
separate Objective-C application because the current Swift application and its
dependencies require iOS 16.4 or newer.

## What works

- Rootless or rootful installation without an Apple Developer membership.
- Home Assistant frontend in `WKWebView` on iOS 8+ and `UIWebView` on iOS 4-7.
- Native Home Assistant username/password authentication.
- Native two-factor code prompt for TOTP and notification MFA.
- Six-digit verification codes submit automatically when the final digit is entered.
- Expired access tokens renew automatically using each home's saved refresh token.
- Native iPhone 5 launch sizing prevents iOS 6 letterboxing.
- Native entity list that does not depend on the device web engine.
- Customizable My Devices view with a contextual + button and swipe-to-delete.
- Searchable All Devices view without add/remove controls.
- Compact native My Devices / All Devices selector that fits older navigation bars.
- Searchable Add Devices sheet, centered on iPad and sliding up on iPhone.
- Add Devices rows use a + control, and cameras open directly into their feed.
- Multiple saved homes with a native home switcher and last-used-home launch behavior.
- Standard UIKit controls retain each installed iOS version's native appearance.
- Separate legacy and modern SDK builds let UIKit provide era-correct system styling without runtime version checks.
- Native light, switch, cover, lock, scene, script, button and automation controls.
- Brightness and RGB color presets for compatible lights.
- Authenticated, continuously refreshed CCTV camera viewer.
- Responsive iPhone and iPad layouts.

## Important limits

- APNs requires an Apple-issued `aps-environment` entitlement and a matching
  server credential. A jailbreak does not bypass that server-side check.
- iOS suspends ordinary applications in the background. Endpoint polling is
  reliable while the app is open and opportunistic during a background task.
- Modern Home Assistant frontend JavaScript may not run in old `UIWebView`
  engines. A simple dashboard intended for old WebKit is recommended on iOS 4-7.
- Current TLS certificates/cipher suites may not work on iOS 4-8. Put a trusted
  reverse proxy with compatible TLS in front of Home Assistant rather than
  disabling certificate validation.

## Build

Install Theos, then build one package per ABI/OS family:

```sh
cd Legacy
make clean package ARCHS=armv7 TARGET=iphone:clang:9.3:4.0
make clean package ARCHS=arm64 TARGET=iphone:clang:16.5:7.0
# Dopamine/rootless jailbreaks:
make clean package THEOS_PACKAGE_SCHEME=rootless ARCHS=arm64 TARGET=iphone:clang:16.5:15.0
```

The first package covers armv7 devices where the available SDK/toolchain can
still deploy to iOS 4. The second covers arm64 devices on iOS 7-14. Very old
armv6 hardware requires an archived armv6-capable toolchain and is not supported
by contemporary Theos.

Install the generated `.deb` through Sileo, Zebra, Cydia, or `dpkg -i` over SSH.

## Unjailbroken device IPAs

The release also includes separate unsigned/resignable IPA files for 32-bit armv7
and 64-bit arm64 devices. Install the matching IPA with a sideloading tool that
signs it using your Apple account. A free Apple Personal Team profile expires
after seven days, so the app must then be signed and installed again. These IPAs
do not bypass Apple's code-signing or provisioning requirements.

## Configure

On first launch enter:

1. The externally reachable Home Assistant base URL.
The password is submitted directly to the selected Home Assistant instance using
its login-flow API and discarded when the flow finishes. Home Assistant returns
short-lived access and refresh tokens. The initial native dashboard lists entity
names and states without loading the JavaScript frontend.
