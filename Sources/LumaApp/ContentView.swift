import SwiftUI
import LightCore

extension RGB {
    var swiftColor: Color { Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255) }
}

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 18)]

    private var sidebarSelection: Binding<String?> {
        Binding(get: { model.category }, set: { selection in
            guard let selection else { return }
            model.category = selection; model.tab = 0; model.search = ""
        })
    }

    private var visiblePresets: [Preset] {
        let source = model.category == "Мои цвета" ? model.favorites : PresetCatalog.all
        return source.filter {
            (model.category == "Все пресеты" || model.category == "Мои цвета" || $0.group.rawValue == model.category)
            && (model.search.isEmpty || ($0.name + " " + $0.subtitle).localizedCaseInsensitiveContains(model.search))
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar.navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            workspace
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 650)
        .overlayPreferenceValue(RecommendationOrbAnchor.self) { anchor in
            GeometryReader { geometry in
                if let anchor {
                    let bounds = geometry[anchor]
                    RecommendationGlow(model: model, center: CGPoint(x: bounds.midX, y: bounds.midY), size: geometry.size)
                }
            }.allowsHitTesting(false)
        }
        .disabled(model.recommendationFlow.phase != .idle)
        .alert("Luma", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("Понятно") { model.error = nil }
        } message: { Text(model.error ?? "") }
        .sheet(isPresented: $model.showSave) { saveSheet }
    }

    private var sidebar: some View {
        List(selection: sidebarSelection) {
            Section("Библиотека") {
                Label("Все цвета", systemImage: "square.grid.2x2").badge(PresetCatalog.all.count).tag("Все пресеты")
                Label("Мои цвета", systemImage: "heart").badge(model.favorites.count).tag("Мои цвета")
            }
            Section("Настроение") {
                ForEach(PresetGroup.allCases, id: \.self) { group in
                    Label(group.rawValue, systemImage: group.icon).tag(group.rawValue)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            Label {
                Text("Свет останется,\nкогда вы закроете Luma.")
                    .font(.system(size: 11)).lineSpacing(3)
            } icon: {
                Image(systemName: "powerplug").font(.system(size: 14, weight: .light))
            }
            .foregroundStyle(.secondary).padding(18)
        }
        .navigationTitle("Luma")
    }

    private var workspace: some View {
        VStack(alignment: .leading, spacing: 24) {
            recommendation.padding(.horizontal, 28).padding(.top, 16)
            if model.tab == 0 { libraryHeader.padding(.horizontal, 28) }
            ScrollView {
                Group {
                    if model.tab == 0 { presets } else { customColor }
                }.padding(.horizontal, 28).padding(.bottom, 24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            controls.padding(.horizontal, 18).padding(.bottom, 14).padding(.top, 8)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Режим выбора", selection: $model.tab) {
                    Text("Пресеты").tag(0)
                    Text("Свой цвет").tag(1)
                }.pickerStyle(.segmented).labelsHidden().frame(width: 220)
            }
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 6) {
                    Circle().fill(model.connected ? Color.green : Color.secondary).frame(width: 5, height: 5)
                    Text(model.connected ? "Подключено" : "Нет подключения")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }.help(model.deviceName).accessibilityLabel(model.deviceName)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Toggle("Предпросмотр на подсветке", isOn: $model.livePreview)
                    Divider()
                    Button("Обновить подключение и рекомендацию", systemImage: "arrow.clockwise") { model.refresh() }
                    Button("Выключить свет", systemImage: "power") { model.turnOff() }
                } label: { Image(systemName: "ellipsis") }
                .menuIndicator(.hidden).help("Настройки подсветки").disabled(model.isBusy)
            }
        }
        .onChange(of: model.livePreview) { _ in model.schedulePreview() }
    }

    private var recommendation: some View {
        let recommended = model.recommendation
        return HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Рекомендуется сейчас", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                Button { model.select(recommended.preset) } label: {
                    HStack(spacing: 9) {
                        Text(recommended.preset.name).font(.system(size: 28, weight: .semibold, design: .rounded))
                            .lineLimit(2).multilineTextAlignment(.leading)
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .medium)).foregroundStyle(.tertiary)
                    }
                }.buttonStyle(.plain)
                    .help("Выбрать рекомендованный цвет")
                    .accessibilityLabel("Выбрать рекомендацию: \(recommended.preset.name)")
                Text(recommended.preset.subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
                Text(recommended.context).font(.system(size: 10)).foregroundStyle(.secondary)
                    .padding(.top, 3)
            }.frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 10) {
                powerOrb
                VStack(spacing: 4) {
                    Text(model.selectedName).font(.system(size: 11, weight: .medium)).lineLimit(1)
                    Text(model.recommendationFlow.phase == .spreading ? "Цвет заполняет окно" :
                         model.recommendationFlow.phase == .transitioning ? "Плавный переход" : "Нажмите, чтобы включить")
                        .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                }
            }.frame(width: 168)
        }.padding(.vertical, 12)
    }

    private var powerOrb: some View {
        Button { model.beginSelectedLight() } label: {
            ZStack {
                Circle().fill(model.color.swiftColor.opacity(colorScheme == .dark ? 0.28 : 0.19))
                    .frame(width: 116, height: 116).blur(radius: 22)
                Circle().fill(RadialGradient(colors: [model.color.swiftColor, model.color.swiftColor.opacity(0.72)],
                                            center: .topLeading, startRadius: 0, endRadius: 100))
                    .frame(width: 94, height: 94)
                    .overlay(Circle().strokeBorder(.white.opacity(0.34), lineWidth: 1))
                    .overlay(alignment: .top) {
                        Ellipse().fill(.white.opacity(0.15)).frame(width: 62, height: 30).blur(radius: 9).padding(.top, 7)
                    }
                    .overlay {
                        Image(systemName: model.recommendationFlow.phase == .transitioning ? "sparkles" : "power")
                            .font(.system(size: 27, weight: .ultraLight)).foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    }
                    .shadow(color: model.color.swiftColor.opacity(0.18), radius: 12, y: 7)
                    .anchorPreference(key: RecommendationOrbAnchor.self, value: .bounds) { $0 }
            }.frame(width: 126, height: 126).contentShape(Circle())
        }
        .buttonStyle(OrbButtonStyle()).disabled(model.isBusy)
        .help("Плавно включить «\(model.selectedName)» · \(model.color.hex)")
        .accessibilityLabel("Включить выбранный цвет: \(model.selectedName), \(model.color.hex)")
        .accessibilityIdentifier("recommendationOrb")
    }

    private var libraryHeader: some View {
        HStack {
            Text(model.category == "Все пресеты" ? "Палитра настроений" : model.category)
                .font(.system(size: 16, weight: .semibold))
            Text("\(visiblePresets.count)").font(.system(size: 11)).foregroundStyle(.tertiary)
            Spacer()
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("Найти цвет", text: $model.search).textFieldStyle(.plain).font(.system(size: 12))
                    .accessibilityIdentifier("presetSearch")
                if !model.search.isEmpty {
                    Button { model.search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain).help("Очистить поиск")
                }
            }.padding(.horizontal, 11).padding(.vertical, 8).frame(width: 174)
                .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var presets: some View {
        VStack(spacing: 0) {
            if visiblePresets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: model.category == "Мои цвета" ? "heart" : "magnifyingglass")
                        .font(.system(size: 28, weight: .light)).foregroundStyle(.tertiary)
                    Text(model.category == "Мои цвета" ? "Ваши любимые оттенки" : "Цвет не найден")
                        .font(.system(size: 14, weight: .medium))
                    Text(model.category == "Мои цвета" ? "Создайте оттенок во вкладке «Свой цвет» и сохраните его здесь." : "Попробуйте другое название.")
                        .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.vertical, 48)
            }
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(visiblePresets) { preset in presetCard(preset) }
            }
        }
    }

    private func presetCard(_ preset: Preset) -> some View {
        let selected = model.color == preset.color && Int(model.brightness.rounded()) == preset.brightness
        return Button { model.select(preset) } label: {
            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [preset.color.swiftColor, preset.color.swiftColor.opacity(colorScheme == .dark ? 0.66 : 0.80)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(selected ? 0.32 : 0.035), lineWidth: selected ? 2 : 1))
                    .overlay(alignment: .bottomTrailing) {
                        if selected {
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.primary).frame(width: 23, height: 23)
                                .background(.regularMaterial, in: Circle()).padding(9)
                        }
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                    Text(preset.subtitle).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                }.padding(.horizontal, 2)
            }.contentShape(Rectangle())
        }
        .buttonStyle(PaletteButtonStyle())
        .help("\(preset.name) · \(preset.color.hex) · \(preset.brightness)%")
        .accessibilityLabel("\(preset.name), \(preset.color.hex), \(preset.brightness) процентов")
        .contextMenu {
            if model.category == "Мои цвета" { Button("Удалить пресет", role: .destructive) { model.removeFavorite(preset.id) } }
        }
    }

    private var customColor: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Ваш оттенок").font(.system(size: 16, weight: .semibold))
                Spacer()
                Button { showSave() } label: { Label("Сохранить", systemImage: "heart") }
                    .buttonStyle(.borderless).font(.system(size: 12))
            }
            HStack(alignment: .top, spacing: 28) {
                VStack(spacing: 15) {
                    ColorSquare(model: model).frame(height: 240)
                    HueStrip(model: model).frame(height: 15)
                }.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEX").font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                        TextField("#RRGGBB", text: $model.hexDraft)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .textFieldStyle(.plain).onSubmit { model.commitHex() }.accessibilityIdentifier("hexInput")
                            .padding(12).background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                    }
                    VStack(spacing: 16) {
                        ForEach(Array(["R", "G", "B"].enumerated()), id: \.offset) { index, label in
                            VStack(spacing: 5) {
                                HStack {
                                    Text(label).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(model.color.channels[index])").monospacedDigit()
                                }.font(.system(size: 11))
                                Slider(value: Binding(get: { Double(model.color.channels[index]) }, set: { model.setChannel(index, Int($0.rounded())) }), in: 0...255)
                                    .controlSize(.small).accessibilityLabel("Канал \(label)")
                            }
                        }
                    }
                }.frame(width: 170)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10).fill(model.color.swiftColor.gradient).frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.selectedName).font(.system(size: 12, weight: .medium)).lineLimit(1)
                    Text(model.color.hex).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                }.frame(minWidth: 76, maxWidth: 140, alignment: .leading)
                Spacer(minLength: 4)
                HStack(spacing: 8) {
                    Image(systemName: "sun.max").font(.system(size: 12)).foregroundStyle(.secondary)
                    Slider(value: $model.brightness, in: 0...100)
                        .frame(minWidth: 70, idealWidth: 110, maxWidth: 140).controlSize(.small)
                        .accessibilityLabel("Яркость").onChange(of: model.brightness) { _ in model.schedulePreview() }
                    Text("\(Int(model.brightness.rounded()))%")
                        .font(.system(size: 11)).monospacedDigit().frame(width: 34, alignment: .trailing)
                }
                Button { model.turnOff() } label: { Image(systemName: "power").frame(width: 16, height: 18) }
                    .modifier(LumaButton(prominent: false)).help("Выключить свет").accessibilityLabel("Выключить свет")
                    .disabled(model.isBusy)
                Button { model.apply() } label: {
                    HStack(spacing: 6) {
                        if model.isBusy { ProgressView().controlSize(.mini) }
                        Text("Включить")
                    }.font(.system(size: 12, weight: .medium)).frame(minWidth: 68, minHeight: 18)
                }.modifier(LumaButton(prominent: true)).disabled(model.isBusy)
                    .help("Плавно включить выбранный цвет · ⌘↩")
                Menu {
                    Button("Включить и закрыть") { model.apply(quit: true) }
                    Button("Сохранить в мои цвета", systemImage: "heart") { showSave() }
                } label: { Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold)) }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().disabled(model.isBusy)
                    .help("Дополнительные действия")
            }
            HStack(spacing: 8) {
                Text(model.status).lineLimit(1).help(model.status)
                Spacer(minLength: 0)
                if model.livePreview { Label("Предпросмотр", systemImage: "eye").fixedSize() }
            }.font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(16).modifier(LumaControlSurface())
    }

    private func showSave() {
        model.savedName = model.selectedName == "Свой цвет" ? "" : model.selectedName
        model.showSave = true
    }

    private var saveSheet: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14).fill(model.color.swiftColor.gradient).frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Сохранить оттенок").font(.system(size: 18, weight: .semibold))
                    Text("\(model.color.hex) · \(Int(model.brightness.rounded()))%")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            TextField("Название", text: $model.savedName).textFieldStyle(.roundedBorder)
                .onSubmit { model.saveFavorite() }
            HStack {
                Spacer()
                Button("Отмена") { model.showSave = false }.keyboardShortcut(.cancelAction)
                Button("Сохранить") { model.saveFavorite() }.buttonStyle(.borderedProminent)
                    .disabled(model.savedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(28).frame(width: 360)
    }
}

private struct LumaControlSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.primary.opacity(0.07)))
        }
    }
}

private struct LumaButton: ViewModifier {
    let prominent: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            if prominent { content.buttonStyle(.glassProminent) }
            else { content.buttonStyle(.glass) }
        } else {
            if prominent { content.buttonStyle(.borderedProminent) }
            else { content.buttonStyle(.bordered) }
        }
    }
}

private struct OrbButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

private struct PaletteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ColorSquare: View {
    @ObservedObject var model: AppModel
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hue: model.hue, saturation: 1, brightness: 1)
                LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                Circle().stroke(.white, lineWidth: 2.5).background(Circle().fill(model.color.swiftColor))
                    .frame(width: 15, height: 15).shadow(color: .black.opacity(0.5), radius: 2)
                    .position(x: max(8, min(geometry.size.width - 8, model.saturation * geometry.size.width)),
                              y: max(8, min(geometry.size.height - 8, (1 - model.value) * geometry.size.height)))
            }.clipShape(RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                    model.setHSV(s: gesture.location.x / max(1, geometry.size.width), v: 1 - gesture.location.y / max(1, geometry.size.height))
                })
                .accessibilityLabel("Цветовой квадрат. Для точного выбора используйте HEX или RGB-ползунки.")
        }
    }
}

struct HueStrip: View {
    @ObservedObject var model: AppModel
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                LinearGradient(colors: (0...12).map { Color(hue: Double($0) / 12, saturation: 1, brightness: 1) }, startPoint: .leading, endPoint: .trailing)
                Capsule().stroke(.white, lineWidth: 2).frame(width: 9)
                    .offset(x: max(0, min(geometry.size.width - 9, model.hue * geometry.size.width - 4.5)))
            }.clipShape(Capsule()).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { model.setHSV(h: $0.location.x / max(1, geometry.size.width)) })
                .accessibilityLabel("Оттенок").accessibilityAdjustableAction { direction in
                    model.setHSV(h: model.hue + (direction == .increment ? 0.02 : -0.02))
                }
        }
    }
}
