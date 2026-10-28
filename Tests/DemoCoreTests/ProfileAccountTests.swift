import XCTest
@testable import DemoCore

final class ProfileAccountTests: XCTestCase {
    func isolated(_ work: (LocalPersistence, UserDefaults) throws -> Void) throws {
        let suite = "ChaseDemo.ProfileTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        try work(LocalPersistence(defaults: defaults), defaults)
    }
    func testFullNameValidationTrimmingAndOptionalMiddle() throws {
        let profile = try LocalProfile(firstName: " Élodie-Marie ", lastName: " O’Neil-Vale \n", middleName: " Anne ")
        XCTAssertEqual(profile.fullName, "Élodie-Marie Anne O’Neil-Vale"); XCTAssertTrue(profile.isComplete)
        XCTAssertEqual(try LocalProfile(firstName: "Avery", lastName: "Collins", middleName: " \n").fullName, "Avery Collins")
        for empty in ["", " \n\t"] {
            XCTAssertThrowsError(try LocalProfile(firstName: empty, lastName: "Collins"))
            XCTAssertThrowsError(try LocalProfile(firstName: "Avery", lastName: empty))
        }
    }
    func testLegacyFirstNameRequiresCompletion() throws {
        let data = try JSONSerialization.data(withJSONObject: ["firstName": "Avery"])
        let profile = try JSONDecoder().decode(LocalProfile.self, from: data)
        XCTAssertFalse(profile.isComplete); XCTAssertEqual(profile.firstName, "Avery"); XCTAssertEqual(profile.lastName, "")
    }
    func testInclusiveBalanceBoundsAndUniquePaddedSuffixes() {
        let lower = AccountInitialization.generate { $0.lowerBound }
        XCTAssertEqual(lower.map(\.cents), [100000, 200000]); XCTAssertEqual(lower.map(\.suffix), ["0000", "0001"])
        let upper = AccountInitialization.generate { $0.upperBound }
        XCTAssertEqual(upper.map(\.cents), [300000, 400000]); XCTAssertEqual(upper.map(\.suffix), ["9999", "9998"])
        XCTAssertEqual(AccountInitialization.suffix(7), "0007"); XCTAssertEqual(AccountInitialization.suffix(90), "0090")
        var values = [123456, 234567, 7, 7]
        let independent = AccountInitialization.generate { _ in values.removeFirst() }
        XCTAssertEqual(independent.map(\.cents), [123456, 234567]); XCTAssertEqual(independent.map(\.suffix), ["0007", "0008"])
    }
    func testRandomizedAccountsStayInRanges() {
        for _ in 0..<500 {
            let accounts = AccountInitialization.generate()
            XCTAssertTrue((100000...300000).contains(accounts[0].cents)); XCTAssertTrue((200000...400000).contains(accounts[1].cents))
            XCTAssertNotEqual(accounts[0].suffix, accounts[1].suffix)
            for account in accounts { XCTAssertEqual(account.suffix?.count, 4); XCTAssertTrue(PhoneNumber.isASCII(account.suffix!)) }
        }
    }
    func testNewProfilePersistsBalancesSuffixesAndNamesAcrossLaunches() throws {
        try isolated { repository, _ in
            var state = try repository.load()
            XCTAssertFalse(state.accountsInitialized)
            try state.onboard(firstName: "Avery", lastName: "Collins", middleName: "Lane", draw: { $0.lowerBound })
            let accounts = state.ledger.accounts
            XCTAssertEqual(accounts.map(\.cents), [100000, 200000])
            try repository.save(state)
            var restored = try repository.load()
            XCTAssertEqual(restored.ledger.accounts, accounts); XCTAssertEqual(restored.profile?.fullName, "Avery Lane Collins")
            try restored.onboard(firstName: "Élodie", lastName: "O'Neil", draw: { range in XCTFail("Must not regenerate existing accounts"); return range.lowerBound })
            XCTAssertEqual(restored.ledger.accounts, accounts)
            try repository.save(restored); XCTAssertEqual(try repository.load().ledger.accounts, accounts)
            restored.resetDemo(); XCTAssertEqual(restored.ledger.accounts, accounts); XCTAssertEqual(restored.profile?.fullName, "Élodie O'Neil")
        }
    }
    func testLegacyBalancesAndHistoricalAccountSnapshotsSurviveMigration() throws {
        try isolated { repository, defaults in
            var state = LocalState(accountsInitialized: true)
            state.ledger.accounts = [Account(id: "checking", label: "CHECKING (..5020)", cents: 98765), Account(id: "savings", label: "SAVINGS (..5020)", cents: 700000)]
            let now = Date(timeIntervalSince1970: 1_800_000_000)
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            var draft = Draft(recipient: Demo.recipients[0], now: now, calendar: calendar); draft.amount = try CurrencyInput(digits: "500")
            let payment = try state.ledger.submit(draft, id: UUID(), sender: "Avery", now: now, calendar: calendar)
            var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
            json["profile"] = ["firstName": "Avery"]; json.removeValue(forKey: "accountsInitialized"); json.removeValue(forKey: "startingAccounts")
            defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: LocalPersistence.storageKey)
            var migrated = try repository.load()
            XCTAssertEqual(migrated.ledger.accounts.map(\.cents), [98265, 700000]); XCTAssertEqual(migrated.ledger.payments, [payment])
            XCTAssertFalse(migrated.profile!.isComplete); XCTAssertNotEqual(migrated.ledger.accounts[0].suffix, migrated.ledger.accounts[1].suffix)
            let assigned = migrated.ledger.accounts
            try migrated.onboard(firstName: "Avery", lastName: "Collins")
            try repository.save(migrated)
            let loaded = try repository.load()
            XCTAssertEqual(loaded.ledger.accounts, assigned); XCTAssertEqual(loaded.ledger.payments, [payment]); XCTAssertTrue(loaded.profile!.isComplete)
        }
    }
    func testLabelsAndHistoricalSnapshotsDoNotFollowLaterProfileEdits() throws {
        var state = LocalState(); try state.onboard(firstName: "Avery", lastName: "Collins", draw: { $0.lowerBound })
        XCTAssertEqual(state.ledger.accounts[0].displayLabel(firstName: state.profile!.fullName), "AVERY COLLINS CHECKING (..0000)")
        XCTAssertEqual(state.ledger.accounts[1].displayLabel(firstName: state.profile!.fullName), "AVERY COLLINS SAVINGS (..0001)")
        let now = Date(timeIntervalSince1970: 1_800_000_000); let calendar = Calendar(identifier: .gregorian)
        var draft = Draft(recipient: Demo.recipients[0], now: now, calendar: calendar); draft.amount = try CurrencyInput(digits: "500")
        let payment = try state.ledger.submit(draft, id: UUID(), sender: state.profile!.fullName, now: now, calendar: calendar)
        try state.onboard(firstName: "Jordan", lastName: "Vale", middleName: "Reed")
        XCTAssertEqual(payment.account.label, "AVERY COLLINS CHECKING (..0000)"); XCTAssertEqual(payment.sender, "Avery Collins")
        XCTAssertEqual(state.ledger.payments, [payment]); XCTAssertEqual(state.ledger.accounts[0].displayLabel(firstName: state.profile!.fullName), "JORDAN REED VALE CHECKING (..0000)")
    }
}
