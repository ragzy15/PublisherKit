import XCTest
@testable import PublisherKit

final class PublisherKitTests: XCTestCase {
    
    static var allTests = [
        ("testMerge", testMerge, "testBindable", testBindable, "testURLSession", testURLSession),
    ]
    
    var anyCancellable: AnyCancellable?
    var anyCancellables = CancellableBag()
    
    let value = BindableValue<Int>(wrappedValue: 0)
    
    @BindableValue
    var x: Int = 5
    
    func testRemoveDuplicates() {
        
        struct Test {
            let value: Int
            let value1: Int
        }
        
        anyCancellable = NotificationCenter.default.pkPublisher(for: .init("test"))
            .map(\.userInfo)
            .compactMap({ (dict) -> Test? in
                dict?["key"] as? Test
            })
            .removeDuplicates(at: \.value)
            .sink(receiveCompletion: { (completion) in
                print(completion)
            }) { (value) in
                print(value)
        }
        
        NotificationCenter.default.post(name: .init("test"), object: nil, userInfo: ["key": Test(value: 10, value1: 10)])
        NotificationCenter.default.post(name: .init("test"), object: nil, userInfo: ["key": Test(value: 10, value1: 10)])
    }
    
    func testMerge() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        
        let pub1 = NotificationCenter.default.pkPublisher(for: .init("test")).map(\.userInfo)
        
        anyCancellable = NotificationCenter.default.pkPublisher(for: .init("test1")).map(\.userInfo)
            .merge(with: pub1)
            .sink(receiveCompletion: { (completion) in
                print(completion)
            }) { (value) in
                print(value ?? [:])
                expectation.fulfill()
        }
        NotificationCenter.default.post(name: .init("test1"), object: nil, userInfo: ["key1": "value1"])
        NotificationCenter.default.post(name: .init("test"), object: nil, userInfo: ["key2": "value2"])
        
        
        wait(for: [expectation], timeout: 600)
    }
    
    func testBindable() {
        let expectation = XCTestExpectation()
        
        value.bind { (newValue) in
            print(newValue)
        }
        
        anyCancellable = value.publisher.sink { (value) in
            print("Sink: \(value)")
        }
        
        value.wrappedValue = 5
        value.wrappedValue = 6
        value.wrappedValue = 7
        value.wrappedValue = 8
        value.wrappedValue = 9
        
        wait(for: [expectation], timeout: 600)
    }
    
    
    func testURLSession() {
        let expectation = XCTestExpectation()
        
        let pub2 = URLSession.shared.dataTaskPKPublisher(for: URL(string: "https://5da1e9ae76c28f0014bbe25f.mockapkki.io/users")!)
            .retry(2)
            .map(\.data)
            .receive(on: DispatchQueue.main)
        
        anyCancellable = pub2.sink(receiveCompletion: { (completion) in
            expectation.fulfill()
        }, receiveValue: { (data) in
            print(data)
        })
        
        wait(for: [expectation], timeout: 60)
    }
    
    override class var defaultPerformanceMetrics: [XCTPerformanceMetric] {
        return [
            XCTPerformanceMetric("com.apple.XCTPerformanceMetric_TransientHeapAllocationsKilobytes"),
            .wallClockTime
        ]
    }
}
