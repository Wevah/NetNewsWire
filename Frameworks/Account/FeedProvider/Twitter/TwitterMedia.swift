//
//  TwitterMedia.swift
//  Account
//
//  Created by Maurice Parker on 4/18/20.
//  Copyright © 2020 Ranchero Software, LLC. All rights reserved.
//

import Foundation

struct TwitterMedia: Codable {
	
	let idStr: String?
	let indices: [Int]?
	let mediaURL: String?
	let httpsMediaURL: String?
	let url: String?
	let displayURL: String?
	let type: String?
	let video: TwitterVideo?

	enum CodingKeys: String, CodingKey {
		case idStr = "idStr"
		case indices = "indices"
		case mediaURL = "media_url"
		case httpsMediaURL = "media_url_https"
		case url = "url"
		case displayURL = "display_url"
		case type = "type"
		case video = "video_info"
	}
	
	func renderAsHTML() -> String {
		var html = String()
		
		switch type {
		case "photo":
			if let url = url {
				html += "<a href=\"\(url)\">"
				html += renderPhotoAsHTML()
				html += "</a>"
			} else {
				html += renderPhotoAsHTML()
			}
		case "video":
			html += renderVideoAsHTML()
		default:
			break
		}
		
		return html
	}
	
}

private extension TwitterMedia {

	func renderPhotoAsHTML() -> String {
		if let httpsMediaURL = httpsMediaURL {
			return "<figure><img src=\"\(httpsMediaURL)\"></figure>"
		}
		if let mediaURL = mediaURL {
			return "<figure><img src=\"\(mediaURL)\"></figure>"
		}
		return ""
	}

	func renderVideoAsHTML() -> String {
		guard let bestVariantURL = findBestVariant()?.url else { return "" }
		
		var html = "<video "

		if let httpsMediaURL = httpsMediaURL {
			html += "poster=\"\(httpsMediaURL)\" "
		} else if let mediaURL = mediaURL {
			html += "poster=\"\(mediaURL)\" "
		}

		html += "src=\"\(bestVariantURL)\"></video>"
		return html
	}
	
	func findBestVariant() -> TwitterVideo.Variant? {
		var best: TwitterVideo.Variant? = nil
		if let variants = video?.variants {
			for variant in variants {
				if let currentBest = best {
					if variant.bitrate ?? 0 > currentBest.bitrate ?? 0 {
						best = variant
					}
				} else {
					best = variant
				}
			}
		}
		return best
	}
	
//	<video poster="https://pbs.twimg.com/ext_tw_video_thumb/1251578276709109764/pu/img/fHFdxWFL3nQE9L0I.jpg:large" width="10" height="7" src="https://video.twimg.com/ext_tw_video/1251578276709109764/pu/vid/1028x720/lHpEeJekcIZAod2B.mp4?tag=10" playsinline="true" controls="true"></video>
}
