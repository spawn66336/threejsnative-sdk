# ThreejsNative SDK

Immutable public distribution for ThreejsNative SDK `1.0.0`.

## Web

```json
{"dependencies": {"@threejsnative/tjn-web": "https://github.com/spawn66336/threejsnative-sdk/releases/download/1.0.0/tjn-web-1.0.0.tgz"}}
```

## Android

```kotlin
repositories {
    maven { url = uri("https://spawn66336.github.io/threejsnative-sdk/maven") }
}
dependencies {
    implementation("dev.threejsnative:tjn-engine:1.0.0")
}
```

## Apple

```swift
.package(
    url: "https://github.com/spawn66336/threejsnative-sdk.git",
    exact: "1.0.0"
)
```

## Windows

Download `tjn-engine-windows-<arch>-1.0.0.zip`, verify the SHA-256 from
the release manifest, and use `find_package(TjnEngine CONFIG REQUIRED)`.

Release manifest SHA-256: `8946b7c32d69510b9ad17181be0f1dac88b27dba3fdb830b17f8cb67ee829b39`. Do not use branch URLs,
`releases/latest/download`, Actions artifacts, or dynamic version selectors.
