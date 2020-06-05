//
//  ZAEventDefaults.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/14.
//

#import "ZAEventDefaults.h"

#import "ZAEventTool.h"

static NSString *enterForgroundTimeinterval = @"";

@implementation ZAEventDefaults

#pragma mark - 内置事件
/// APP安装事件
+ (NSDictionary *)appInstallEvent {
    return @{
        @"utm" : @""
    };
}

/// APP启动事件
+ (NSDictionary *)appDidStartEvent {
    enterForgroundTimeinterval = [ZAEventTool timeStr];
    return @{ };
}

/// APP结束事件
+ (NSDictionary *)appDidEndEvent {
    NSTimeInterval startTime = [enterForgroundTimeinterval doubleValue];
    NSTimeInterval currentTime = [[ZAEventTool timeStr] doubleValue];
    NSTimeInterval duration = currentTime - startTime;
    return @{
        @"duration" : @(duration)
    };
}

@end
