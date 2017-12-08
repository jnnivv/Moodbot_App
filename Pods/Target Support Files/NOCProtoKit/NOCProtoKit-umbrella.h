#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NOCClient.h"
#import "NOCDispatcher.h"
#import "NOCGame.h"
#import "NOCProtoKit.h"

FOUNDATION_EXPORT double NOCProtoKitVersionNumber;
FOUNDATION_EXPORT const unsigned char NOCProtoKitVersionString[];

