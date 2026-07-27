# ThreejsNative SDK

Immutable public distribution for ThreejsNative SDK `1.0.1`.

## Web

```json
{"dependencies": {"@threejsnative/tjn-web": "https://github.com/spawn66336/threejsnative-sdk/releases/download/1.0.1/tjn-web-1.0.1.tgz"}}
```

## Android

```kotlin
repositories {
    maven { url = uri("https://spawn66336.github.io/threejsnative-sdk/maven") }
}
dependencies {
    implementation("dev.threejsnative:tjn-engine:1.0.1")
}
```

## Apple

```swift
.package(
    url: "https://github.com/spawn66336/threejsnative-sdk.git",
    exact: "1.0.1"
)
```

## Windows

Download `tjn-engine-windows-<arch>-1.0.1.zip`, verify the SHA-256 from
the release manifest, and use `find_package(TjnEngine CONFIG REQUIRED)`.

Release manifest SHA-256: `e7e19eb5de5cd75ab4a79ca1dc6051efe05850bcc9699468ccbb4693b09a859d`. Do not use branch URLs,
`releases/latest/download`, Actions artifacts, or dynamic version selectors.
