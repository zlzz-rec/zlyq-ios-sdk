//
//  ZAEventDefaults.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAEventDefaults : NSObject

/// APP安装事件
+ (NSDictionary *)appInstallEvent;
/// APP启动事件
+ (NSDictionary *)appDidStartEvent;
/// APP结束事件
+ (NSDictionary *)appDidEndEvent;

@end

NS_ASSUME_NONNULL_END
