//
//  ZAEventPusher.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/13.
//

#import <Foundation/Foundation.h>

#import "ZADefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZAEventPusher : NSObject

@property (nonatomic, assign) ZACommonParamsType commonParamsType;

- (void)pushEvent:(NSDictionary *)event
        debugMode:(ZADebugMode)debugMode
 completionHandler:(void(^)(BOOL isSuccess))completion;

- (void)pushEvents:(NSArray *)events
         debugMode:(ZADebugMode)debugMode
 completionHandler:(void(^)(BOOL isSuccess))completion;

/// 设置profile
- (void)requestSetProfile:(NSDictionary *)userInfo
                debugMode:(ZADebugMode)debugMode
                     type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
