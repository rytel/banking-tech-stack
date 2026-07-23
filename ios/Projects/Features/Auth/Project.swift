import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "FeatureAuth",
    bundleIdSuffix: "features.auth",
    dependencies: [.core("Models"), .core("DesignSystem")]
)
