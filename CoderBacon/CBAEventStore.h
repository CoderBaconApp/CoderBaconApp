//
//  CBAEventStore.h
//  CoderBacon
//
//  Created by Justin Steffen on 3/25/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBAEventStore : NSObject

#pragma mark Class Methods
+ (instancetype)sharedStore;

#pragma mark Instance Methods
- (NSMutableDictionary *)createItem;
- (NSMutableDictionary *)currentEvent;
- (void)removeItem:(NSMutableDictionary *)item;
- (BOOL)saveChanges;

@end
