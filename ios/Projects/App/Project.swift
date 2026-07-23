import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: "App",
    bundleIdSuffix: "app",
    product: .app,
    dependencies: [
        .feature("Auth"),
        .feature("TopicsList"),
        .feature("TopicDetail"),
        .core("Networking"),
        .core("SecureStorage"),
        .core("DesignSystem"),
    ]
)
