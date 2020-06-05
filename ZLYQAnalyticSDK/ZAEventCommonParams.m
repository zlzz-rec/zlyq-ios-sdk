//
//  ZAEventCommonParams.m
//  ZADataAPI
//
//  Created by ZYM on 2020/5/15.
//

#import "ZAEventCommonParams.h"

#import "ZAEventTool.h"
#import "ZADataAPI.h"

@implementation ZAEventCommonParams

+ (NSDictionary *)commomPramsWithType:(ZACommonParamsType)type {
    if (type == ZACommonParamsTypeDefault) {
        return [self privateSDKParams];
    } else if (type == ZACommonParamsTypePlatform) {
        return [self platformParams];
    }
    return @{};
}

+ (NSString *)debugStringWithDebugModel:(ZADebugMode)debugMode {
    if (debugMode == ZADebugModeDebugAndImport) {
        return @"debug_and_import";
    } else if (debugMode == ZADebugModeDebugAndNotImport) {
        return @"debug_and_not_import";
    }
    return @"no_debug";
}

#pragma mark -

#pragma mark -私有化SDK参数
+ (NSDictionary *)privateSDKParams {
    return @{
        @"udid"             : [ZAEventTool udid],
        @"user_id"          : [ZADataAPI shareManager].userID,
        @"distinct_id"      : [ZADataAPI shareManager].distinctID,
        @"platform"         : [ZAEventTool platform],
        @"time"             : [ZAEventTool formatTime],
        @"sdk_type"         : [ZAEventTool SDKType],
        @"sdk_version"      : [ZAEventTool SDKVersion],
        @"screen_height"    : @([ZAEventTool screenHeight]),
        @"screen_width"     : @([ZAEventTool screenWidth]),
        @"manufacturer"     : [ZAEventTool deviceManufacture],
        @"model"            : [ZAEventTool deviceModel],
        @"network"          : [ZAEventTool network],
        @"os"               : [ZAEventTool deviceOS],
        @"os_version"       : [ZAEventTool deviceOSVersion],
        @"carrier"          : [ZAEventTool carrier],
        @"app_version"      : [ZAEventTool appVersion],
    };
}

#pragma mark -feed中台参数
+ (NSDictionary *)platformParams {
    return @{
        @"udid"             : [ZAEventTool udid],
        @"user_id"          : [ZADataAPI shareManager].userID,
        @"distinct_id"      : [ZADataAPI shareManager].distinctID,
        @"app_id"           : @"",
        @"platform"         : [ZAEventTool platform],
        @"time"             : [ZAEventTool formatTime],
        @"sdk_type"         : [ZAEventTool SDKType],
        @"sdk_version"      : [ZAEventTool SDKVersion],
        @"screen_height"    : @([ZAEventTool screenHeight]),
        @"screen_width"     : @([ZAEventTool screenWidth]),
        @"manufacturer"     : [ZAEventTool deviceManufacture],
        @"model"            : [ZAEventTool deviceModel],
        @"network"          : [ZAEventTool network],
        @"os"               : [ZAEventTool deviceOS],
        @"os_version"       : [ZAEventTool deviceOSVersion],
        @"carrier"          : [ZAEventTool carrier],
        @"app_version"      : [ZAEventTool appVersion],
    };
}

@end
