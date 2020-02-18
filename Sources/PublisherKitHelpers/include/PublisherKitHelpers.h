//
//  PublisherKitHelpers.h
//  
//
//  Created by Raghav Ahuja on 09/02/20.
//

#ifndef PUBLISHERKITHELPERS_H
#define PUBLISHERKITHELPERS_H

#include <stdint.h>

#if __has_attribute(swift_name)
#define PUBLISHERKIT_SWIFT_NAME(_name) __attribute__((swift_name(#_name)))
#else
#define PUBLISHERKIT_SWIFT_NAME(_name)
#endif

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark - COMBINE IDENTIFIER

uint64_t publisherkit_combine_identifier(void)
    PUBLISHERKIT_SWIFT_NAME(_newCombineIdentifier());

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* PUBLISHERKITHELPERS_H */
