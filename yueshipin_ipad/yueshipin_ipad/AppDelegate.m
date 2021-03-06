//
//  AppDelegate.m
//  yueshipin_ipad
//
//  Created by joyplus1 on 12-11-19.
//  Copyright (c) 2012年 joyplus. All rights reserved.
//

#import "AppDelegate.h"
#import "CommonHeader.h"
#import "OpenUDID.h"
#import "RootViewController.h"
#import "MobClick.h"
#import <Parse/Parse.h>
#import "ActionUtility.h"
#import "iRate.h"
#import "UMFeedback.h"
#import <AVFoundation/AVFoundation.h>
#import "AHAlertView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "HTTPServer.h"
#import "PageManageViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "CommonMotheds.h"
#import "DatabaseManager.h"
#import "SegmentUrl.h"
#import "CustomNavigationViewController.h"
#import "IphoneAVPlayerViewController.h"
#import "SystemMethods.h"
#import "AFDownloadRequestOperation.h"
#import "BPush.h"
#define DAY(day)        (day * 3600 * 24)

@interface AppDelegate ()
@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;
@property (nonatomic, readonly) int networkStatus;
@property (strong, nonatomic) NSMutableArray *downloaderArray;
@property (atomic, strong) NSString *show3GAlertSeq;
@property (nonatomic, strong)HTTPServer *httpServer;
- (void)monitorReachability;

- (void)addLocalNotification;
- (void)addLocalNotificationInterVal:(NSTimeInterval)time
                             message:(NSString *)msg;
- (void)cancelLocalNotification;

@end

@implementation AppDelegate
@synthesize playWithDownload;
@synthesize padDownloadManager;
@synthesize window;
@synthesize rootViewController;
@synthesize tabBarView;
@synthesize closed;
@synthesize networkStatus;
@synthesize hostReach;
@synthesize internetReach;
@synthesize wifiReach;
@synthesize sinaweibo;
@synthesize downloaderArray;
@synthesize currentDownloadingNum;
@synthesize alertUserInfo;
@synthesize showVideoSwitch;
@synthesize closeVideoMode;
@synthesize recommendAppSwich;
@synthesize mediaVolumeValue;
@synthesize show3GAlertSeq;
@synthesize httpServer;
@synthesize adViewController;
@synthesize advUrl, advTargetUrl,bgTask;
@synthesize curDownloadingTask;
@synthesize internetSearchUrl;

+ (AppDelegate *) instance {
	return (AppDelegate *) [[UIApplication sharedApplication] delegate];
}

+ (void)initialize
{
	//set the app and bundle ID. normally you wouldn't need to do this
    //but we need to test with an app that's actually on the store
	[iRate sharedInstance].appStoreID = APPIRATER_APP_ID;
    [iRate sharedInstance].applicationBundleID = @"com.joyplus.yueshipin";
    [iRate sharedInstance].onlyPromptIfLatestVersion = NO;
    [iRate sharedInstance].usesUntilPrompt = 3;
    [iRate sharedInstance].daysUntilPrompt = 2; //第一次提醒
    [iRate sharedInstance].remindPeriod = 3;
    [iRate sharedInstance].verboseLogging = NO;
    
    //enable preview mode
    [iRate sharedInstance].previewMode = NO;
}

- (void)startHttpServer
{
    if (httpServer) {
        if (![httpServer isRunning]) {
            [self startNewHttpServer];
        }
    } else {
        httpServer = [[HTTPServer alloc] init];
        [httpServer setPort:12580];
    	[httpServer setType:@"_http._tcp."];
        NSArray  *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = [documentPaths objectAtIndex:0];
    	[httpServer setDocumentRoot:documentsDir];
        [self startNewHttpServer];
    }
}

- (void)stopHttpServer
{
    if (httpServer) {
        [httpServer stop];
        NSLog(@"HTTP Server is stoped.");
    }
}

- (void)startNewHttpServer
{
    NSError *error;
    if([httpServer start:&error]) {
        NSLog(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
    } else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

- (void)customizeAppearance
{
    // Set the background image for *all* UINavigationBars
    NSString * name = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
    {
        name = @"nav_bar_bg_64";
    }
    else
    {
        name = @"nav_bar_bg_44";
    }
    UIImage *gradientImage44 = [[UIImage imageNamed:name]resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [[UINavigationBar appearance] setBackgroundImage:gradientImage44 forBarMetrics:UIBarMetricsDefault];
    
    [[UIProgressView appearance] setProgressTintColor:[UIColor colorWithRed:95/255.0 green:169/255.0 blue:250/255.0 alpha:1.0]];
    [[UIProgressView appearance] setTrackTintColor:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1.000]];
    
    [[UISwitch appearance] setOnTintColor:CMConstants.yellowColor];
//    [[UISwitch appearance] setTintColor:[UIColor colorWithRed:127/255.0 green:127/255.0 blue:127/255.0 alpha:1.000]];
//    [[UISwitch appearance] setThumbTintColor:[UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.000]];
}
- (void)initSinaweibo
{
    self.sinaweibo = [[SinaWeibo alloc] initWithAppKey:kSinaWeiboAppKey appSecret:kSinaWeiboAppSecret appRedirectURI:kSinaWeiboRedirectURL andDelegate:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *sinaweiboInfo = [defaults objectForKey:@"SinaWeiboAuthData"];
    if ([sinaweiboInfo objectForKey:@"AccessTokenKey"] && [sinaweiboInfo objectForKey:@"ExpirationDateKey"] && [sinaweiboInfo objectForKey:@"UserIDKey"])
    {
        sinaweibo.accessToken = [sinaweiboInfo objectForKey:@"AccessTokenKey"];
        sinaweibo.expirationDate = [sinaweiboInfo objectForKey:@"ExpirationDateKey"];
        sinaweibo.userID = [sinaweiboInfo objectForKey:@"UserIDKey"];
    }
}

-(void)initWeChat{
    [WXApi registerApp:KWeChatAppID];
}

-(void)initBPush:(NSDictionary *)dictionary{
    // 必须
    [BPush setupChannel:dictionary];
    // 必须。参数对象必须实现 onMethod: response:方法
    [BPush setDelegate:self];

}
- (void)initDownloadManager
{
    padDownloadManager = [[NewDownloadManager alloc]init];
    curDownloadingTask = [[NSMutableArray alloc] init];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //如果是测试
    if (ENVIRONMENT == 0) {
        [[AFHTTPRequestOperationLogger sharedLogger] startLogging];
    }
    [MobClick startWithAppkey:umengAppKey reportPolicy:REALTIME channelId:CHANNEL_ID];
    self.recommendAppSwich = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:RECOMMEND_APP_SWITCH];
    if (self.recommendAppSwich == nil) {
        self.recommendAppSwich = @"1";
    }
    self.showVideoSwitch = @"0";
    self.closeVideoMode = @"0";
    show3GAlertSeq = @"0";
    networkStatus = 2;
    [MobClick updateOnlineConfig];
    [MobClick checkUpdate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineConfigCallBack:) name:UMOnlineConfigDidFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setIdleTimerDisabled:) name:SYSTEM_IDLE_TIMER_DISABLED object:nil];
    
    SystemMethods *sys = [[SystemMethods alloc]init];
    [sys saveChannelRecord];
    NSString *documentsDirectory= [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    if ([sys addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:documentsDirectory]]) {
        NSLog(@"Ignore for iClode success.");
    }
    
    NSString *appKey = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:kIpadAppKey];
    if (appKey == nil) {
        [[ContainerUtility sharedInstance] setAttribute:kDefaultAppKey forKey:kIpadAppKey];
    }
    
    NSString *hiddenAVS = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:HIDDEN_AMERICAN_VIDEOS];
    if (hiddenAVS == nil) {
        if ([CHANNEL_ID isEqualToString:@""]) {
             [[ContainerUtility sharedInstance] setAttribute:AMERICANVIDEOS forKey:HIDDEN_AMERICAN_VIDEOS];
        }
        else{
             [[ContainerUtility sharedInstance] setAttribute:@"0" forKey:HIDDEN_AMERICAN_VIDEOS];
        }
    
    }
    
    //消息推送
    NSString *notificationSelected = (NSString *)[[ContainerUtility sharedInstance] attributeForKey:PUSH_NotificationSelected];
    if (notificationSelected == nil) {
         [[ContainerUtility sharedInstance] setAttribute:@"0" forKey:PUSH_NotificationSelected];
    }
    
    
    playWithDownload = [NSString stringWithFormat:@"%@", [[ContainerUtility sharedInstance] attributeForKey:SHOW_PLAY_INTRO_WITH_DOWNLOAD]];
    [ActionUtility generateUserId:nil];
    [self initSinaweibo];
    [self initWeChat];
    [self initBPush:launchOptions];
    [self monitorReachability];
    [self isParseReachable];
    [[BundingTVManager shareInstance] connecteServer];
    
    [Parse setApplicationId:PARSE_APP_ID clientKey:PARSE_CLIENT_KEY];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
     if (application.applicationIconBadgeNumber != 0) {
         application.applicationIconBadgeNumber = 0;
//        PFInstallation *installation = [PFInstallation currentInstallation];
//        [installation setBadge:0];
//        [installation saveInBackground];
    }
    self.closed = YES;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 
    [DatabaseManager initDatabase];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [self customizeAppearance];
        [self initDownloadManager];
        [self initAdViewController];
        self.rootViewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
        self.window.rootViewController = self.rootViewController;
    }
    else
    {
        tabBarView = [[TabBarViewController alloc] init];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
        //UINavigationController * navCtrl = [[UINavigationController alloc] initWithRootViewController:tabBarView];
        //navCtrl.navigationBarHidden = YES;
        self.downLoadManager = [DownLoadManager defaultDownLoadManager];
        [self.downLoadManager resumeDownLoad];
        self.window.rootViewController = tabBarView;
    }
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound)];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) {NSLog(@"%@", setCategoryError);}
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    if (!success) {NSLog(@"%@", activationError);}
    
    NSString *statement = (NSString *)[[ContainerUtility sharedInstance] attributeForKey:@"statement"];
    if (![statement isEqualToString:@"1"]) {
        [self showStatement];
    }
    
    mediaVolumeValue = [MPMusicPlayerController applicationMusicPlayer].volume;
    
    NSDictionary *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (localNotif)
    {
        [self showAPNSMessage:localNotif];
    }    
    return YES;
}

- (void)initAdViewController
{
    self.adViewController = [[AdViewController alloc]initWithFrame: CGRectMake(0, 0, self.window.bounds.size.height - LEFT_MENU_DIPLAY_WIDTH - RIGHT_VIEW_WIDTH, self.window.bounds.size.width)];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", DocumentsDirectory, ADV_IMAGE_NAME];
    if ([fileManager fileExistsAtPath:filePath]) {
        [self.adViewController setAdvImage:filePath];
    }
}

- (void)onlineConfigCallBack:(NSNotification *)notification {
    NSString *appKey = [notification.userInfo objectForKey:kIpadAppKey];
    //如果是测试
    if (ENVIRONMENT == 0) {
        appKey = kDefaultAppKey;
    }
    if(appKey != nil){
        [[AFServiceAPIClient sharedClient] setDefaultHeader:@"app_key" value:appKey];
        [[ContainerUtility sharedInstance] setAttribute:appKey forKey:kIpadAppKey];
    }
    
    if ([CHANNEL_ID isEqualToString:@""]) {//参数self.showVideoSwitch只对app store生效
        self.recommendAppSwich = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:RECOMMEND_APP_SWITCH]];
        self.showVideoSwitch = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:SHOW_VIDEO_SWITCH]];
        self.closeVideoMode = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:CLOSE_VIDEO_MODE]];
        
        NSString *hiddenAVS = [notification.userInfo objectForKey:HIDDEN_AMERICAN_VIDEOS];
        if (hiddenAVS != nil && ![hiddenAVS isEqualToString:@"(null)"]) {
            if (ENVIRONMENT == 0) {
                hiddenAVS = @"0";
            }
            [[AFServiceAPIClient sharedClient] setDefaultHeader:@"EX_COPY_MOVIE" value:hiddenAVS];
            [[ContainerUtility sharedInstance] setAttribute:hiddenAVS forKey:HIDDEN_AMERICAN_VIDEOS];
        }
    }
    self.advUrl = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:ADV_PAHT]];
//    self.advUrl = @"http://g.hiphotos.baidu.com/album/w%3D230/sign=7f271f7883025aafd33279c8cbecab8d/060828381f30e92416adc5894d086e061d95f779.jpg";
    self.advTargetUrl = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:ADV_TARGET_PATH]];
    
    self.internetSearchUrl = [NSString stringWithFormat:@"%@", [notification.userInfo objectForKey:INTERNET_SEARCH_URL]];
    [self downloadAdvImage];
    
    if(self.showVideoSwitch == nil || [self.showVideoSwitch isEqualToString:@"(null)"]){
        self.showVideoSwitch = @"0";
    }
    if(self.closeVideoMode == nil || [self.closeVideoMode isEqualToString:@"(null)"]){
        self.closeVideoMode = @"0";
    }
    if(self.recommendAppSwich == nil || [self.recommendAppSwich isEqualToString:@"(null)"]){
        self.recommendAppSwich = @"0";
    }
 
     NSString *notifyS = [notification.userInfo objectForKey:NotificationSelectedValue];
     [[ContainerUtility sharedInstance] setAttribute:notifyS forKey:PUSH_NotificationSelected];
    
    NSString * pageNum = [notification.userInfo objectForKey:KWXCODENUM];
    [[ContainerUtility sharedInstance] setAttribute:pageNum forKey:KWXCODENUM];
    [[ContainerUtility sharedInstance] setAttribute:self.showVideoSwitch forKey:SHOW_VIDEO_SWITCH];
    [[ContainerUtility sharedInstance] setAttribute:self.recommendAppSwich forKey:RECOMMEND_APP_SWITCH];
    [[NSNotificationCenter defaultCenter] postNotificationName:RELOAD_MENU_ITEM object:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *notificationSelected = (NSString *)[[ContainerUtility sharedInstance] attributeForKey:PUSH_NotificationSelected];
    if ([notificationSelected isEqualToString:@"0"]) { //baidu
        // 必须
        [BPush registerDeviceToken:deviceToken];
        // 必须。可以在其它时机调用,只有在该方法返回(通过 onMethod:response:回调)绑
        //定成功时,app 才能接收到 Push 消息。一个 app 绑定成功至少一次即可(如果 access token 变更请重新绑定)。
        [BPush bindChannel];
    }
    else if ([notificationSelected isEqualToString:@"1"]){  //parse
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:deviceToken];
        NSArray *channels = [NSArray arrayWithObjects:@"", @"CHANNEL_IOS", @"CHANNEL_IOS1", nil];
        [currentInstallation addUniqueObjectsFromArray:channels forKey:@"channels"];
        if (application.applicationIconBadgeNumber != 0) {
            application.applicationIconBadgeNumber = 0;
            [currentInstallation setBadge:0];
        }
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
                NSLog(@"Successfully subscribed to broadcast channel!");
            else
                NSLog(@"Failed to subscribe to broadcast channel; Error: %@",error);
        }];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self showAPNSMessage:userInfo];
    [BPush handleNotification:userInfo];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *prodId = [NSString stringWithFormat:@"%@", [self.alertUserInfo objectForKey:@"prod_id"]];
        NSString *prodType = [NSString stringWithFormat:@"%@", [self.alertUserInfo objectForKey:@"prod_type"]];
        if(prodId != nil && prodType != nil){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:prodId, @"prod_id", prodType, @"prod_type", nil];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"push_notification" object:nil userInfo:userInfo];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [self clearRespForWXView];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.downLoadManager pauseAllTask];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [self continueiPadDownloadWhenEnterBackground:application];
    }
    else
    {
        [self continueiPhoneDownloadWhenEnterBackground:application];
    }
    
    //When app enter background, add a new local Notification
    [self addLocalNotification];
    // end
    //add notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APPLICATION_DID_ENTER_BACKGROUND_NOTIFICATION object:nil];
    if (httpServer && [httpServer isRunning]) {
        [httpServer stop:YES];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [application endBackgroundTask:bgTask];
        
        bgTask = UIBackgroundTaskInvalid;
    }
    
    if (httpServer && ![httpServer isRunning]) {
        [httpServer start:NULL];
    }
    
    [self performSelector:@selector(iphoneContinueDownload) withObject:nil afterDelay:5];
}

-(void)iphoneContinueDownload{
   [self.downLoadManager appDidEnterForeground];
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    Reachability *myhostReach = [Reachability reachabilityForInternetConnection];
//    if([myhostReach currentReachabilityStatus] == NotReachable) {
//         UIView *rootView = self.window.rootViewController.view;
//         [UIUtility showNetWorkError:rootView];
//    };
    
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
//        PFInstallation *installation = [PFInstallation currentInstallation];
//        [installation setBadge:0];
//        [installation saveInBackground];
    }
   
    [self.sinaweibo applicationDidBecomeActive];
    [self performSelector:@selector(triggerDownload) withObject:self afterDelay:5];
    
    //when app become active ,cancel all local notification .
    [self cancelLocalNotification];
    [self getLocalNotificationMsg];
    
    //add notification
    [[NSNotificationCenter defaultCenter] postNotificationName:APPLICATION_DID_BECOME_ACTIVE_NOTIFICATION
                                                        object:nil];
}

- (void)triggerDownload
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        [padDownloadManager startDownloadingThreads];
    }
    else{
    
  }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
}
//- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
//    
//    return UIInterfaceOrientationMaskAll;
//    
//}
- (BOOL)isParseReachable {
    return self.networkStatus != NotReachable;
}
- (BOOL)isWifiReachable {
    return self.networkStatus == ReachableViaWiFi;
}
- (void)monitorReachability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.hostReach = [Reachability reachabilityWithHostname: @"www.baidu.com"];
    [self.hostReach startNotifier];
    
//    self.internetReach = [Reachability reachabilityForInternetConnection];
//    [self.internetReach startNotifier];
//    
//    self.wifiReach = [Reachability reachabilityForLocalWiFi];
//    [self.wifiReach startNotifier];
}
//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification* )note {
    Reachability *curReach = (Reachability *)[note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    int currentStatus = [curReach currentReachabilityStatus];
    networkStatus = currentStatus;
     NSLog(@"networkStatus -------------------%d",currentStatus);
    //网络变化的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:NETWORK_CHANGED object:[NSNumber numberWithInt:currentStatus]];
    
    switch (currentStatus) {
        case NotReachable:  //无网络
            break;
        case ReachableViaWWAN: //3G,GPRS
            [[NSNotificationCenter defaultCenter] postNotificationName:KEY_NETWORK_BECOME_AVAILABLE object:nil];
            [self triggerDownload];
            [ActionUtility generateUserId:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:WIFI_IS_NOT_AVAILABLE object:@"0"];
            break;
        case ReachableViaWiFi: // wifi
            [[NSNotificationCenter defaultCenter] postNotificationName:KEY_NETWORK_BECOME_AVAILABLE object:nil];
            [self triggerDownload];
            [ActionUtility generateUserId:nil];
            break;
            
        default:
            break;
    }
    
   
    
//    if(self.networkStatus != NotReachable){
//        NSLog(@"Network is fine.");
//        [[NSNotificationCenter defaultCenter] postNotificationName:KEY_NETWORK_BECOME_AVAILABLE object:nil];
//        [self triggerDownload];
//        [ActionUtility generateUserId:nil];
//        if ([self isWifiReachable]) {
//            show3GAlertSeq = @"0";
//        } else {
//            @synchronized(show3GAlertSeq){
//                if ([show3GAlertSeq isEqualToString:@"0"]) {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:WIFI_IS_NOT_AVAILABLE object:show3GAlertSeq];
//                    show3GAlertSeq = @"1";
//                }
//            }
//        }
//    } 
    
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
//        [self.downLoadManager networkChanged:networkStatus];
//    }
    
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
   [self.sinaweibo handleOpenURL:url];
    return [WXApi handleOpenURL:url delegate:self];
   
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [self.sinaweibo handleOpenURL:url];
    return  [WXApi handleOpenURL:url delegate:self];
   
}

- (void)showStatement
{
    AHAlertView *alert = [[AHAlertView alloc] initWithTitle:@"免 责 声 明" message:nil];
    alert.frame = CGRectMake(alert.frame.origin.x, alert.frame.origin.y, 350, 400);
    [self applyCustomAlertAppearance];
    [alert setCancelButtonTitle:@"接 受" block:^{
        [[ContainerUtility sharedInstance] setAttribute:@"1" forKey:@"statement"];
    }];
    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 40, alert.frame.size.width - 25, alert.frame.size.height - 110)];
    textView.font = [UIFont systemFontOfSize:14];
    textView.text = [self getContent];
    textView.editable = NO;
    textView.layer.cornerRadius = 2;
    textView.layer.masksToBounds = YES;
    alert.contentTextView = textView;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
       alert.frame = CGRectMake(alert.frame.origin.x, alert.frame.origin.y, 250, 330);
       textView.frame = CGRectMake(10, 40, alert.frame.size.width - 25, alert.frame.size.height - 110);
    }
    [alert show];
}

- (void)applyCustomAlertAppearance
{
	[[AHAlertView appearance] setContentInsets:UIEdgeInsetsMake(12, 18, 12, 18)];
	[[AHAlertView appearance] setBackgroundImage:[UIImage imageNamed:@"custom-dialog-background"]];
	UIEdgeInsets buttonEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
	[[AHAlertView appearance] setCancelButtonBackgroundImage:[[UIImage imageNamed:@"custom-cancel-normal"] resizableImageWithCapInsets:buttonEdgeInsets]
													forState:UIControlStateNormal];
	[[AHAlertView appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont boldSystemFontOfSize:19], UITextAttributeFont, [UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, [NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset, nil]];
	[[AHAlertView appearance] setButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont boldSystemFontOfSize:18], UITextAttributeFont, [UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, [NSValue valueWithCGSize:CGSizeMake(0, -1)], UITextAttributeTextShadowOffset, nil]];
}


- (NSString *)getContent
{
    return @"        任何用户在使用悦视频客户端服务之前，均应仔细阅读本声明（未成年人应当在其法定监护人陪同下阅读），用户可以选择不使用悦视频客户端服务，一旦使用，既被视为对本声明全部内容的认可和接受。\n\n\
1. 任何通过悦视频显示或下载的资源和产品均系聚合引擎技术自动搜录第三方网站所有者制作或提供的内容，悦视频中的所有材料、信息和产品仅按“原样”提供，我公司对其合法性、准确性、真实性、适用性、安全性等概不负责，也无法负责；并且悦视频自动搜录的内容不代表我公司之任何意见和主张，也不代表我公司同意或支持第三方网站上的任何内容、主张或立场。\n\n\
2. 任何第三方网站如果不希望被我公司的聚合引擎技术收录，应该及时向我公司反映。否则，我公司的聚合引擎技术将视其为可收录的资源网站。\n\n\
3. 任何单位或者个人如认为悦视频客户端聚合引擎技术收录的第三方网站视频内容可能侵犯了其合法权益，请及时向我公司书面反馈，并提供身份证明、权属证明以及详情侵权情况证明。我公司在收到上述文件后，可依其合理判断，断开聚合引擎技术收录的涉嫌侵权的第三方网站内容。\n\n\
4. 用户理解并且同意，用户通过悦视频所获得的材料、信息、产品以及服务完全处于用户自己的判断，并承担因使用该等内容而引起的所有风险，包括但不限于因对内容的正确性、完整性或实用性的依赖而产生的风险。用户在使用悦视频的过程中，因受视频或相关内容误导或欺骗而导致或可能导致的任何心理、生理上的伤害以及经济上的损失，一概与本公司无关。\n\n\
5. 用户因第三方如电信部门的通讯线路故障、技术问题、网络、电脑故障、系统不稳定性及其他各种不可抗力量原因而遭受到的一切损失，我公司不承担责任。因技术故障等不可抗时间影响到服务的正常运行的，我公司承诺在第一时间内与相关单位配合，及时处理进行修复，但用户因此而遭受的一切损失，我公司不承担责任。";
}

-(void) onRequestAppMessage
{
    // 微信请求App提供内容， 需要app提供内容后使用sendRsp返回
    RespForWXRootViewController * respRootViewCtrl = [[RespForWXRootViewController alloc] init];
    respRootViewCtrl.delegate = self;
    UINavigationController * navCtrl = [tabBarView.viewControllers objectAtIndex:tabBarView.selectedIndex];
    UIViewController * rootViewCtrl = navCtrl.topViewController;
    if (rootViewCtrl.presentedViewController)
    {
        UIViewController * persentedCtrl = rootViewCtrl.presentedViewController;
        if ([persentedCtrl isKindOfClass:[CustomNavigationViewController class]])
        {
            CustomNavigationViewController * cNavCtrl = (CustomNavigationViewController *)persentedCtrl;
            UIViewController * topCtrl = cNavCtrl.topViewController;
            if ([topCtrl isKindOfClass:[IphoneAVPlayerViewController class]])
            {
                IphoneAVPlayerViewController * playCtrl = (IphoneAVPlayerViewController *)topCtrl;
                [playCtrl clearPlayerData];
            }
            [topCtrl dismissViewControllerAnimated:NO completion:NULL];
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
        }
        else
        {
            [rootViewCtrl dismissViewControllerAnimated:NO completion:NULL];
        }
    }
    respRootViewCtrl.hidesBottomBarWhenPushed = YES;
    [navCtrl pushViewController:respRootViewCtrl animated:NO];
}

// wecha sdk delegate
-(void) onReq:(BaseReq*)req
{
    //
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        [self onRequestAppMessage];
    }
}
-(void) onResp:(BaseResp*)resp{
    if (resp.errCode == 0) {
         [[NSNotificationCenter defaultCenter] postNotificationName:@"wechat_share_success" object:nil];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"WXShare" object:nil];
    }
    

}

- (void)showAPNSMessage:(NSDictionary *)dic
{
    self.alertUserInfo = dic;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ([AppDelegate instance].isInPlayView) {
            return;
        }
    }
    NSString *alert = [[dic objectForKey:@"aps"] objectForKey:@"alert"];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil message:alert delegate:self  cancelButtonTitle:@"不了" otherButtonTitles:@"看一下", nil];
    [alertView show];
}

#pragma mark -
#pragma mark - download at background

- (void)continueiPadDownloadWhenEnterBackground:(UIApplication *)application
{
    UIDevice* device = [UIDevice currentDevice];
    
    BOOL backgroundSupported = NO;
    
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
        
        backgroundSupported = device.multitaskingSupported;
    
    if (!backgroundSupported)
    {
        return;
    }
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        //[self.padDownloadManager stopDownloading];
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
    }];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task, preferably in chunks.
        int curDownloadNum = [NewDownloadManager downloadingTaskCount];
        BOOL isDownloadFinish = (curDownloadNum == 0 ? YES : NO);
        if (!isDownloadFinish)
        {
            [self.padDownloadManager startDownloadingThreads];
        }
        
        while (!isDownloadFinish)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            [NSThread sleepForTimeInterval:5];
            isDownloadFinish = ([NewDownloadManager downloadingTaskCount] == 0 ? YES : NO);
        }
        
        [application endBackgroundTask:bgTask];
        
        bgTask = UIBackgroundTaskInvalid;
        
    });
}

- (void)continueiPhoneDownloadWhenEnterBackground:(UIApplication *)application
{
    UIDevice* device = [UIDevice currentDevice];
    
    BOOL backgroundSupported = NO;
    
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
        
        backgroundSupported = device.multitaskingSupported;
    
    if (!backgroundSupported)
    {
        return;
    }
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        
        // Clean up any unfinished task business by marking where you
        
        // stopped or ending the task outright.
        
        [self.downLoadManager pauseAllTask];
        
        [application endBackgroundTask:bgTask];
        
        bgTask = UIBackgroundTaskInvalid;
        
    }];
    
    
    
    // Start the long-running task and return immediately.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task, preferably in chunks.
        int curDownloadNum = [DownLoadManager downloadingTaskCount];
        BOOL isDownloadFinish = (curDownloadNum == 0 ? YES : NO);
        if (!isDownloadFinish)
        {
            [self.downLoadManager resumeDownLoad];
        }
        
        while (!isDownloadFinish)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            [NSThread sleepForTimeInterval:5];
            isDownloadFinish = ([DownLoadManager downloadingTaskCount] == 0 ? YES : NO);
        }
        
        [application endBackgroundTask:bgTask];
        
        bgTask = UIBackgroundTaskInvalid;
        
    });
}

#pragma mark - 
#pragma mark - LocalNotification

- (void)getLocalNotificationMsg
{
    if([[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]){
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: @"1", @"page_num", [NSNumber numberWithInt:5], @"page_size", LOCAL_NOTIFICATION_YUEDAN_ID, @"top_id", nil];
        [[AFServiceAPIClient sharedClient] getPath:kPathTopItems parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
            NSString * content = [result objectForKey:@"content"];
            [[CacheUtility sharedCache] putInCache:@"local_notification_content" result:content];
        } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@",error);
        }];
    }
}

- (void)addLocalNotification
{
    NSString * notificationMsg = (NSString *)[[CacheUtility sharedCache] loadFromCache:@"local_notification_content"];
    NSArray * notificationArr = [notificationMsg componentsSeparatedByString:@"$"];
    if (0 == notificationArr.count)
    {
        notificationArr = [DEFAULT_LOCAL_NOTIFICATION_CONTENT componentsSeparatedByString:@"$"];
        [[CacheUtility sharedCache] putInCache:@"local_notification_content" result:DEFAULT_LOCAL_NOTIFICATION_CONTENT];
    }
    
    int random = arc4random()%5;
    
    for (int i = 0; i < notificationArr.count; i ++)
    {
        NSString * msg = [notificationArr objectAtIndex:random];
        [self addLocalNotificationInterVal:DAY(4 * (i + 1))
                                   message:msg];
        random ++;
        random = (random >= 5) ? 0 : random;
    }
    
    //    NSString * firstStr  = @"亲，我们上了很多新片大片，要来看哦~";
    //    NSString * secondStr = @"亲，你已经很久没来看小悦啦，是不是工作太忙？再忙也要抽空看个电影放松一下呀~";
    //    NSString * thirdStr  = @"亲，忙碌了一整天，看一部喜欢的影片来缓解下疲劳吧~";
    //    NSString * fourthStr = @"亲，小悦怀念曾经陪你一起看电影的时光，记得来看小悦哦~";
    //    NSString * fifthStr  = @"亲，小悦觉得忙过一整天后最美的事情莫过于与喜欢的影片不期而遇，你觉得呢？";
    //
    //    [self addLocalNotificationInterVal:DAY(4)
    //                               message:firstStr];
    //    [self addLocalNotificationInterVal:(DAY(4) * 2)
    //                               message:secondStr];
    //    [self addLocalNotificationInterVal:(DAY(4) * 3)
    //                               message:thirdStr];
    //    [self addLocalNotificationInterVal:(DAY(4) * 4)
    //                               message:fourthStr];
    //    [self addLocalNotificationInterVal:(DAY(4) * 5)
    //                               message:fifthStr];
}

- (void)addLocalNotificationInterVal:(NSTimeInterval)time
                             message:(NSString *)msg
{
    
    NSDate * now = [NSDate new];
    //输出字符串为格林威治时区，做8小时偏移
    NSString * now_str = [now description];
    //即北京时区20点整,(ti)天后，提示用户
    NSString * today9PM = [now_str stringByReplacingCharactersInRange:NSMakeRange(11, 8) withString:@"12:00:00"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSDate * Date9PM = [formatter dateFromString:today9PM];
    
    UILocalNotification * localNotification = [[UILocalNotification alloc] init];
    NSDate * fireDate = [Date9PM dateByAddingTimeInterval:time];
    localNotification.fireDate = fireDate;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.alertBody = msg;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
}

- (void)cancelLocalNotification
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)clearRespForWXView
{
    UINavigationController * navCtrl = [tabBarView.viewControllers objectAtIndex:tabBarView.selectedIndex];
    if ([navCtrl.topViewController isKindOfClass:[RespForWXRootViewController class]])
    {
        [navCtrl popViewControllerAnimated:NO];
    }
    else if ([navCtrl.topViewController isKindOfClass:[RespForWXDetailViewController class]])
    {
        [navCtrl popViewControllerAnimated:NO];
        [navCtrl popViewControllerAnimated:NO];
    }
}

#pragma mark - BPushDelegate
- (void) onMethod:(NSString*)method response:(NSDictionary*)data {
    if ([BPushRequestMethod_Bind isEqualToString:method]) {
        NSDictionary* res = [[NSDictionary alloc] initWithDictionary:data];
//        NSString *appid = [res valueForKey:BPushRequestAppIdKey];
//        NSString *userid = [res valueForKey:BPushRequestUserIdKey];
//        NSString *channelid = [res valueForKey:BPushRequestChannelIdKey];
//        int returnCode = [[res valueForKey:BPushRequestErrorCodeKey] intValue];
//        NSString *requestid = [res valueForKey:BPushRequestRequestIdKey];
        NSLog(@"绑定百度消息推送返回信息：%@",res);
    }
}


#pragma mark - RespForWXRootViewControllerDelegate
- (void)removeRespForWXRootView
{
    tabBarView.tabBar.hidden = NO;
    UINavigationController * navCtrl = [tabBarView.viewControllers objectAtIndex:tabBarView.selectedIndex];
    [navCtrl popViewControllerAnimated:NO];
}

- (void)backButtonClick
{
    [WXApi openWXApp];
    tabBarView.tabBar.hidden = NO;
    UINavigationController * navCtrl = [tabBarView.viewControllers objectAtIndex:tabBarView.selectedIndex];
    [navCtrl popViewControllerAnimated:NO];
}

- (void)shareVideoResp:(NSDictionary *)data
{
    //NSDictionary * shareData = [NSDictionary dictionaryWithObjectsAndKeys:downloadUrl,@"videoURL",title,@"name",description ,@"description",thumb,@"thumb",nil];
    
    WXMediaMessage *message = [WXMediaMessage message];
    
    message.title = [data objectForKey:@"name"];
    message.description = [data objectForKey:@"description"];
    
    NSURL *url = [NSURL URLWithString:[data objectForKey:@"thumb"]];
    
    UIImage * thumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    
    [message setThumbImage:thumb];
    
    WXVideoObject *ext = [WXVideoObject object];
    ext.videoUrl = [data objectForKey:@"videoURL"];
    
    message.mediaObject = ext;
    
    GetMessageFromWXResp* resp = [[GetMessageFromWXResp alloc] init];
    resp.message = message;
    resp.bText = NO;
    
    [WXApi sendResp:resp];
}

- (void)setIdleTimerDisabled:(NSNotification *)notification
{
    BOOL disabled = [notification.object boolValue];
    [[UIApplication sharedApplication] setIdleTimerDisabled: disabled];
}

- (void)downloadAdvImage
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:DocumentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if ([filename hasPrefix:ADV_IMAGE_NAME]) {
            [fileManager removeItemAtPath:[DocumentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
    
    NSURL *url = [NSURL URLWithString:self.advUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", DocumentsDirectory, ADV_IMAGE_NAME];
    AFDownloadRequestOperation *downloadingOperation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:filePath shouldResume:YES];
    [downloadingOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded file to %@", filePath);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Download Ad Error: %@", error);
        self.advUrl = nil;
        [operation cancel];
    }];
    [downloadingOperation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
    }];
    [downloadingOperation start];
}

@end
