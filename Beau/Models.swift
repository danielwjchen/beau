//
//  Models.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//
import Foundation

struct BeauItem {
  var sourceURL: URL
  var targetURL: URL
  var rename: String = ""
  var timeBegin: Date?
  var timeEnd: Date?
  var resolution: String
  var encoding: String
  var completionPercentage: Float?
}

struct BeauSession {
  var isInPlace: Bool = true
  var resolution: String
  var encoding: String
  var renamePattern: String = ""
  var preservesMeta: Bool = true
  var sourceURL: URL
  var targetURL: URL
  var preservesFolders: Bool = true
  var items: [BeauItem]
  var timeBegin: Date?
  var timeEnd: Date?
}
