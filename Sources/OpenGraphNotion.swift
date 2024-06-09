import ArgumentParser
import Foundation
import OpenGraphReader
import NotionSwift

@main
struct OpenGraphNotion: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        abstract: "Open Graph Utility for Notion",
        subcommands: [WWDCCommand.self],
        defaultSubcommand: WWDCCommand.self
    )
}

struct WWDCCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "wwdc",
        abstract: "Enters a WWDC video URL into Notion"
    )

    @Argument(help: "Hello", transform: { URL(string: $0) ?? URL(string: "https://google.com")! })
    var url: URL

    func run() async throws {
        print("got \(url)")

        print("fetching metadata...")
        let openGraphResponse = try await OpenGraphReader().fetch(url: url)

        let titleParts = (openGraphResponse.title ?? "").split(separator: " - ").map(String.init)

        let id = url.pathComponents.last
        let year = titleParts[1].replacing("WWDC", with: "WWDC 20")

        //        print(
        //            """
        //            metadata
        //            host: \(urlComponents?.host ?? "N/A")
        //            id: \(id ?? "N/A")
        //            title: \(titleParts[0])
        //            year: \(year)
        //            image: \(String(describing: openGraphResponse.imageURL))
        //            description: \(openGraphResponse.description ?? "N/A")
        //            icon: \(String(describing: openGraphResponse.urlValue("icon")))
        //            url: \(String(describing: metadata.url))
        //            """
        //        )

        guard
            let id,
            let title = titleParts.first,
            let imageURL = openGraphResponse.imageURL,
            let description = openGraphResponse.description
        else {
            print("Incomplete data")
            return
        }

        let video = WWDC.Video(
            id: id,
            url: url,
            name: title,
            year: year,
            imageURL: imageURL,
            description: description
        )

        guard let notionAccessKey = ProcessInfo.processInfo.environment["WWDC_IMPORTER_NOTION_ACCESS_KEY"] else {
            fatalError("❌ you need to set `WWDC_IMPORTER_NOTION_ACCESS_KEY`")
        }
        guard let dbID = ProcessInfo.processInfo.environment["WWDC_IMPORTER_DB_ID"] else {
            fatalError("❌ you need to set `WWDC_IMPORTER_DB_ID`")
        }

        let notion = NotionClient(accessKeyProvider: StringAccessKeyProvider(accessKey: notionAccessKey))

        print("searching for '\(video.name)'...")
        let existingPageFound = try await searchExistingPage(for: video, inDB: dbID, forClient: notion)
        guard !existingPageFound else {
            print("exising page found! ... skiping the rest")
            return
        }

        print("no data for that session")
        let request = PageCreateRequest(
            parent: .database(.init(dbID)),
            properties: [
                "Name": .init(
                    type: .title([.init(string: video.name)])
                ),
                "Year": .init(type: .select(.init(id: nil, name: video.year, color: nil))),
                "URL": .init(type: .url(video.url)),
                "Image": .init(
                    type: .files(
                        [
                            .init(
                                video.name + " - Image",
                                type: .external(url: video.imageURL.absoluteString)
                            )
                        ]
                    )
                ),
            ],
            children: [
                .init(type: .paragraph(.init(richText: [.init(string: video.description)], color: .default)))
            ]
        )


        let newPage = try await createNotionPage(with: request, forClient: notion)
        let _ = try await updatePageCover(for: newPage.id, to: video.imageURL, forClient: notion)

        print("\(url) imported into Notion")
    }

    @discardableResult
    private func searchExistingPage(for video: WWDC.Video, inDB dbID: String, forClient notion: NotionClient) async throws -> Bool {
        try await withUnsafeThrowingContinuation { continuation in
            notion.databaseQuery(databaseId: Database.Identifier(dbID)) { result in
                switch result {
                case .success(let resultPages):
                    let urls = resultPages.results.compactMap {
                        if case let .url(urlValue) = $0.properties["URL"]?.type {
                            return urlValue
                        } else {
                            return nil
                        }
                    }
                    continuation.resume(returning: urls.contains(where: { $0 == video.url }))
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    private func createNotionPage(
        with request: PageCreateRequest,
        forClient notion: NotionClient
    ) async throws -> Page {
        try await withUnsafeThrowingContinuation { continuation in
            notion.pageCreate(request: request) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    private func updatePageCover(
        for pageID: Page.ID,
        to imageURL: URL,
        forClient notion: NotionClient
    ) async throws -> Page {
        try await withUnsafeThrowingContinuation { continuation in
            notion.pageUpdateProperties(
                pageId: pageID,
                request: .init(cover: .external(url: imageURL.absoluteString))
            ) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
}

enum WWDC {}

extension WWDC {
    struct Video {
        let id: String
        let url: URL
        let name: String
        let year: String
        let imageURL: URL
        let description: String
    }
}
