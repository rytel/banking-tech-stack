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
        dependencies: [TargetDependency] = [],
        needsTestHost: Bool = false
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

        // Tests that touch the Keychain must run inside a host app: a hostless XCTest bundle
        // on the iOS Simulator has no keychain access group, so SecItemAdd fails with -34018
        // (errSecMissingEntitlement). The host app is a minimal, empty app; XCTest injects the
        // test bundle into it and the tests inherit the host's default keychain access group.
        let hostTarget: Target? = needsTestHost ? .target(
            name: "\(name)TestHost",
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundleId).testhost",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: ["TestHost"]
        ) : nil

        var testDependencies: [TargetDependency] = [.target(name: name)]
        var testSettings: SettingsDictionary = [:]
        if let hostTarget {
            testDependencies.append(.target(name: hostTarget.name))
            testSettings["TEST_HOST"] = .string("$(BUILT_PRODUCTS_DIR)/\(hostTarget.name).app/\(hostTarget.name)")
        }

        let testTarget = Target.target(
            name: "\(name)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleId).tests",
            deploymentTargets: deploymentTargets,
            buildableFolders: ["Tests"],
            dependencies: testDependencies,
            settings: .settings(base: testSettings)
        )

        return Project(
            name: name,
            settings: .settings(base: [
                "DEVELOPMENT_TEAM": .string(developmentTeam),
                "SWIFT_VERSION": .string("6.0"),
            ]),
            targets: [mainTarget, testTarget, hostTarget].compactMap { $0 },
            additionalFiles: ["Project.swift"]
        )
    }
}
