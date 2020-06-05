//
//  ZAEventSaver.h
//  ZADataAPI
//
//  Created by ZYM on 2020/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZAEventSaver : NSObject

@property (nonatomic, strong) NSMutableArray *events;   // 保存事件

- (void)addEvent:(NSDictionary *)event;
/// 保存未上传的事件到本地
- (void)saveEventsToLocal;
/// 读取本地保存的事件
- (NSArray *)readAllLocalEvents;
/// 清除本地事件
- (void)clearLocalEvents;

@end

NS_ASSUME_NONNULL_END
