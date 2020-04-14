//
//  CombineIdentifier.cpp
//  PublisherKit
//
//  Created by Raghav Ahuja on 09/02/20.
//

#include "CombineIdentifier.h"

#include <atomic>

namespace {

std::atomic<uint64_t> new_combine_identifier;

}

extern "C" {

uint64_t publisherkit_combine_identifier(void) {
    return new_combine_identifier.fetch_add(1);
}

} // extern "C"
