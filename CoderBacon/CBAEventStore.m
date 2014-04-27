//
//  CBAEventStore.m
//  CoderBacon
//
//  Created by Justin Steffen on 3/25/14.
//  Copyright (c) 2014 Justin Steffen. All rights reserved.
//

#import "CBAEventStore.h"

@interface CBAEventStore ()

@property (nonatomic) NSMutableArray *privateItems;

@end

@implementation CBAEventStore

+ (instancetype)sharedStore {
    static CBAEventStore *sharedStore = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[self alloc] initPrivate];
    });
    
    return sharedStore;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[CBAEventStore sharedStore]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    
    if (self) {
        NSString *path = [self eventArchivePath];
        _privateItems = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        if(!_privateItems) {
            _privateItems = [[NSMutableArray alloc] init];
        }
    }
    
    return self;
}

- (NSArray *)allItems {
    return self.privateItems;
}

- (NSMutableDictionary *)createItem {
    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
    
    [self.privateItems addObject:item];
    
    return item;
}

- (NSMutableDictionary *)currentEvent {
    static NSMutableDictionary *currentEvent = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentEvent = [self.privateItems firstObject];
        
        if (!currentEvent) {
            currentEvent = [[CBAEventStore sharedStore] createItem];
        }
    });
    
    return currentEvent;
}


- (void)removeItem:(NSMutableDictionary *)item {
    [self.privateItems removeObjectIdenticalTo:item];
}

- (NSString *)eventArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDirectory = [documentDirectories firstObject];
    
    return [documentDirectory stringByAppendingPathComponent:@"events.archive"];
}

- (BOOL)saveChanges {
    NSString *path = [self eventArchivePath];
    
    return [NSKeyedArchiver archiveRootObject:self.privateItems toFile:path];
}

@end
