### zlyq-ios-sdk

##### 1. `CocoaPods`集成
```
pod 'ZLYQAnalyticsSDK'
```

##### 2. 初始化
导入头文件`#import <ZLYQAnalyticsSDK/ZADataAPI>`
```
[[ZADataAPI share] configWithProjectID:projectID
                                appKey:appKey
                                apiKey:apiKey
                                server:server
                        uploadDuration:duration
                            uploadCount:count
```
`projectID`、`appKey`、`apiKey`、`server`在私有化部署后获取，其中`appKey`需要添加到工程的`scheme`中，调试`debugMode`时需要唤起APP使用;

`duration`指定触发上传的间隔时间, 如果`duration`等于0,使用默认的15秒, 如果`duration`小于0,取消定时任务;

`count`指定触发上传的条数。

##### 3. 指定事件
App用户登录时调用`loginWithUserID`传入`userID`,退出登录时调用`logout`清除登录信息

##### 4. 更新用户画像
根据需要调用下面的方法,**`increaseProfile`只能传入`value`是数值类型的信息**
```
- (void)setProfile:(NSDictionary *)profileInfo;
- (void)setOnceProfile:(NSDictionary *)profileInfo;
- (void)appendProfile:(NSDictionary *)profileInfo;
- (void)increaseProfile:(NSDictionary *)profileInfo;
- (void)deleteProfile:(NSDictionary *)profileInfo;
- (void)unsetProfile:(NSDictionary *)profileInfo;
```

##### 5. 埋点
普通上传
```
+ (void)addEvent:(NSString *)eventName info:(nullable NSDictionary *)info
```
实时上传
传入事件名称和时间对应的属性
```
+ (void)addEvent:(NSString *)eventName info:(nullable NSDictionary *)info shouldDelay:(BOOL)shouldDelay
```
当`shouldDelay`值为`false`时,该事件实时上传,值为`true`时,等于普通上传

###### 6. 登录、退出登录更新`userId`
登录成功后，传入`userId`
```
- (void)loginWithUserID:(NSString *)userID;
```
退出登录，清空`userId`
```
- (void)logout;
```

##### 其它
提供了获取事件公共参数的方法, 用作服务端埋点时保证数据的完整性
```
- (NSDictionary *)commonParams;
```
