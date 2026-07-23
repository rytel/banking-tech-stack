import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "CoreSecureStorage",
    bundleIdSuffix: "core.securestorage",
    dependencies: [.core("Models")],
    // The tests exercise the real Keychain, which needs a host app on the Simulator
    // (see `Project.module`).
    needsTestHost: true
)
