//
//  URLSessionTaskPublisherDelegate.swift
//  PublisherKit
//
//  Created by Raghav Ahuja on 26/01/20.
//

import Foundation

protocol URLSessionTaskPublisherDelegate {
}

extension URLSessionTaskPublisherDelegate {
    
    func handleCompletion<Downstream: Subscriber>(subscriber: Subscriptions.Internal<Downstream, URLSession.DataTaskPKPublisher.Output, URLSession.DataTaskPKPublisher.Failure>) -> (Data?, URLResponse?, Error?) -> Void {
        
        let completion: (Data?, URLResponse?, Error?) -> Void = { [weak subscriber] (data, response, error) in
            
            guard let subscriber = subscriber else {
                return
            }
            
            subscriber.getLock().lock()
            guard !subscriber.isTerminated else {
                subscriber.getLock().unlock()
                return
            }

            subscriber.getLock().unlock()
            
            if let error = error {
                subscriber.receive(completion: .failure(error))
                
            } else if let response = response as? HTTPURLResponse, let data = data {
                subscriber.receive(input: (data, response))
                subscriber.receive(completion: .finished)
            } else {
                subscriber.receive(completion: .failure(URLError(.unknown)))
            }
        }
        
        return completion
    }
}
