//
//  DockMenuController.swift
//  NetNewsWire
//
//  Created by Nate Weaver on 2019-10-05.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation
import Articles
import Account
import RSCore
import os.log

class DockMenuController: NSObject, NSMenuDelegate {
	static let shared = DockMenuController()

	@objc func openRepresentedArticle(forItem item: NSMenuItem) {
		if let article = item.representedObject as? Article {
			os_log(.debug, "%@", article.title ?? "nil")

			if let urlString = article.url ?? article.externalURL, let url = URL(string: urlString) {
				NSWorkspace.shared.open(url)
				markArticles([article], statusKey: .read, flag: true)
			}
		}
	}

	@objc func markArticlesAsRead(forMenuItem menuItem: NSMenuItem) {
		if let articles = menuItem.representedObject as? Set<Article> {
			markArticles(articles, statusKey: .read, flag: true)
		}
	}

	@objc func openLink(forMenuItem menuItem: NSMenuItem) {
		if let feed = menuItem.representedObject as? Feed, let urlString = feed.homePageURL, let url = URL(string: urlString) {
			NSWorkspace.shared.open(url)
		}
	}

	private func menuForFeed(_ feed: Feed) -> NSMenu {
		let menu = NSMenu(title: feed.nameForDisplay)
		let sortOrder = AppDefaults.timelineSortDirection
		let articles = feed.fetchUnreadArticles()

		let sortedArticles = articles.sorted { (a, b) -> Bool in
			if sortOrder == .orderedAscending { return a.sortableDate < b.sortableDate }
			else { return a.sortableDate > b.sortableDate }
		}

		for article in sortedArticles {
			var title: String

			if let s = article.title {
				title = s
			} else {
				if let body = article.body {
					var s = body
					s = s.rsparser_stringByDecodingHTMLEntities()
					s = s.rs_string(byStrippingHTML: 50)
					s = s.rs_stringByTrimmingWhitespace()
					s = s.rs_stringWithCollapsedWhitespace()

					if s.count < body.count { s = s.appending("…") }

					title = s
				} else {
					title = NSLocalizedString("Untitled", comment: "Untitled article title")
				}
			}

			let item = menu.addItem(withTitle: title, action: #selector(openRepresentedArticle), keyEquivalent: "")
			item.target = self
			item.representedObject = article
		}

		menu.addItem(.separator())

		var item = menu.addItem(withTitle: NSLocalizedString("Open Link", comment: "Open feed link"), action: #selector(openLink(forMenuItem:)), keyEquivalent: "")
		item.target = self
		item.representedObject = feed

		item = menu.addItem(withTitle: NSLocalizedString("Mark All as Read", comment: "Mark all articles as read"), action: #selector(markArticlesAsRead(forMenuItem:)), keyEquivalent: "")
		item.target = self
		item.representedObject = articles

		return menu
	}

	func menuForContainer(_ container: Container & DisplayNameProvider) -> NSMenu? {
		if container.topLevelFeeds.count == 0 && container.folders?.count == 0 { return nil }

		let containerMenu = NSMenu()

		let sortedFeeds = container.topLevelFeeds.sorted { (a, b) -> Bool in
			return a.nameForDisplay.compare(b.nameForDisplay, options: .caseInsensitive) == .orderedAscending
		}

		var sortedFolders: [Folder]? = nil

		if let folders = container.folders {
			sortedFolders = folders.sorted { (a, b) -> Bool in
				return a.nameForDisplay.compare(b.nameForDisplay, options: .caseInsensitive) == .orderedAscending
			}
		}

		for feed in sortedFeeds {
			if feed.unreadCount == 0 { continue }
			let item = containerMenu.addItem(withTitle: feed.nameForDisplay, action: nil, keyEquivalent: "")
			item.submenu = menuForFeed(feed)
		}

		if let sortedFolders = sortedFolders {
			for folder in sortedFolders {
				let folderItem = NSMenuItem(title: folder.nameForDisplay, action: nil, keyEquivalent: "")
				folderItem.submenu = menuForContainer(folder)
				containerMenu.addItem(folderItem)
			}
		}

		return containerMenu;
	}

	var menu: NSMenu {
		let menu = NSMenu()

		for account in AccountManager.shared.activeAccounts {
			menu.addSeparatorIfNeeded()
			menu.addItem(withTitle: account.nameForDisplay, action: nil, keyEquivalent: "")

			if let accountMenu = menuForContainer(account) {
				for item in accountMenu.items {
					accountMenu.removeItem(item)
					menu.addItem(item)
				}
			}
		}

		return menu
	}
}
