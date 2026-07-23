import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "CoreNetworking",
    bundleIdSuffix: "core.networking",
    dependencies: [.core("Models")]
)
