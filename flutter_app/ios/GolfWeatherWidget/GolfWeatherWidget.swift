import WidgetKit
import SwiftUI

// ── App Group에서 Flutter(home_widget)가 저장한 데이터 읽기 ──────
private let appGroup = "group.com.weatherapp.widget"

struct WeatherEntry: TimelineEntry {
    let date: Date
    let ddayLabel: String
    let courseName: String
    let status: String       // GREEN / YELLOW / RED / NONE
    let message: String
    let temp: String
    let rainProb: String
    let windSpeed: String
    let cancelMessage: String
    // 낚시 전용
    let waveHeight: String
    let goldenTime: String
    let departureBlocked: Bool
}

// ── 데이터 로더 ────────────────────────────────────────────────
struct WeatherProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: Date(), ddayLabel: "D-3",
            courseName: "용인 컨트리클럽", status: "GREEN",
            message: "라운딩 최적 날씨", temp: "18~24°C",
            rainProb: "10%", windSpeed: "3m/s",
            cancelMessage: "무료 취소 가능 — 23시간 남음",
            waveHeight: "", goldenTime: "", departureBlocked: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry = readEntry()
        // 1시간 후 갱신
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> WeatherEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        return WeatherEntry(
            date: Date(),
            ddayLabel:        defaults?.string(forKey: "dday_label") ?? "",
            courseName:       defaults?.string(forKey: "course_name") ?? "일정 없음",
            status:           defaults?.string(forKey: "status") ?? "NONE",
            message:          defaults?.string(forKey: "status_message") ?? "켜자마자 날씨",
            temp:             defaults?.string(forKey: "temp") ?? "",
            rainProb:         defaults?.string(forKey: "rain_prob") ?? "",
            windSpeed:        defaults?.string(forKey: "wind_speed") ?? "",
            cancelMessage:    defaults?.string(forKey: "cancel_message") ?? "",
            waveHeight:       defaults?.string(forKey: "wave_height") ?? "",
            goldenTime:       defaults?.string(forKey: "golden_time") ?? "",
            departureBlocked: defaults?.string(forKey: "departure_blocked") == "true"
        )
    }
}

// ── 색상 헬퍼 ──────────────────────────────────────────────────
private extension String {
    var statusColor: Color {
        switch self {
        case "GREEN":  return Color(red: 0.30, green: 0.69, blue: 0.31)
        case "YELLOW": return Color(red: 1.00, green: 0.76, blue: 0.03)
        case "RED":    return Color(red: 0.96, green: 0.26, blue: 0.21)
        default:       return .gray
        }
    }
    var statusBg: Color {
        switch self {
        case "GREEN":  return Color(red: 0.07, green: 0.26, blue: 0.20)
        case "YELLOW": return Color(red: 0.24, green: 0.17, blue: 0.00)
        case "RED":    return Color(red: 0.24, green: 0.00, blue: 0.00)
        default:       return Color(red: 0.05, green: 0.11, blue: 0.16)
        }
    }
}

// ── 홈화면 위젯 뷰 (medium, 4×2) ──────────────────────────────
struct GolfWeatherWidgetView: View {
    let entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            entry.status.statusBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                // 1행: D-Day 뱃지 + 코스명 + 상태 점
                HStack(spacing: 8) {
                    if !entry.ddayLabel.isEmpty {
                        Text(entry.ddayLabel)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.18, green: 0.49, blue: 0.42))
                            .cornerRadius(6)
                    }
                    Circle()
                        .fill(entry.status.statusColor)
                        .frame(width: 8, height: 8)
                    Text(entry.courseName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                // 2행: AI 권고 메시지
                Text(entry.message)
                    .font(.system(size: 12))
                    .foregroundColor(entry.status.statusColor)
                    .lineLimit(2)

                // 3행: 날씨 수치
                if !entry.temp.isEmpty {
                    HStack(spacing: 12) {
                        Label(entry.temp, systemImage: "thermometer")
                        Label(entry.rainProb, systemImage: "cloud.rain")
                        Label(entry.windSpeed, systemImage: "wind")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.7))
                }

                // 4행: 낚시 전용 (wave height / golden time)
                if !entry.waveHeight.isEmpty {
                    HStack(spacing: 12) {
                        Label(entry.waveHeight, systemImage: "water.waves")
                        Label(entry.goldenTime, systemImage: "fish")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color.cyan.opacity(0.8))
                }

                Spacer(minLength: 0)

                // 5행: 취소 안내
                if !entry.cancelMessage.isEmpty {
                    Text(entry.cancelMessage)
                        .font(.system(size: 11))
                        .foregroundColor(Color.green.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
    }
}

// ── 잠금화면 위젯 뷰 (accessoryRectangular, iOS 16+) ───────────
struct LockScreenWeatherView: View {
    let entry: WeatherEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                if !entry.ddayLabel.isEmpty {
                    Text(entry.ddayLabel)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(entry.courseName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            Text(entry.message)
                .font(.system(size: 11))
                .foregroundColor(entry.status.statusColor)
                .lineLimit(1)
            if !entry.cancelMessage.isEmpty {
                Text(entry.cancelMessage)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ── Widget 설정 ────────────────────────────────────────────────
@main
struct GolfWeatherWidget: Widget {
    let kind = "GolfWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            if #available(iOS 17.0, *) {
                GolfWeatherWidgetView(entry: entry)
                    .containerBackground(entry.status.statusBg, for: .widget)
            } else {
                GolfWeatherWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("켜자마자 날씨")
        .description("골프·낚시 일정 날씨 & 취소 권고")
        .supportedFamilies([
            .systemMedium,
            .accessoryRectangular,  // 잠금화면 (iOS 16+)
        ])
    }
}
