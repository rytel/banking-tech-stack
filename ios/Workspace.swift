import ProjectDescription

let workspace = Workspace(
    name: "BankingTechStack",
    projects: [
        "Projects/App",
        "Projects/Features/**",
        "Projects/Core/**",
    ],
    additionalFiles: [
        "Workspace.swift",
        "Tuist.swift",
        "Tuist/ProjectDescriptionHelpers/Project+Module.swift",
        "Tuist/Package.swift",
    ]
)
