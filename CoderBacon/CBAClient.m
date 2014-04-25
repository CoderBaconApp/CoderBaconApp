//
//  CBAClient.m
//  CoderBacon
//
//  Created by Justin Steffen on 4/24/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import "CBAClient.h"

NSString* const CBAClientErrorDomain = @"CBAClientErrorDomain";

@interface CBAClient ()
@property (strong, nonatomic) NSString* sessionKey;
@property (strong, nonatomic) NSNumber* userId;
@property (strong, nonatomic) NSURLSession* defaultUrlSession;
@end

@implementation CBAClient

- (id)init {
    self = [self initWithUserId:nil andSessionKey:nil];
    return self;
}

- (NSURL*)baseUrl {
    static NSURL* sharedUrl = nil;
    if (sharedUrl == nil) {
        sharedUrl = [NSURL URLWithString:API_BASE_URL];
    }
    return sharedUrl;
}

- (id)initWithUserId:(NSNumber*)userId andSessionKey:(NSString*)sessionKey {
    self = [super init];
    if (self) {
        self.sessionKey = sessionKey;
        self.userId = userId;
        NSURLSessionConfiguration* conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        conf.timeoutIntervalForResource = 150; // oh yeah
        self.defaultUrlSession = [NSURLSession sharedSession]; // use defaults here
    }
    
    return self;
}

-(NSString *)urlenc:(NSString *)val { // do i really have to write this shit by hand?!?
    CFStringRef safeString = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                     (CFStringRef)val,
                                                                     NULL,
                                                                     CFSTR("/%&=?$#+-~@<>|*,.()[]{}^!"),
                                                                     kCFStringEncodingUTF8);
    NSString* ret = (__bridge_transfer NSString*)safeString;
    return ret;
}

- (NSString*)queryStringForParams:(NSDictionary*)dict {
    NSString* ret = @"";
    for (id key in dict) {
        NSString* ekey = [self urlenc:[NSString stringWithFormat:@"%@", key]];
        NSString* eval = [self urlenc:[NSString stringWithFormat:@"%@", [dict valueForKey:key]]];
        
        ret = [ret stringByAppendingString:[NSString stringWithFormat:@"%@=%@&", ekey, eval]];
    }
    
    return [ret substringToIndex:[ret length] - 1]; // remove trailing &
}

- (NSURL*)urlForCall:(NSString*)callName {
    return [NSURL URLWithString:[NSString stringWithFormat:API_BASE_URL "%@", callName]];
}

- (NSURL*)urlForCall:(NSString*)callName withParams:(NSDictionary*)params {
    if ((params == nil) || (params.count == 0)) {
        return [self urlForCall:callName];
    }
    NSString* url = [NSString stringWithFormat:API_BASE_URL "%@?%@", callName, [self queryStringForParams:params]];
    return [NSURL URLWithString:url];
}

- (NSDictionary*)parseResponse:(NSData*)response withError:(NSError**)error {
    NSError* parseError = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:response options:0 error:&parseError];
    
    // did json parsing fail?
    if (dict == nil) {
        NSLog(@"[API] couldn't parse json for '%@': %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding], parseError);
        *error = [NSError errorWithDomain:CBAClientErrorDomain code:CBAClientResponseParseError userInfo:@{NSLocalizedDescriptionKey:[parseError localizedDescription] }];
        return nil;
    }
    
    // did the server return an error message?
    NSString* serverError = [dict valueForKey:@"error"];
    if(serverError != nil) {
        NSLog(@"[API] server returned error: %@", serverError);
        if(error != nil) {
            *error = [NSError errorWithDomain:CBAClientErrorDomain code:CBAClientApplicationError userInfo:@{NSLocalizedDescriptionKey: serverError }];
        }
        return nil;
    }
    
    // omg we have a value!
    return dict;
}

const NSString* boundary = @"CoderBaconAppFormBoundary";

- (NSData*)bodyForFormPost:(NSDictionary*)params {
    NSMutableData *body = [NSMutableData data];
    
    for (NSString* key in params) {
        id object = params[key];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([object isKindOfClass:[NSString class]]) {
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", object] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else if([object isKindOfClass:[NSData class]]) {
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"data.bin\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:object];
        }
        else if([object isKindOfClass:[UIImage class]]) {
            NSData *imageData = UIImageJPEGRepresentation(object, 0.6);
            if (imageData) {
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:imageData];
            }
        }
        else {
            NSLog(@"UNKNOWN PARAM TYPE for %@!!!!!!!!!!!!!!! <><><><><><>><><<><> ********* $$$$$$$$$ +!+!+!+!++!!+!+!+!+", key);
        }
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

- (void)makeApiCall:(NSString*)name withParams:(NSDictionary*)params andMethod:(NSString*)method onSuccess:(void(^)(NSDictionary* response))successHandler onError:(void(^)(NSError* err))errHandler {
    NSMutableURLRequest* request = nil;
    if (self.sessionKey != nil) {
        if (params == nil) params = [[NSMutableDictionary alloc] init];
        else params = [NSMutableDictionary dictionaryWithDictionary:params];
        ((NSMutableDictionary*)params)[@"session-id"] = self.sessionKey;
    }
    
    if ([method isEqual:@"POST"]) { // POST request
        request = [NSMutableURLRequest requestWithURL:[self urlForCall:name]];
        request.HTTPBody = [[self queryStringForParams:params] dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPMethod = method;
    }
    else if([method isEqual:@"POST-form"]) { // should probably try to autodetect this
        request = [NSMutableURLRequest requestWithURL:[self urlForCall:name]];
        request.HTTPBody = [self bodyForFormPost:params];
        request.HTTPMethod = @"POST";
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField: @"Content-Type"];
    }
    else { // GET request
        NSURL* url = [self urlForCall:name withParams:params];
        request = [NSMutableURLRequest requestWithURL:url];
    }
    
    //NSLog(@"request for %@(%@) is: %@", method, name, request);
    NSLog(@"[API] %@(%@)", method, name);
    NSURLSessionDataTask* task = [self.defaultUrlSession dataTaskWithRequest:request
                                                           completionHandler:^(NSData* data, NSURLResponse* response, NSError* networkError) {
                                                               if (data == nil) {
                                                                   NSLog(@"[API] got network error %@", networkError);
                                                                   if (errHandler) {
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           errHandler(networkError);
                                                                       });
                                                                   }
                                                               }
                                                               else {
                                                                   NSError* err = nil;
                                                                   
                                                                   NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                                                                   //      NSLog(@"  => %ld", (long)httpResp.statusCode);
                                                                   
                                                                   if ((httpResp.statusCode < 200) || (httpResp.statusCode >= 300)) {
                                                                       NSLog(@"[API] got non-2xx response code %ld for %@(%@)", (long)httpResp.statusCode, method, name);
                                                                       
                                                                       [self parseResponse:data withError:&err];
                                                                       if (err == nil) { // wasn't set by parser
                                                                           NSString* msg = [NSString stringWithFormat:@"non-200 code %ld", (long)httpResp.statusCode];
                                                                           err = [NSError errorWithDomain:CBAClientErrorDomain code:CBAClientNonSuccessResponseError userInfo:@{NSLocalizedDescriptionKey: msg, @"response-code": [NSNumber numberWithLong:httpResp.statusCode]}];
                                                                       }
                                                                       if (errHandler) {
                                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                                               errHandler(err);
                                                                           });
                                                                       }
                                                                   }
                                                                   else {
                                                                       NSDictionary* result = [self parseResponse:data withError:&err];
                                                                       if (result == nil) {
                                                                           NSLog(@"[API] parse response error: %@", err);
                                                                           if (errHandler) {
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   errHandler(err);
                                                                               });
                                                                           }
                                                                       }
                                                                       else {
                                                                           if (successHandler) {
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   successHandler(result);
                                                                               });
                                                                           }
                                                                       }
                                                                   }
                                                               }
                                                           }];
    
    [task resume];
}

- (NSDictionary*)makeBlockingApiCall:(NSString*)name withParams:(NSDictionary*)params andMethod:(NSString*)method andError:(NSError**)err {
    __block NSDictionary* ret = nil;
    dispatch_semaphore_t waiter = dispatch_semaphore_create(0);
    
    [self makeApiCall:name withParams:params andMethod:method onSuccess:^(NSDictionary* result) {
        ret = result;
        dispatch_semaphore_signal(waiter);
    } onError:^(NSError* e) {
        if(err != nil) *err = e;
        dispatch_semaphore_signal(waiter);
    }];
    
    dispatch_semaphore_wait(waiter, DISPATCH_TIME_FOREVER);
    return ret;
}

- (void)getUsersOnSuccess:(void(^)(NSDictionary* data))successHandler onError:(void(^)(NSError* err))errHandler {
    [self makeApiCall:[NSString stringWithFormat:@"users.json"] withParams:nil andMethod:@"GET" onSuccess:^(NSDictionary *response) {
        NSDictionary* dict = response;
        if (dict == nil) {
            NSLog(@"[API] couldn't extract user payload from json");
            NSError* err = [NSError errorWithDomain:CBAClientErrorDomain code:CBAClientNonSuccessResponseError userInfo:@{NSLocalizedDescriptionKey: @"invalid server response"}];
            if (errHandler) errHandler(err);
        } else {
            if (successHandler) successHandler(dict);
        }
    } onError:^(NSError *err) {
        if (errHandler) errHandler(err);
    }];
}

- (void)getUserFromId:(NSNumber*)userId onSuccess:(void(^)(NSDictionary* data))successHandler onError:(void(^)(NSError* err))errHandler {
    [self makeApiCall:[NSString stringWithFormat:@"users/%@.json", userId] withParams:nil andMethod:@"GET" onSuccess:^(NSDictionary *response) {
        NSDictionary* dict = response[@"response"][@"user"];
        if (dict == nil) {
            NSLog(@"[API] couldn't extract user payload from json");
            NSError* err = [NSError errorWithDomain:CBAClientErrorDomain code:CBAClientNonSuccessResponseError userInfo:@{NSLocalizedDescriptionKey: @"invalid server response"}];
            if (errHandler) errHandler(err);
        } else {
            if (successHandler) successHandler(dict);
        }
    } onError:^(NSError *err) {
        if (errHandler) errHandler(err);
    }];
}


@end

