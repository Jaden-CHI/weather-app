import Flutter
import EventKit
import UIKit
import Vision
import ImageIO

private struct RecognizedToken {
  let text: String
  let box: CGRect

  var centerY: CGFloat { box.midY }
  var centerX: CGFloat { box.minX }
  var height: CGFloat { box.height }
}

private struct RecognizedLineGroup {
  var tokens: [RecognizedToken]
  var averageCenterY: CGFloat
  var averageHeight: CGFloat

  mutating func append(_ token: RecognizedToken) {
    tokens.append(token)
    let count = CGFloat(tokens.count)
    averageCenterY = ((averageCenterY * (count - 1)) + token.centerY) / count
    averageHeight = ((averageHeight * (count - 1)) + token.height) / count
  }
}

final class ScoreOcrPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "golf_windy/ocr",
      binaryMessenger: registrar.messenger()
    )
    let instance = ScoreOcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "이미지 경로가 전달되지 않았습니다.",
          details: nil
        )
      )
      return
    }

    recognizeText(at: path, result: result)
  }

  private func recognizeText(at path: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let imageUrl = URL(fileURLWithPath: path)
      guard
        let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil),
        let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
      else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "image_load_failed",
              message: "이미지를 불러오지 못했습니다.",
              details: path
            )
          )
        }
        return
      }

      let request = VNRecognizeTextRequest { request, error in
        if let error {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "ocr_failed",
                message: "텍스트 인식에 실패했습니다.",
                details: error.localizedDescription
              )
            )
          }
          return
        }

        let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
        let lines = self.buildLogicalLines(from: observations)

        DispatchQueue.main.async {
          result(lines.joined(separator: "\n"))
        }
      }

      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = false
      request.recognitionLanguages = ["ko-KR", "en-US"]
      request.minimumTextHeight = 0.015

      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "ocr_request_failed",
              message: "OCR 요청 실행에 실패했습니다.",
              details: error.localizedDescription
            )
          )
        }
      }
    }
  }

  private func buildLogicalLines(from observations: [VNRecognizedTextObservation]) -> [String] {
    let tokens = observations.compactMap { observation -> RecognizedToken? in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      let trimmed = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      return RecognizedToken(text: trimmed, box: observation.boundingBox)
    }

    guard !tokens.isEmpty else { return [] }

    let sortedTokens = tokens.sorted { lhs, rhs in
      let yTolerance = max(min(lhs.height, rhs.height) * 0.7, 0.012)
      let yDiff = abs(lhs.centerY - rhs.centerY)
      if yDiff > yTolerance {
        return lhs.centerY > rhs.centerY
      }
      return lhs.centerX < rhs.centerX
    }

    var groups: [RecognizedLineGroup] = []

    for token in sortedTokens {
      let tokenTolerance = max(min(token.height * 0.85, 0.03), 0.012)
      var matchedGroupIndex: Int?
      var smallestDiff = CGFloat.greatestFiniteMagnitude

      for (index, group) in groups.enumerated().reversed() {
        let groupTolerance = max(min(group.averageHeight * 0.9, 0.03), 0.012)
        let yDiff = abs(group.averageCenterY - token.centerY)
        if yDiff <= max(tokenTolerance, groupTolerance), yDiff < smallestDiff {
          matchedGroupIndex = index
          smallestDiff = yDiff
        }

        if group.averageCenterY - token.centerY > 0.08 {
          break
        }
      }

      if let matchedGroupIndex {
        groups[matchedGroupIndex].append(token)
      } else {
        groups.append(
          RecognizedLineGroup(
            tokens: [token],
            averageCenterY: token.centerY,
            averageHeight: token.height
          )
        )
      }
    }

    return groups
      .sorted { lhs, rhs in lhs.averageCenterY > rhs.averageCenterY }
      .map { group in
        group.tokens
          .sorted { lhs, rhs in lhs.centerX < rhs.centerX }
          .map(\.text)
          .joined(separator: " ")
          .replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
          )
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }
      .filter { !$0.isEmpty }
  }
}

final class CalendarImportPlugin: NSObject, FlutterPlugin {
  private let eventStore = EKEventStore()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "golf_windy/calendar",
      binaryMessenger: registrar.messenger()
    )
    let instance = CalendarImportPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "findGolfEvents" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard let args = call.arguments as? [String: Any],
      let startMillis = int64Argument(args["startMillis"]),
      let endMillis = int64Argument(args["endMillis"])
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "캘린더 조회 기간이 전달되지 않았습니다.",
          details: nil
        )
      )
      return
    }

    ensureCalendarAccess { [weak self] granted, error in
      guard let self else { return }

      if let error {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "calendar_permission_failed",
              message: "캘린더 권한 확인에 실패했습니다.",
              details: error.localizedDescription
            )
          )
        }
        return
      }

      guard granted else {
        DispatchQueue.main.async {
          result(["permissionGranted": false, "events": []])
        }
        return
      }

      let startDate = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000.0)
      let endDate = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000.0)
      let events = self.fetchEvents(from: startDate, to: endDate)

      DispatchQueue.main.async {
        result(["permissionGranted": true, "events": events])
      }
    }
  }

  private func int64Argument(_ value: Any?) -> Int64? {
    if let value = value as? Int64 { return value }
    if let value = value as? Int { return Int64(value) }
    if let value = value as? NSNumber { return value.int64Value }
    return nil
  }

  private func ensureCalendarAccess(
    completion: @escaping (_ granted: Bool, _ error: Error?) -> Void
  ) {
    let status = EKEventStore.authorizationStatus(for: .event)

    switch status {
    case .authorized:
      completion(true, nil)
    case .notDetermined:
      requestCalendarAccess(completion: completion)
    case .restricted, .denied:
      completion(false, nil)
    @unknown default:
      if #available(iOS 17.0, *) {
        if status == .fullAccess {
          completion(true, nil)
        } else if status == .writeOnly {
          completion(false, nil)
        } else {
          completion(false, nil)
        }
      } else {
        completion(false, nil)
      }
    }
  }

  private func requestCalendarAccess(
    completion: @escaping (_ granted: Bool, _ error: Error?) -> Void
  ) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, error in
        completion(granted, error)
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, error in
        completion(granted, error)
      }
    }
  }

  private func fetchEvents(from startDate: Date, to endDate: Date) -> [[String: Any]] {
    let calendars = eventStore.calendars(for: .event)
    let predicate = eventStore.predicateForEvents(
      withStart: startDate,
      end: endDate,
      calendars: calendars
    )

    return eventStore.events(matching: predicate)
      .sorted { $0.startDate < $1.startDate }
      .prefix(200)
      .map { event in
        [
          "id": event.eventIdentifier ?? "",
          "title": event.title ?? "",
          "location": event.location ?? "",
          "description": event.notes ?? "",
          "startMillis": Int64(event.startDate.timeIntervalSince1970 * 1000),
          "endMillis": Int64(event.endDate.timeIntervalSince1970 * 1000),
          "allDay": event.isAllDay,
        ]
      }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let registrar = self.registrar(forPlugin: "ScoreOcrPlugin") {
      ScoreOcrPlugin.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "CalendarImportPlugin") {
      CalendarImportPlugin.register(with: registrar)
    }

    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
