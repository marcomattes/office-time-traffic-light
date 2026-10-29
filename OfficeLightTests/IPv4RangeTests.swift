import Foundation
import Testing

@Suite struct IPv4RangeTests {
    @Test func parsesNetworkAndPrefixLength() throws {
        let range = try #require(IPv4Range("10.20.0.0/16"))
        #expect(range.network == 0x0A14_0000)
        #expect(range.prefixLength == 16)
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(IPv4Range("  192.168.1.0/24 ") != nil)
    }

    @Test(arguments: ["10.20.0.0", "10.20.0.0/33", "10.20.0/16", "256.0.0.0/8", "10.20.0.0/", "/16", "", "10.20.0.0/16/1", "10.20.0.0/-1"])
    func rejectsInvalidNotation(_ text: String) {
        #expect(IPv4Range(text) == nil)
    }

    @Test func containsAddressesInsideTheRange() throws {
        let range = try #require(IPv4Range("10.20.0.0/16"))
        #expect(range.contains(try address("10.20.0.1")))
        #expect(range.contains(try address("10.20.255.254")))
        #expect(!range.contains(try address("10.21.0.1")))
        #expect(!range.contains(try address("11.20.0.1")))
    }

    @Test func hostBitsInTheNetworkPartAreIgnored() throws {
        let range = try #require(IPv4Range("10.20.30.40/16"))
        #expect(range.contains(try address("10.20.0.1")))
    }

    @Test func prefixZeroMatchesEverything() throws {
        let range = try #require(IPv4Range("0.0.0.0/0"))
        #expect(range.contains(try address("203.0.113.9")))
    }

    @Test func prefix32MatchesOnlyTheAddressItself() throws {
        let range = try #require(IPv4Range("10.20.30.40/32"))
        #expect(range.contains(try address("10.20.30.40")))
        #expect(!range.contains(try address("10.20.30.41")))
    }

    @Test func slash24AroundAnAddress() throws {
        #expect(IPv4Range.slash24(around: try address("10.20.30.40")) == "10.20.30.0/24")
    }

    private func address(_ text: String) throws -> UInt32 {
        try #require(IPv4Range.address(text))
    }
}

@Suite struct InterfaceAddressTests {
    @Test func formatsAsDottedQuad() {
        #expect(InterfaceAddress.text(0xC0A8_0101) == "192.168.1.1")
        #expect(InterfaceAddress.text(0) == "0.0.0.0")
        #expect(InterfaceAddress.text(.max) == "255.255.255.255")
    }

    @Test func textAndParsingRoundTrip() throws {
        let value = try #require(IPv4Range.address("172.16.254.3"))
        #expect(InterfaceAddress(interface: "en0", value: value).text == "172.16.254.3")
    }
}
