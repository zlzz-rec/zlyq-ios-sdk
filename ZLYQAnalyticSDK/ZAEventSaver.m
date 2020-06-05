//
//  ZAEventSaver.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/13.
//

#import "ZAEventSaver.h"

@interface ZAEventSaver ()

@property (nonatomic, strong) NSLock *readLock;
@property (nonatomic, strong) NSLock *writeLock;

@end

static NSString *const local_events_key = @"sk_local_events_key";
@implementation ZAEventSaver

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.events = [NSMutableArray array];
    }
    return self;
}

#pragma mark - actions
- (void)addEvent:(NSDictionary *)event {
    [self.events addObject:event];
}

/// 保存未上传的事件到本地
- (void)saveEventsToLocal {
    NSMutableArray *localEvents = [NSMutableArray array];
    [localEvents addObjectsFromArray:[self readAllLocalEvents]];
    
    [self.writeLock lock];
    [localEvents addObjectsFromArray:self.events];
    [[NSUserDefaults standardUserDefaults] setValue:localEvents forKey:local_events_key];
    [self.events removeAllObjects];
    [self.writeLock unlock];
}

/// 读取本地保存的事件
- (NSArray *)readAllLocalEvents {
    [self.readLock lock];
    NSArray *localEvents = [[NSUserDefaults standardUserDefaults] arrayForKey:local_events_key];
    [self.readLock unlock];
    
    if (localEvents.count == 0) {
        return @[];
    }
    return localEvents;
}

/// 清除本地事件
- (void)clearLocalEvents {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:local_events_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - lazy
- (NSLock *)readLock {
    if (!_readLock) {
        _readLock = [[NSLock alloc] init];
    }
    return _readLock;
}

- (NSLock *)writeLock {
    if (!_writeLock) {
        _writeLock = [[NSLock alloc] init];
    }
    return _writeLock;
}

@end
