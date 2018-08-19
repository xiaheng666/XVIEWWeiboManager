//
//  XVIEWWeiboManager.m
//  XVIEW2.0
//
//  Created by njxh on 16/11/28.
//  Copyright © 2016年 南京 夏恒. All rights reserved.
//

#import "XVIEWWeiboManager.h"
#import "WeiboSDK.h"
@interface XVIEWWeiboManager() <WeiboSDKDelegate>
@property (nonatomic, copy) void (^weiboCallbackBlock) (XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData);  //回调的状态码， 返回的数据
@property (nonatomic, strong) NSString *appKeyString;    //微博的AppID
@property (nonatomic, strong) NSString *appSecretString; //微博的密钥
@property (nonatomic, strong) NSString *wbRedirectUrl;   //回调网址
@property (nonatomic, strong) NSString *wbAuthoUrl;      //微博根据用户id获取用户信息URL

@end
@implementation XVIEWWeiboManager

+ (instancetype)shareXVIEWWeiboManager {
    static XVIEWWeiboManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[XVIEWWeiboManager alloc] init];
    });
    return _instance;
}
+ (BOOL)isWeiboAppInstalled {
    return [WeiboSDK isWeiboAppInstalled];
}
- (instancetype)init {
    if (self = [super init]) { }
    return self;
}
- (BOOL)XVIEWWeiboSDKCallbackUrl:(NSURL *)url {
    return [WeiboSDK handleOpenURL:url delegate:self];
}
- (void)registerXVieweiboAppKey:(NSString *)wbAppKey
             weiboAppSecret:(NSString *)wbAppSecret
                redirectUrl:(NSString *)redirectUrl
            enableDebugMode:(BOOL)enabled {
    self.appKeyString = wbAppKey;
    self.appSecretString = wbAppSecret;
    self.wbRedirectUrl = redirectUrl;
    [WeiboSDK enableDebugMode:enabled];
    [WeiboSDK registerApp:self.appKeyString];
}
- (void)registerXViewWeiBoAppSecret:(NSString *)appSecret {
    if (![appSecret isEqualToString:self.appSecretString]) {
        self.appSecretString = appSecret;
    }
}
#pragma mark ==qq分享、支付、登录
- (void)XVIEWSDKWeiboParameters:(NSDictionary *)parameters contentType:(XVIEWSDKPlatfromType)type callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock {
    self.weiboCallbackBlock = callbackBlock;
    if (type == XVIEWSDKTypeWeiboLogin) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self XVIEWWeiboLogin];
        });
    }
    else if (type == XVIEWSDKTypeWeiboShare) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shareWithParameters:parameters type:type];
        });
    }
}
- (void)shareWithParameters:(NSDictionary *)parameters type:(XVIEWSDKPlatfromType)type {
    WBMessageObject *message = [WBMessageObject message];
    if ([parameters[@"sharetype"] isEqualToString:@"text"]) {
        message.text = NSLocalizedString(parameters[@"sharetype"], nil);
    } else if ([parameters[@"sharetype"] isEqualToString:@"image"]) {
        WBImageObject *image = [WBImageObject object];
        image.imageData = parameters[@"imageurl"];
        message.imageObject = image;
    } else {
        WBWebpageObject *webpage = [WBWebpageObject object];
        webpage.objectID = @"identifier1";
        webpage.title = NSLocalizedString(parameters[@"title"], nil);
        webpage.description = NSLocalizedString(parameters[@"description"], nil);
        webpage.thumbnailData = parameters[@"thumburl"];
        webpage.webpageUrl = parameters[@"shareurl"];
        
        message.mediaObject = webpage;
        message.text = NSLocalizedString(parameters[@"description"], nil);
    }
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = self.wbRedirectUrl;
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
    request.userInfo = @{@"ShareMessageFrom": @"ViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
}

#pragma mark ==分享到微博==
- (void)XVIEWWeiboShareParametersWithTitle:(NSString *)title
                               description:(NSString *)description
                                       url:(NSString *)url
                                thumbImage:(id)thumbImage {
    //分享多媒体文件
    WBWebpageObject *webpage = [WBWebpageObject object];
    webpage.objectID = @"identifier1";
    webpage.title = NSLocalizedString(title, nil);
    webpage.description = NSLocalizedString(description, nil);
    webpage.thumbnailData = [self dataWithThumbImage:thumbImage];
    webpage.webpageUrl = url;
    
    WBMessageObject *message = [WBMessageObject message];
    message.mediaObject = webpage;
    message.text = NSLocalizedString(description, nil);
    [self share:message];
}

- (void)share:(WBMessageObject *)messageObject {
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = @"https://api.weibo.com/oauth2/default.html";
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:messageObject authInfo:authRequest access_token:nil];
    request.userInfo = @{@"ShareMessageFrom": @"ViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
}

- (NSData *)dataWithThumbImage:(id)thumbImage {
    if ([thumbImage isKindOfClass:[NSString class]]) {
        return [NSData dataWithContentsOfFile:thumbImage];
    }
    else if ([thumbImage isKindOfClass:[UIImage class]]) {
        return UIImagePNGRepresentation(thumbImage);
    }
    else if ([thumbImage isKindOfClass:[NSData class]]) {
        return thumbImage;
    }
    return nil;
}
#pragma mark ==微博登陆方法==
- (void)XVIEWWeiboLogin {
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = self.wbRedirectUrl;
    request.scope = @"all";
    request.userInfo = @{@"SSO_From": @"ViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
}
#pragma mark ==微博登陆成功之后回调信息==
- (void)weiboLoginSuccess:(NSDictionary *)dict {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@&uid=%@", @"https://api.weibo.com/2/users/show.json", dict[@"access_token"], dict[@"uid"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (self.weiboCallbackBlock) {
                self.weiboCallbackBlock(XVIEWSDKCodeSuccess, @{@"code":@"-1", @"data":@{@"result": error.localizedDescription, @"type":@"weiboLogin"}, @"message":@"微博登录失败"});
            }
            return ;
        }
        NSError *myerror;
        NSDictionary *mydict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&myerror];
        if (myerror) {
            if (self.weiboCallbackBlock) {
                self.weiboCallbackBlock(XVIEWSDKCodeSuccess, @{@"code":@"-1", @"data":@{@"result": myerror.localizedDescription, @"type":@"weiboLogin"}, @"message": @"微博登录失败"});
            }
            return ;
        }
        if (self.weiboCallbackBlock) {
            NSDictionary *callbackDict = @{@"type":@"weiboLogin",
                                           @"openid":mydict[@"idstr"],
                                           @"unionid":@"",
                                           @"nickname":mydict[@"screen_name"],
                                           @"headimgurl":mydict[@"profile_image_url"],
                                           @"sex":([mydict[@"gender"] isEqualToString:@"m"] || [mydict[@"gender"] isEqualToString:@"n"]) ? ([mydict[@"gender"] isEqualToString:@"m"] ? @"1" : @"0") : @"2",
                                           @"access_token":dict[@"access_token"],
                                           @"refresh_token":dict[@"refresh_token"]};
            self.weiboCallbackBlock(XVIEWSDKCodeSuccess, @{@"code":@"0", @"data":callbackDict, @"message":@"微博登录成功"});
        }
    }];
    [task resume];
}


#pragma mark - WeiboSDKDelegate
- (void)didReceiveWeiboRequest:(WBBaseRequest *)request {

}
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response {
    //微博登陆
    if ([response isKindOfClass:WBAuthorizeResponse.class]) {
        if (response.statusCode == 0) {
            if (response.userInfo != nil)
                [self weiboLoginSuccess:response.userInfo];
        }
        else {
            [self callbackWeiboResponse:response];
        }
    }
    //微博分享
    else if ([response isKindOfClass:WBSendMessageToWeiboResponse.class]) {
        if (response.statusCode == 0) {
            if (_weiboCallbackBlock)
                self.weiboCallbackBlock(XVIEWSDKCodeSuccess, @{@"code": @"0", @"data":@{@"result":@"微博分享成功", @"type":@"weiboShare"}, @"message":@"微博分享成功"});
        }
        else {
            [self callbackWeiboResponse:response];
        }
    }
}
- (void)callbackWeiboResponse:(WBBaseResponse *)response {
    if (self.weiboCallbackBlock) {
        NSString *result = @"";
        if (response.statusCode == -1) result = @"用户取消发送";
        else if (response.statusCode == -2) result = @"发送失败";
        else if (response.statusCode == -3) result = @"授权失败";
        else if (response.statusCode == -4) result = @"用户取消安装微博客户端";
        else if (response.statusCode == -5) result = @"支付失败";
        else if (response.statusCode == -8) result = @"分享失败";
        else if (response.statusCode == -99) result = @"不支持的请求";
        else if (response.statusCode == -100) result = @"WeiboSDKResponseStatusCodeUnknown";
        if (response.userInfo) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:response.userInfo];
            [dict setObject:result forKey:@"result"];
            [dict setObject:[response isKindOfClass:WBAuthorizeResponse.class] ? @"weiboLogin" : @"weiboShare" forKey:@"type"];
            self.weiboCallbackBlock(XVIEWSDKCodeFail, @{@"code": @"-1", @"data":dict, @"message":[response isKindOfClass:WBAuthorizeResponse.class] ? @"微博登录失败" : @"微博分享失败"});
        } else {
            self.weiboCallbackBlock(XVIEWSDKCodeFail, @{@"code": @"-1", @"data":@{@"result": result, @"type":[response isKindOfClass:WBAuthorizeResponse.class] ? @"weiboLogin" : @"weiboShare"}, @"message":[response isKindOfClass:WBAuthorizeResponse.class] ? @"微博登录失败" : @"微博分享失败"});
        }
    }
}











#pragma mark ==旧的微博方法==
- (void)registerAppKey:(NSString *)appKey weiboType:(XVIEWSDKPlatfromType)type parameter:(NSDictionary *)infoData callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock {
    self.weiboCallbackBlock = callbackBlock;
    [self weiboType:type parameter:infoData];
}
- (void)weiboType:(XVIEWSDKPlatfromType)type parameter:(NSDictionary *)dict {
    self.appKeyString = dict[@"wbappkey"];
    self.wbRedirectUrl = dict[@"wbRedirectUrl"];
    self.wbAuthoUrl = @"https://api.weibo.com/2/users/show.json";//dict[@"wbAuthoUrl"];
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:self.appKeyString];
    if (type == XVIEWSDKTypeWeiboLogin) {
        self.appSecretString = dict[@"wbappsecret"];
        [self XVIEWWeiboLogin];
    }
    else if (type == XVIEWSDKTypeWeiboShare) {
        [self shareToWeibo:dict];
    }
}
#pragma mark ==分享到微博==
- (void)shareToWeibo:(NSDictionary *)dict {
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = self.wbRedirectUrl;
    authRequest.scope = @"all";
    //分享多媒体文件
    WBWebpageObject *webpage = [WBWebpageObject object];
    webpage.objectID = @"identifier1";
    webpage.title = NSLocalizedString(dict[@"title"], nil);
    webpage.description = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), dict[@"descrption"]];
    webpage.thumbnailData = [NSData dataWithContentsOfURL:[NSURL URLWithString:dict[@"picture"]]];
    webpage.webpageUrl = dict[@"url"];
    WBMessageObject *message = [WBMessageObject message];
    message.mediaObject = webpage;
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
    request.userInfo = @{@"ShareMessageFrom": @"ViewController",
                         @"Other_Info_1": [NSNumber numberWithInt:123],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    [WeiboSDK sendRequest:request];
}
@end
/**
 *  微博结果的回调，用于AppDelegate里面设置回调以及代理
 *
 *  @param url AppDelegate的方法中的url
 */
//- (BOOL)XVIEWWeiboSDKCallbackUrl:(NSURL *)url;
//
//
///**
// *  设置微博的应用信息
// *
// *  @param appKey      XVIEW的应用标识
// *  @param wbAppKey    微博的应用标识
// *  @param wbAppSecret 微博的应用密钥
// *  @param redirectUrl 微博的回调网址
// *  @param enabled 开启或关闭WeiboSDK的调试模式
// *   设置WeiboSDK的调试模式
// *   当开启调试模式时，WeiboSDK会在控制台输出详细的日志信息，开发者可以据此调试自己的程序。默认为 NO
// */
//
//- (void)registerXViewAppKey:(NSString *)appKey
//weiboAppKey:(NSString *)wbAppKey
//weiboAppSecret:(NSString *)wbAppSecret
//redirectUrl:(NSString *)redirectUrl
//enableDebugMode:(BOOL)enabled;
//
///**
// *  设置分享网页到微博的参数
// *
// *  @param title        标题
// *  @param url          分享链接
// *  @param thumbImage   缩略图，可以为UIImage、NSString(图片在本地路径)、NSData-图片大小不能超过32k
// *  @param description  文字描述
// *
// */
//- (void)XVIEWWeiboShareParametersWithTitle:(NSString *)title
//description:(NSString *)description
//url:(NSString *)url
//thumbImage:(id)thumbImage;
//
///**
// *  微博登录
// */
//- (void)XVIEWWeiboLogin;
//
///**
// *  调用微博登陆、微博分享
// *  @param appKey             XVIEW注册的AppKey
// *  @param type               类型（登陆、分享）
// *  @param infoData           数据（分享的数据）
// *  @param callbackBlock      回调（登陆、分享完成之后的回调）
// */
///**
// *  分享的参数：@{@"title":@"", @"descrption":@"", @"picture":@"", @"url":@"", @"wbappkey":@"3067948552",@"wbRedirectUrl":@"https://api.weibo.com/oauth2/default.html", @"wbAuthoUrl":@"https://api.weibo.com/2/users/show.json"}
// *  登录的参数：@{@"wbappkey":@"3067948552", @"wbappsecret":@"bf69337ef871a364b92e174855f83138", @"wbRedirectUrl":@"https://api.weibo.com/oauth2/default.html", @"wbAuthoUrl":@"https://api.weibo.com/2/users/show.json"}
// */
//- (void)registerAppKey:(NSString *)appKey weiboType:(XVIEWSDKPlatfromType)type parameter:(NSDictionary *)infoData callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock;
