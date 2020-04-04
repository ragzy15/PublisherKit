//
//  Record.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 04/04/20.
//

/// A publisher that allows for recording a series of inputs and a completion for later playback to each subscriber.
public struct Record<Output, Failure> : Publisher where Failure : Error {
    
    /// The recorded output and completion.
    public let recording: Recording
    
    /// Interactively record a series of outputs and a completion.
    public init(record: (inout Recording) -> Void) {
        var recording = Recording()
        record(&recording)
        self.recording = recording
    }
    
    /// Initialize with a recording.
    public init(recording: Recording) {
        self.recording = recording
    }
    
    /// Set up a complete recording with the specified output and completion.
    public init(output: [Output], completion: Subscribers.Completion<Failure>) {
        recording = Recording(output: output, completion: completion)
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
        if recording.output.isEmpty {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: recording.completion)
        } else {
            subscriber.receive(subscription: Inner(downstream: subscriber, sequence: recording.output, completion: recording.completion))
        }
    }
    
    /// A recorded set of `Output` and a `Subscribers.Completion`.
    public struct Recording {
        
        public typealias Input = Output
        
        private var _output: [Output]
        private var _completion: Subscribers.Completion<Failure>
        
        private var receivedCompletion = false
        
        /// The output which will be sent to a `Subscriber`.
        public var output: [Output] {
            _output
        }
        
        /// The completion which will be sent to a `Subscriber`.
        public var completion: Subscribers.Completion<Failure> {
            _completion
        }
        
        /// Set up a recording in a state ready to receive output.
        public init() {
            _output = []
            _completion = .finished
        }
        
        /// Set up a complete recording with the specified output and completion.
        public init(output: [Output], completion: Subscribers.Completion<Failure> = .finished) {
            _output = output
            _completion = completion
        }
        
        /// Add an output to the recording.
        ///
        /// A `fatalError` will be raised if output is added after adding completion.
        public mutating func receive(_ input: Record<Output, Failure>.Recording.Input) {
            precondition(!receivedCompletion, "Cannot receive input after receiving completion.")
            
            _output.append(input)
        }
        
        /// Add a completion to the recording.
        ///
        /// A `fatalError` will be raised if more than one completion is added.
        public mutating func receive(completion: Subscribers.Completion<Failure>) {
            precondition(!receivedCompletion, "Cannot receive more than one completion.")
            
            receivedCompletion = true
            _completion = completion
        }
        
        private enum CodingKeys: String, CodingKey {
            case output
            case completion
        }
    }
}

extension Record: Codable where Output: Decodable, Output: Encodable, Failure: Decodable, Failure: Encodable { }

extension Record.Recording: Codable where Output: Decodable, Output: Encodable, Failure: Decodable, Failure: Encodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _output = try container.decode([Output].self, forKey: .output)
        _completion = try container.decode(Subscribers.Completion<Failure>.self, forKey: .completion)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(completion, forKey: .completion)
        try container.encode(output, forKey: .output)
    }
}

extension Record {
    
    // MARK: RECORD SINK
    private class Inner<Downstream: Subscriber>: Subscription, CustomStringConvertible, CustomPlaygroundDisplayConvertible, CustomReflectable where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private var downstream: Downstream?
        private var sequence: [Output]?
        private var completion: Subscribers.Completion<Failure>?
        
        private var iterator: IndexingIterator<[Output]>
        private var next: Output?
        
        private var downstreamDemand = Subscribers.Demand.none
        private var isActive = false
        
        private let lock = Lock()
        
        init(downstream: Downstream, sequence: [Output], completion: Subscribers.Completion<Failure>) {
            self.downstream = downstream
            self.sequence = sequence
            self.completion = completion
            
            iterator = sequence.makeIterator()
            next = iterator.next()
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock()
            guard downstream != nil else { lock.unlock(); return }
            downstreamDemand += demand
            
            if isActive { lock.unlock(); return }

            while let downstream = downstream, downstreamDemand > .none {
                if let element = next {
                    downstreamDemand -= 1
                    let nextElement = iterator.next()
                    isActive = true
                    lock.unlock()
                    
                    let additionalDemand = downstream.receive(element)
                    
                    lock.lock()
                    isActive = false
                    downstreamDemand += additionalDemand
                    self.next = nextElement
                }

                if next == nil, let completion = completion {
                    self.downstream = nil
                    self.sequence = nil
                    lock.unlock()
                    
                    downstream.receive(completion: completion)
                    return
                }
            }

            lock.unlock()
        }

        func cancel() {
            lock.lock()
            downstream = nil
            sequence = nil
            completion = nil
            lock.unlock()
        }
        
        var description: String {
            lock.lock()
            defer { lock.unlock() }
            
            return sequence.map { $0.description } ?? "Cancelled Events"
        }
        
        var playgroundDescription: Any {
            description
        }
        
        var customMirror: Mirror {
            lock.lock()
            defer { lock.unlock() }
            
            if downstream == nil {
                return Mirror(self, children: [("some", "Cancelled Events")])
            }
            
            let children: [Mirror.Child] = [
                ("sequence", sequence as Any),
                ("completion", completion as Any)
            ]
            
            return Mirror(self, children: children)
        }
    }
}
