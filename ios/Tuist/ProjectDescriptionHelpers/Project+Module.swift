import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")
let bundleIdRoot = "dev.rflrytel.bankingtechstack"
let developmentTeam = "2WF737FU65"

public extension TargetDependency {
    /// A dependency on a module under `Projects/Core/<module>`, e.g. `.core("Models")`.
    static func core(_ module: String) -> TargetDependency {
        .project(target: "Core\(module)", path: .relativeToRoot("Projects/Core/\(module)"))
    }

    /// A dependency on a module under `Projects/Features/<module>`, e.g. `.feature("Auth")`.
    static func feature(_ module: String) -> TargetDependency {
        .project(target: "Feature\(module)", path: .relativeToRoot("Projects/Features/\(module)"))
    }
}

public extension Project {
    /// Builds a module as a `Project` with a main target and a paired unit test target,
    /// so every one of the app's modules follows the same shape without repeating boilerplate.
    static func module(
        name: String,
        bundleIdSuffix: String,
        product: Product = .framework,
        dependencies: [TargetDependency] = []
    ) -> Project {
        let bundleId = "\(bundleIdRoot).\(bundleIdSuffix)"

        let mainTarget = Target.target(
            name: name,
            destinations: .iOS,
            product: product,
            bundleId: bundleId,
            deploymentTargets: deploymentTargets,
            buildableFolders: ["Sources"],
            dependencies: dependencies
        )

        let testTarget = Target.target(
            name: "\(name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleId).tests",
            deploymentTargets: deploymentTargets,
            buildableFolders: ["Tests"],
            dependencies: [.target(name: name)]
        )

        return Project(
            name: name,
            settings: .settings(base: [
                "DEVELOPMENT_TEAM": .string(developmentTeam),
                "SWIFT_VERSION": .string("6.0"),
            ]),
            targets: [mainTarget, testTarget],
            additionalFiles: ["Project.swift"]
        )
    }
}
