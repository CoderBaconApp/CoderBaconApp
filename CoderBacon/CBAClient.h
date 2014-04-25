//
//  CBAClient.h
//  CoderBacon
//
//  Created by Justin Steffen on 4/24/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString* const CBAClientErrorDomain;
extern NSURL* const CBAClientApiBaseUrl;

#define API_BASE_URL @"http://localhost:3000/"

enum {
    CBAClientResponseParseError = 1000, // doesn't parse
    CBAClientResponseInvalidError, // e.g. parses but doesn't contain what i thought it should
    CBAClientNonSuccessResponseError, // e.g. non-200 response
    CBAClientApplicationError, // server reports an error
};

@interface CBAClient : NSObject

- (id)initWithUserId:(NSNumber*)userId andSessionKey:(NSString*)sessionKey;

// methods for users
- (void)getUsersOnSuccess:(void(^)(NSDictionary* data))successHandler onError:(void(^)(NSError* err))errHandler;
- (void)getUserFromId:(NSNumber*)userId onSuccess:(void(^)(NSDictionary* data))successHandler onError:(void(^)(NSError* err))errHandler;

// generic methods
- (NSURL*)baseUrl;
- (void)makeApiCall:(NSString*)name withParams:(NSDictionary*)params andMethod:(NSString*)method onSuccess:(void(^)(NSDictionary* response))successHandler onError:(void(^)(NSError* err))errHandler;

@end
