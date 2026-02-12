//
//  iMOPS_HaccpTests.swift
//  iMOPS-HaccpTests
//
//  Created by Andreas Pelczer on 06.02.26.
//

import Testing
@testable import iMOPS_Haccp

// MARK: - ValueCoder Tests

struct ValueCoderTests {

    @Test func encodeString() {
        let result = ValueCoder.encode("Matjes")
        #expect(result == "S:Matjes")
    }

    @Test func encodeInt() {
        let result = ValueCoder.encode(42)
        #expect(result == "I:42")
    }

    @Test func encodeDouble() {
        let result = ValueCoder.encode(3.14)
        #expect(result == "D:3.14")
    }

    @Test func encodeBool() {
        let result = ValueCoder.encode(true)
        #expect(result == "B:true")
    }

    @Test func decodeString() {
        let result = ValueCoder.decode("S:Wässerung") as? String
        #expect(result == "Wässerung")
    }

    @Test func decodeInt() {
        let result = ValueCoder.decode("I:42") as? Int
        #expect(result == 42)
    }

    @Test func decodeDouble() {
        let result = ValueCoder.decode("D:3.14") as? Double
        #expect(result == 3.14)
    }

    @Test func decodeBool() {
        let result = ValueCoder.decode("B:true") as? Bool
        #expect(result == true)
    }

    @Test func roundTripString() {
        let original = "CCP-2: Lagertemperatur < 4°C"
        let encoded = ValueCoder.encode(original)!
        let decoded = ValueCoder.decode(encoded) as? String
        #expect(decoded == original)
    }

    @Test func roundTripInt() {
        let original = 15
        let encoded = ValueCoder.encode(original)!
        let decoded = ValueCoder.decode(encoded) as? Int
        #expect(decoded == original)
    }
}

// MARK: - BrainPath Tests

struct BrainPathTests {

    @Test func navPath() {
        let path = BrainPath.nav("LOCATION")
        #expect(path.raw == "^NAV.LOCATION")
    }

    @Test func sysPath() {
        let path = BrainPath.sys("STATUS")
        #expect(path.raw == "^SYS.STATUS")
    }

    @Test func taskPath() {
        let path = BrainPath.task("001", "TITLE")
        #expect(path.raw == "^TASK.001.TITLE")
    }

    @Test func archivePath() {
        let path = BrainPath.archive("001", "TIME")
        #expect(path.raw == "^ARCHIVE.001.TIME")
    }

    @Test func brigadePath() {
        let path = BrainPath.brigade("HARRY", "NAME")
        #expect(path.raw == "^BRIGADE.HARRY.NAME")
    }

    @Test func pathDescription() {
        let path = BrainPath.task("001", "STATUS")
        #expect(path.description == "^TASK.001.STATUS")
    }
}

// MARK: - RAMState Tests

struct RAMStateTests {

    @Test func setAndGet() {
        let state = RAMState()
        state.set(path: "^TASK.001.TITLE", value: "MATJES WÄSSERN")
        #expect(state.get(path: "^TASK.001.TITLE") == "MATJES WÄSSERN")
    }

    @Test func kill() {
        let state = RAMState()
        state.set(path: "^TASK.001.TITLE", value: "TEST")
        state.kill(path: "^TASK.001.TITLE")
        #expect(state.get(path: "^TASK.001.TITLE") == nil)
    }

    @Test func killTree() {
        let state = RAMState()
        state.set(path: "^TASK.001.TITLE", value: "TEST")
        state.set(path: "^TASK.001.STATUS", value: "OPEN")
        state.set(path: "^TASK.001.WEIGHT", value: "10")
        state.set(path: "^TASK.002.TITLE", value: "OTHER")
        state.killTree(prefix: "^TASK.001")
        #expect(state.get(path: "^TASK.001.TITLE") == nil)
        #expect(state.get(path: "^TASK.001.STATUS") == nil)
        #expect(state.get(path: "^TASK.002.TITLE") == "OTHER")
    }

    @Test func count() {
        let state = RAMState()
        state.set(path: "^A", value: "1")
        state.set(path: "^B", value: "2")
        #expect(state.count == 2)
    }

    @Test func removeAll() {
        let state = RAMState()
        state.set(path: "^A", value: "1")
        state.set(path: "^B", value: "2")
        state.removeAll()
        #expect(state.count == 0)
    }
}

// MARK: - StateDiff Tests

struct StateDiffTests {

    @Test func noDiff() {
        let old = RAMState()
        old.set(path: "^A", value: "1")
        let new = RAMState()
        new.set(path: "^A", value: "1")
        let diff = StateDiff.between(old: old, new: new)
        #expect(diff.isEmpty)
    }

    @Test func detectAdded() {
        let old = RAMState()
        let new = RAMState()
        new.set(path: "^A", value: "1")
        let diff = StateDiff.between(old: old, new: new)
        #expect(diff.added["^A"] == "1")
        #expect(diff.removed.isEmpty)
        #expect(diff.changed.isEmpty)
    }

    @Test func detectRemoved() {
        let old = RAMState()
        old.set(path: "^A", value: "1")
        let new = RAMState()
        let diff = StateDiff.between(old: old, new: new)
        #expect(diff.removed["^A"] == "1")
        #expect(diff.added.isEmpty)
    }

    @Test func detectChanged() {
        let old = RAMState()
        old.set(path: "^A", value: "1")
        let new = RAMState()
        new.set(path: "^A", value: "2")
        let diff = StateDiff.between(old: old, new: new)
        #expect(diff.changed["^A"]?.from == "1")
        #expect(diff.changed["^A"]?.to == "2")
    }

    @Test func summaryNotEmpty() {
        let old = RAMState()
        let new = RAMState()
        new.set(path: "^TASK.001.TITLE", value: "NEU")
        let diff = StateDiff.between(old: old, new: new)
        #expect(!diff.summary.isEmpty)
        #expect(diff.summary.contains("ADDED"))
    }
}

// MARK: - Replayer Tests

struct ReplayerTests {

    @Test func fullReplay() {
        let events = [
            iMOPSEvent(type: .set, path: "^TASK.001.TITLE", value: "S:MATJES", sequenceNumber: 0),
            iMOPSEvent(type: .set, path: "^TASK.001.STATUS", value: "S:OPEN", sequenceNumber: 1)
        ]
        let replayer = Replayer()
        let state = replayer.replay(events: events, mode: .full)
        #expect(state.get(path: "^TASK.001.TITLE") == "S:MATJES")
        #expect(state.get(path: "^TASK.001.STATUS") == "S:OPEN")
    }

    @Test func replayWithKill() {
        let events = [
            iMOPSEvent(type: .set, path: "^A", value: "S:test", sequenceNumber: 0),
            iMOPSEvent(type: .kill, path: "^A", sequenceNumber: 1)
        ]
        let replayer = Replayer()
        let state = replayer.replay(events: events, mode: .full)
        #expect(state.get(path: "^A") == nil)
    }

    @Test func replayWithCountLimit() {
        let events = [
            iMOPSEvent(type: .set, path: "^A", value: "S:first", sequenceNumber: 0),
            iMOPSEvent(type: .set, path: "^B", value: "S:second", sequenceNumber: 1),
            iMOPSEvent(type: .set, path: "^C", value: "S:third", sequenceNumber: 2)
        ]
        let replayer = Replayer()
        let state = replayer.replay(events: events, mode: .untilEventCount(2))
        #expect(state.get(path: "^A") == "S:first")
        #expect(state.get(path: "^B") == "S:second")
        #expect(state.get(path: "^C") == nil)
    }

    @Test func emptyReplay() {
        let replayer = Replayer()
        let state = replayer.replay(events: [], mode: .full)
        #expect(state.count == 0)
    }
}

// MARK: - TheBrain Core Tests

struct TheBrainTests {

    @Test func setAndGet() {
        let brain = TheBrain.shared
        brain.set("^TEST.VALUE", "hello", audit: false)
        let result: String? = brain.get("^TEST.VALUE")
        #expect(result == "hello")
        brain.kill("^TEST.VALUE", audit: false)
    }

    @Test func invalidPathRejected() {
        let brain = TheBrain.shared
        brain.set("INVALID_NO_CARET", "test", audit: false)
        let result: String? = brain.get("INVALID_NO_CARET")
        #expect(result == nil)
    }

    @Test func killRemovesKey() {
        let brain = TheBrain.shared
        brain.set("^TEST.KILL_ME", "bye", audit: false)
        brain.kill("^TEST.KILL_ME", audit: false)
        let result: String? = brain.get("^TEST.KILL_ME")
        #expect(result == nil)
    }

    @Test func killTreeRemovesSubtree() {
        let brain = TheBrain.shared
        brain.set("^TEST.TREE.A", "a", audit: false)
        brain.set("^TEST.TREE.B", "b", audit: false)
        brain.killTree(prefix: "^TEST.TREE", audit: false)
        let a: String? = brain.get("^TEST.TREE.A")
        let b: String? = brain.get("^TEST.TREE.B")
        #expect(a == nil)
        #expect(b == nil)
    }

    @Test func getOpenTaskIDs() {
        let brain = TheBrain.shared
        brain.set("^TASK.T1.STATUS", "OPEN", audit: false)
        brain.set("^TASK.T1.TITLE", "Test 1", audit: false)
        brain.set("^TASK.T2.STATUS", "OPEN", audit: false)
        brain.set("^TASK.T2.TITLE", "Test 2", audit: false)
        let ids = brain.getOpenTaskIDs()
        #expect(ids.contains("T1"))
        #expect(ids.contains("T2"))
        // Cleanup
        brain.killTree(prefix: "^TASK.T1", audit: false)
        brain.killTree(prefix: "^TASK.T2", audit: false)
    }
}

// MARK: - EmployeeAuthentication Tests

struct EmployeeAuthenticationTests {

    @Test func pinHashDeterministic() {
        let hash1 = EmployeeAuthentication.hashPIN("1234")
        let hash2 = EmployeeAuthentication.hashPIN("1234")
        #expect(hash1 == hash2)
    }

    @Test func differentPinsDifferentHashes() {
        let hash1 = EmployeeAuthentication.hashPIN("1234")
        let hash2 = EmployeeAuthentication.hashPIN("5678")
        #expect(hash1 != hash2)
    }

    @Test func pinAuthSuccess() throws {
        let pin = "4321"
        let hash = EmployeeAuthentication.hashPIN(pin)
        let result = try EmployeeAuthentication.authenticateWithPIN(
            employeeId: "HARRY",
            pin: pin,
            storedHash: hash
        )
        #expect(result.employeeId == "HARRY")
        #expect(result.method == .pin)
    }

    @Test func pinAuthFailure() {
        let hash = EmployeeAuthentication.hashPIN("1234")
        #expect(throws: AuthError.self) {
            try EmployeeAuthentication.authenticateWithPIN(
                employeeId: "HARRY",
                pin: "wrong",
                storedHash: hash
            )
        }
    }
}
