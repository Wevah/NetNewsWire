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

	private func updateMenu(_ menu: NSMenu, forFeed feed: Feed) {
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
	}

	private var menuMap = [NSMenu: Feed]()

	func menuNeedsUpdate(_ menu: NSMenu) {
		if let feed = menuMap[menu] {
			updateMenu(menu, forFeed: feed)
		}
	}

	func menuHasKeyEquivalent(_ menu: NSMenu, for event: NSEvent, target: AutoreleasingUnsafeMutablePointer<AnyObject?>, action: UnsafeMutablePointer<Selector?>) -> Bool {
		return false
	}

	var menu: NSMenu {
		menuMap.removeAll()
		let menu = NSMenu()

		for (index, account) in AccountManager.shared.activeAccounts.enumerated() {
			if index != 0 { menu.addItem(.separator()) }

			menu.addItem(withTitle: account.nameForDisplay, action: nil, keyEquivalent: "")

			let sortedFeeds = account.topLevelFeeds.sorted { (a, b) -> Bool in
				return a.nameForDisplay.compare(b.nameForDisplay, options: .caseInsensitive) == .orderedAscending
			}

			for feed in sortedFeeds {
				if feed.unreadCount == 0 { continue }

				let item = menu.addItem(withTitle: feed.nameForDisplay, action: nil, keyEquivalent: "")
				let submenu = NSMenu(title: feed.nameForDisplay)

				//menuMap[submenu] = feed

				updateMenu(submenu, forFeed: feed)

				item.submenu = submenu
				//submenu.delegate = self
			}
		}

		return menu
	}
}
