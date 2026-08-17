// swift-tools-version: 6.0
import Foundation
import PackageDescription

// Hand-authored SPM manifest for React Native's experimental SwiftPM support
// (RN 0.87, "Preview" — see scripts/spm/__doc__/spm-scripts.md in react-native).
// This is a direct translation of `op-s2.podspec`, which CocoaPods evaluates
// as Ruby during `pod install`. SwiftPM evaluates *this* file as Swift on
// every resolve instead.
//
// Per RN's "hand-authored community library contract"
// (spm-header-paths-contract.md): a self-managed Package.swift depends on
// the app-local ReactNative + React-GeneratedCode packages by plain relative
// path. The autolinker always exposes a self-managed dep through a symlink
// at `<appRoot>/build/generated/autolinking/libs/<SwiftName>/` — a fixed
// depth from appRoot — so those relative paths are stable constants, not
// something this manifest has to discover at resolve time.

let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

// MARK: - React Native + package dependencies
// Per the hand-authored community library contract (RN's
// spm-header-paths-contract.md): a self-managed dep is symlinked by the
// autolinker at a fixed depth, `<appRoot>/build/generated/autolinking/libs/<SwiftName>/`,
// so these relative paths to the app-local ReactNative / React-GeneratedCode
// packages are stable — the same ones RN's own scaffolder emits.

let packageDependencies: [Package.Dependency] = [
  .package(name: "ReactNative", path: "../../../../xcframeworks"),
  .package(name: "React-GeneratedCode", path: "../../../ios"),
]
let targetDependencies: [Target.Dependency] = [
  .product(name: "ReactHeaders", package: "ReactNative"),
  .product(name: "ReactNativeHeaders", package: "ReactNative"),
  .product(name: "ReactNativeDependenciesHeaders", package: "ReactNative"),
  .product(name: "ReactAppHeaders", package: "React-GeneratedCode"),
]

// MARK: - Package

// `path: "."` puts the whole repo root in scope for SPM's own directory
// walk. `example/` contains the autolinker's self-managed-package symlink
// for this very package (`example/ios/build/generated/autolinking/libs/OpS2`
// -> this repo root), so an unbounded walk recurses through that symlink
// forever. Bound the walk to only the top-level dirs the target needs.
let neededTopLevelDirs: Set<String> = ["ios", "cpp"]
let topLevelExcludes: [String] =
  (try? FileManager.default.contentsOfDirectory(atPath: packageRoot.path))?
  .filter { !neededTopLevelDirs.contains($0) && $0 != "Package.swift" && $0 != "op-s2-spm-prefix.h" }
  ?? []

let package = Package(
  name: "OpS2",
  // RN's own SPM packaging (generate-spm-autolinking.js) only declares
  // .iOS(.v15) for the autolinked aggregator; a broader platform list here
  // makes SPM reject the whole graph with a minimum-deployment-target
  // conflict, since the aggregator doesn't guarantee those platforms. RN's
  // SwiftPM support is iOS-only at this stage regardless.
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "OpS2", targets: ["OpS2"])
  ],
  dependencies: packageDependencies,
  targets: [
    .target(
      name: "OpS2",
      dependencies: targetDependencies,
      path: ".",
      // Deliberately no `sources:` alongside `exclude:` — combining an
      // explicit `sources:` allowlist with `exclude:` proved unreliable on
      // this toolchain (files covered by `exclude:` but absent from
      // `sources:` still got swept into the build). `topLevelExcludes` is
      // constructed so everything left under `path` is exactly the wanted
      // set (mirrors op-s2.podspec's `ios/**/*.{h,m,mm}` +
      // `cpp/**/*.{c,h,hpp,cpp}`), and the default auto-scan is the
      // well-trodden SPM code path.
      exclude: topLevelExcludes,
      publicHeadersPath: "cpp",
      cSettings: [
        .headerSearchPath("."),
        .headerSearchPath("cpp"),
        .unsafeFlags(["-O2", "-include", "op-s2-spm-prefix.h"]),
      ],
      cxxSettings: [
        .headerSearchPath("."),
        .headerSearchPath("cpp"),
        .unsafeFlags(["-O2", "-include", "op-s2-spm-prefix.h"]),
      ],
      linkerSettings: [
        .linkedFramework("LocalAuthentication")
      ]
    )
  ],
  cxxLanguageStandard: .cxx2b
)
