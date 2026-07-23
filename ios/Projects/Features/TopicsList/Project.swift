import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "FeatureTopicsList",
    bundleIdSuffix: "features.topicslist",
    dependencies: [.core("Models"), .core("DesignSystem")]
)
