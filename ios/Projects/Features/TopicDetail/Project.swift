import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "FeatureTopicDetail",
    bundleIdSuffix: "features.topicdetail",
    dependencies: [.core("Models"), .core("DesignSystem")]
)
