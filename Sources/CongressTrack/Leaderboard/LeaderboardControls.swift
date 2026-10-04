import SwiftUI

struct LeaderboardControls: View {
    @Bindable var model: LeaderboardModel
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack { periodPicker; samplePicker; rankToggle }.fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: 12) { periodPicker; samplePicker; rankToggle }
        }
    }
    private var periodPicker: some View {
        Picker("Holding period", selection: $model.window) {
            Text("30 days").tag(30); Text("90 days").tag(90); Text("180 days").tag(180)
        }.frame(width: 210)
    }
    private var samplePicker: some View {
        Picker("Minimum samples", selection: $model.minimumSamples) {
            Text("1 purchase").tag(1); Text("3 purchases").tag(3); Text("5 purchases").tag(5)
        }.frame(width: 210)
    }
    private var rankToggle: some View {
        Toggle("Rank by excess return", isOn: $model.rankByExcess).toggleStyle(.checkbox)
    }
}
