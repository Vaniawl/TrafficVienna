import SwiftUI

struct AnnualPassView: View {
    @EnvironmentObject private var store: AnnualPassStore
    @State private var showsEditor = false
    @State private var showsRemovalConfirmation = false

    var body: some View {
        Group {
            if let pass = store.pass {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        AnnualPassCard(pass: pass)

                        VStack(alignment: .leading, spacing: 14) {
                            detailRow("Holder", value: pass.holderName, icon: "person.fill")
                            Divider()
                            detailRow("Card number", value: pass.maskedCardNumber, icon: "number")
                            Divider()
                            detailRow("Valid from", value: pass.validFrom.formatted(date: .long, time: .omitted), icon: "calendar")
                            Divider()
                            detailRow("Valid until", value: pass.validUntil.formatted(date: .long, time: .omitted), icon: "calendar.badge.checkmark")
                        }
                        .neoCard(padding: 16)

                        Text("This is a local reminder and is not a valid ticket for inspection. Keep your official Wiener Linien ticket with you.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Remove Jahreskarte", role: .destructive) {
                            showsRemovalConfirmation = true
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            } else {
                ContentUnavailableView {
                    Label("No Jahreskarte", systemImage: "wallet.pass")
                } description: {
                    Text("Save the validity of your annual pass and see when it needs renewal.")
                } actions: {
                    Button("Add Jahreskarte") { showsEditor = true }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("annualPass.add")
                }
            }
        }
        .neoScreen()
        .navigationTitle("Jahreskarte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.pass != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showsEditor = true }
                        .accessibilityIdentifier("annualPass.edit")
                }
            }
        }
        .sheet(isPresented: $showsEditor) {
            AnnualPassEditor(existing: store.pass)
                .environmentObject(store)
        }
        .confirmationDialog("Remove Jahreskarte?", isPresented: $showsRemovalConfirmation) {
            Button("Remove", role: .destructive) { store.remove() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes only the local reminder from Traffic Vienna.")
        }
    }

    private func detailRow(_ title: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(NeoDesign.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
    }
}

private struct AnnualPassCard: View {
    let pass: AnnualPass

    private var state: AnnualPassState { .evaluate(pass, on: .now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("WIENER LINIEN", systemImage: "tram.fill")
                    .font(.caption2.bold())
                    .tracking(1)
                Spacer()
                statusLabel
            }

            Spacer(minLength: 48)

            Text("Jahreskarte")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(pass.holderName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 3)

            Spacer(minLength: 28)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CARD")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.55))
                    Text(pass.maskedCardNumber)
                        .font(.subheadline.monospaced().weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("VALID UNTIL")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.55))
                    Text(pass.validUntil.formatted(.dateTime.month(.twoDigits).year()))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x172554), Color(hex: 0x1D4ED8), Color(hex: 0x2563EB)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 45, y: -55)
                .allowsHitTesting(false)
        }
        .shadow(color: Color.blue.opacity(0.22), radius: 22, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("annualPass.card")
    }

    @ViewBuilder private var statusLabel: some View {
        switch state {
        case .active(let days):
            Text(days == 0 ? "Last day" : "\(days) days left")
                .passStatus(color: .green)
        case .upcoming(let days):
            Text("Starts in \(days) days")
                .passStatus(color: .orange)
        case .expired:
            Text("Expired")
                .passStatus(color: .red)
        }
    }
}

private struct AnnualPassEditor: View {
    @EnvironmentObject private var store: AnnualPassStore
    @Environment(\.dismiss) private var dismiss
    @State private var holderName: String
    @State private var cardNumber: String
    @State private var validFrom: Date
    @State private var validUntil: Date

    init(existing: AnnualPass?) {
        _holderName = State(initialValue: existing?.holderName ?? "")
        _cardNumber = State(initialValue: existing?.cardNumber ?? "")
        _validFrom = State(initialValue: existing?.validFrom ?? .now)
        _validUntil = State(initialValue: existing?.validUntil ?? Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pass details") {
                    TextField("Holder name", text: $holderName)
                        .textContentType(.name)
                        .accessibilityIdentifier("annualPass.holder")
                    TextField("Card number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("annualPass.number")
                }
                Section("Validity") {
                    DatePicker("Valid from", selection: $validFrom, displayedComponents: .date)
                    DatePicker("Valid until", selection: $validUntil, in: validFrom..., displayedComponents: .date)
                }
                Section {
                    Text("Traffic Vienna stores this pass locally. It cannot verify, renew, or replace the official Wiener Linien ticket.")
                }
            }
            .navigationTitle(store.pass == nil ? "Add Jahreskarte" : "Edit Jahreskarte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.save(
                            holderName: holderName,
                            cardNumber: cardNumber,
                            validFrom: validFrom,
                            validUntil: validUntil
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("annualPass.save")
                }
            }
        }
    }

    private var canSave: Bool {
        !holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && validUntil >= validFrom
    }
}

private extension View {
    func passStatus(color: Color) -> some View {
        font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.22), in: Capsule())
    }
}

#Preview {
    NavigationStack { AnnualPassView() }
        .environmentObject(AnnualPassStore())
}
