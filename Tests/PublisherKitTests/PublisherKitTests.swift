import XCTest
import Combine
@testable import PublisherKit

@available(OSX 10.15, iOS 13.0, tvOS 13.0, *)
final class PublisherKitTests: XCTestCase {
    
    static var allTests = [
        ("testExample", testExample, "testPerformanceExample", testPerformanceExample),
    ]
    
    var cancellable: AnyCancellable?
    var anyCancellable: NKAnyCancellable?
    
    var cancellables = Set<AnyCancellable>()
    var anyCancellables = Set<NKAnyCancellable>()
    
    let value = BindableValue<Int>(wrappedValue: 0)
    
    @BindableValue
    var x: Int = 5
    
    func testMerge() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2
        
        let pub1 = NotificationCenter.default.nkPublisher(for: .init("nn")).map(\.userInfo)
        
        anyCancellable = NotificationCenter.default.nkPublisher(for: .init("nn1")).map(\.userInfo)
            .merge(with: pub1)
            .sink(receiveCompletion: { (completion) in
                print(completion)
                expectation.fulfill()
            }) { (value) in
                print(value ?? [:])
                self.anyCancellable?.cancel()
        }
        NotificationCenter.default.post(name: .init("nn1"), object: nil, userInfo: ["edede": "okoko"])
        NotificationCenter.default.post(name: .init("nn"), object: nil, userInfo: ["heelo": "frfr"])
        
        
        wait(for: [expectation], timeout: 600)
    }
    
    func testCombineExtensions() {
        let expectation = XCTestExpectation()
        
        let c = NotificationCenter.default.publisher(for: .init("nn"))
            .compactMap {
                $0.userInfo
        }
        .map { _ in 1 }
        .filter {
            $0.isMultiple(of: 2)
            
        }
        .filter {
            $0.isMultiple(of: 2)
            
        }
        .sink { (value) in
            print(value)
            expectation.fulfill()
        }
        
        c.store(in: &cancellables)
        
        NotificationCenter.default.post(name: .init("nn"), object: nil, userInfo: ["heelo": "frfr"])
        
        wait(for: [expectation], timeout: 600)
    }
    
    func testCombineLatest() {
        let expectation = XCTestExpectation()
        
        let pub1 = NotificationCenter.default.nkPublisher(for: .init("nn"))
            .map(\.userInfo)
        
        let pub2 = NotificationCenter.default.nkPublisher(for: .init("nn11"))
        .map(\.userInfo)
        .combineLatest(pub1)
        
        let c = pub2.sink { (values) in
            print(values)
        }
        
        c.store(in: &anyCancellables)
        
        NotificationCenter.default.post(name: .init("nn"), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            NotificationCenter.default.post(name: .init("nn11"), object: nil)
            
            NotificationCenter.default.post(name: .init("nn"), object: nil)
        }
        
        wait(for: [expectation], timeout: 600)
    }
    
    func testLazySequence() {
        let pub = Publishers.Sequence<[Int], Never>(sequence: [5, 6, 6])
            .map {
                $0 * 2
        }
            .filter {
                $0.isMultiple(of: 2)
                
        }
        
        print(pub)
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
    
    func testDispatch() {
        let stride = DispatchQueue.SchedulerTimeType.Stride.init(.never)
        print(stride.magnitude)
    }
    
    
    func testExample() {
        let expectation = XCTestExpectation()
        
//        let pub = NotificationCenter.default.nkPublisher(for: .init("notificationName"))
//            .map(\.userInfo)
//            .eraseToAnyPublisher()
        
        let pub2 = URLSession.shared.nkTaskPublisher(for: URL(string: "https://5da1e9ae76c28f0014bbe25f.mockapkki.io/users")!)
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
    
    func testPerformanceExample() {
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 60)
    }
    
}
