//
//  VideoDetailViewController.m
//  yueshipin_ipad
//
//  Created by joyplus1 on 12-11-29.
//  Copyright (c) 2012年 joyplus. All rights reserved.
//

#import "VideoDetailViewController.h"
#import "SelectListViewController.h"
#import "CommonHeader.h"
#import "ListViewController.h"
#import "MyMediaPlayerViewController.h"
#import "VideoWebViewController.h"

@interface VideoDetailViewController ()

@end

@implementation VideoDetailViewController
@synthesize prodId;
@synthesize fromViewController;
@synthesize type;
@synthesize subname;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:CMConstants.backgroundColor];
    [self.view addGestureRecognizer:swipeRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self clearMemory];
}

- (void)clearMemory
{
    _sinaweibo = nil;
    video = nil;
    topics = nil;
    [downloadUrls removeAllObjects];
    downloadUrls = nil;
    episodeArray = nil;
}

- (void)shareBtnClicked
{
    Reachability *hostReach = [Reachability reachabilityForInternetConnection];
    if([hostReach currentReachabilityStatus] == NotReachable) {
        [UIUtility showNetWorkError:self.view];
        return;
    }
    _sinaweibo = [AppDelegate instance].sinaweibo;
    _sinaweibo.delegate = self;
    
    if ([_sinaweibo isLoggedIn]) {
        
        [AppDelegate instance].rootViewController.prodId = self.prodId;
        [AppDelegate instance].rootViewController.prodUrl = [video objectForKey:@"poster"];
        [AppDelegate instance].rootViewController.prodName = [video objectForKey:@"name"];
        [[AppDelegate instance].rootViewController showSharePopup];
    } else {
        [_sinaweibo logIn];
    }
}

- (void)commentBtnClicked
{
    Reachability *hostReach = [Reachability reachabilityForInternetConnection];
    if([hostReach currentReachabilityStatus] == NotReachable) {
        [UIUtility showNetWorkError:self.view];
        return;
    }
    [AppDelegate instance].rootViewController.prodId = self.prodId;
    [AppDelegate instance].rootViewController.videoDetailDelegate = self;
    [[AppDelegate instance].rootViewController showCommentPopup];
    
}


- (void)removeAuthData
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
}

- (void)storeAuthData
{
    NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                              _sinaweibo.accessToken, @"AccessTokenKey",
                              _sinaweibo.expirationDate, @"ExpirationDateKey",
                              _sinaweibo.userID, @"UserIDKey",
                              _sinaweibo.refreshToken, @"refresh_token", nil];
    [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"SinaWeiboAuthData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - SinaWeibo Delegate

- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo
{
    [self shareBtnClicked];
    [self storeAuthData];
    [sinaweibo requestWithURL:@"users/show.json"
                       params:[NSMutableDictionary dictionaryWithObject:sinaweibo.userID forKey:@"uid"]
                   httpMethod:@"GET"
                     delegate:self];
}

- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboDidLogOut");
    [self removeAuthData];
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboLogInDidCancel");
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error
{
    NSLog(@"sinaweibo logInDidFailWithError %@", error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"网络数据错误，请重新登陆。"
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error
{
    NSLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    [self removeAuthData];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"Token已过期，请重新登陆。"
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}

#pragma mark - SinaWeiboRequest Delegate

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)userInfo
{
    if ([request.url hasSuffix:@"users/show.json"])
    {
        NSString *username = [userInfo objectForKey:@"screen_name"];
        [[ContainerUtility sharedInstance] setAttribute:username forKey:kUserNickName];
        NSString *avatarUrl = [userInfo objectForKey:@"avatar_large"];
        [[ContainerUtility sharedInstance] setAttribute:avatarUrl forKey:kUserAvatarUrl];
        
        NSString *userId = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:kUserId];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: userId, @"pre_user_id", [userInfo objectForKey:@"idstr"], @"source_id", @"1", @"source_type", nil];
        [[AFServiceAPIClient sharedClient] postPath:kPathUserValidate parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
            NSString *responseCode = [result objectForKey:@"res_code"];
            if(responseCode == nil){
                NSString *user_id = [result objectForKey:@"user_id"];
                [[AFServiceAPIClient sharedClient] setDefaultHeader:@"user_id" value:user_id];
                [[ContainerUtility sharedInstance] setAttribute:user_id forKey:kUserId];
                [[CacheUtility sharedCache] removeObjectForKey:@"PersonalData"];
                [[CacheUtility sharedCache] removeObjectForKey:WATCH_RECORD_CACHE_KEY];
                [[CacheUtility sharedCache] removeObjectForKey:@"my_support_list"];
                [[CacheUtility sharedCache] removeObjectForKey:@"my_collection_list"];
                [[NSNotificationCenter defaultCenter] postNotificationName:PERSONAL_VIEW_REFRESH object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:WATCH_HISTORY_REFRESH object:nil];
            } else {
                NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: [userInfo objectForKey:@"idstr"], @"source_id", @"1", @"source_type", avatarUrl, @"pic_url", username, @"nickname", nil];
                [[AFServiceAPIClient sharedClient] postPath:kPathAccountBindAccount parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
                    
                } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
                    
                }];
            }
        } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
            
        }];
    }
}

- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error
{
    if ([request.url hasSuffix:@"users/show.json"])
    {
        
    }
}



- (NSString *)parseVideoUrl:(NSDictionary *)tempVideo
{
    NSString *videoUrl;
    NSArray *urlArray =  [tempVideo objectForKey:@"urls"];
    for(NSDictionary *url in urlArray){
        if([GAO_QING isEqualToString:[url objectForKey:@"type"]]){
            videoUrl = [url objectForKey:@"url"];
            break;
        }
    }
    if(videoUrl == nil){
        for(NSDictionary *url in urlArray){
            if([BIAO_QING isEqualToString:[url objectForKey:@"type"]]){
                videoUrl = [url objectForKey:@"url"];
                break;
            }
        }
    }
    if(videoUrl == nil){
        for(NSDictionary *url in urlArray){
            if([LIU_CHANG isEqualToString:[url objectForKey:@"type"]]){
                videoUrl = [url objectForKey:@"url"];
                break;
            }
        }
    }
    if(videoUrl == nil){
        for(NSDictionary *url in urlArray){
            if([CHAO_QING isEqualToString:[url objectForKey:@"type"]]){
                videoUrl = [url objectForKey:@"url"];
                break;
            }
        }
    }
    if(videoUrl == nil){
        if(urlArray.count > 0){
            videoUrl = [[urlArray objectAtIndex:0] objectForKey:@"url"];
        }
    }
    return videoUrl;
}

- (void)addListBtnClicked
{
    Reachability *hostReach = [Reachability reachabilityForInternetConnection];
    if([hostReach currentReachabilityStatus] == NotReachable) {
        [UIUtility showNetWorkError:self.view];
        return;
    }
    SelectListViewController *viewController = [[SelectListViewController alloc]init];
    viewController.prodId = self.prodId;
    viewController.type = self.type;
    viewController.view.frame = CGRectMake(0, 0, RIGHT_VIEW_WIDTH, self.view.bounds.size.height);
    [[AppDelegate instance].rootViewController.stackScrollViewController addViewInSlider:viewController invokeByController:self isStackStartView:FALSE removePreviousView:NO];
}

- (void)showSublistView:(int)num{
    ListViewController *viewController = [[ListViewController alloc] init];
    viewController.view.frame = CGRectMake(0, 0, RIGHT_VIEW_WIDTH, self.view.bounds.size.height);
    NSDictionary *item = [topics objectAtIndex:num];
    NSString *topId = [NSString stringWithFormat:@"%@", [item objectForKey: @"t_id"]];
    viewController.topId = topId;
    viewController.listTitle = [item objectForKey: @"t_name"];
    [[AppDelegate instance].rootViewController.stackScrollViewController addViewInSlider:viewController invokeByController:self isStackStartView:FALSE removePreviousView:NO];
}

- (void)closeBtnClicked
{
    fromViewController.moveToLeft = YES;
    if (fromViewController == nil) {
         [[AppDelegate instance].rootViewController.stackScrollViewController removeViewInSlider];
    } else {
        [[AppDelegate instance].rootViewController.stackScrollViewController removeViewToViewInSlider:fromViewController.class];
    }
}

- (void)getDownloadUrls:(int)num
{
    if(num < 0 || num >=episodeArray.count){
        downloadUrls = nil;
        return;
    }
    downloadUrls = [[NSMutableArray alloc]initWithCapacity:3];
    NSArray *videoUrlArray = [[episodeArray objectAtIndex:num] objectForKey:@"down_urls"];
    if(videoUrlArray.count > 0){
        for(NSDictionary *tempVideo in videoUrlArray){
            NSArray *urlArray =  [tempVideo objectForKey:@"urls"];
            for(NSDictionary *url in urlArray){
                if([@"mp4" isEqualToString:[url objectForKey:@"file"]]){
                    NSString *videoUrl = [url objectForKey:@"url"];
                    [downloadUrls addObject:videoUrl];
                }
            }
        }
    }
}

- (void)updateBadgeIcon
{
    SequenceData *newNum = (SequenceData *)[SequenceData findFirstByCriteria:@"WHERE type = 0"];
    if (newNum == nil) {
        newNum = [[SequenceData alloc]initWithType:0];
        newNum.newDownloadItemNum = 1;
    } else {
        newNum.newDownloadItemNum++;
    }
    [newNum save];
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_DOWNLOAD_ITEM_NUM object:nil];
}

- (void)playVideo:(int)num
{
    if(![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]){
        [UIUtility showNetWorkError:self.view];
        return;
    }
    if(![[UIApplication sharedApplication].delegate performSelector:@selector(isWifiReachable)]){
        willPlayIndex = num;
        UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:@"播放视频会消耗大量流量，您确定要在非WiFi环境下播放吗？"
                                                          delegate:self
                                                 cancelButtonTitle:@"取消"
                                                 otherButtonTitles:@"确定", nil];
        [alertView show];
    } else {
        [self willPlayVideo:num];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        [self willPlayVideo:willPlayIndex];
    }
}

- (void)willPlayVideo:(int)num
{
    if(num < 0 || num >= episodeArray.count){
        return;
    }
    // 网页地址
    NSMutableArray *httpUrlArray = [[NSMutableArray alloc]initWithCapacity:5];
    for (int i = num; i < episodeArray.count; i++) {
        NSArray *videoUrls = [[episodeArray objectAtIndex:i] objectForKey:@"video_urls"];
        BOOL found = NO;
        for (NSDictionary *videoUrl in videoUrls) {
            NSString *url = [NSString stringWithFormat:@"%@", [videoUrl objectForKey:@"url"]];
            if([self validadUrl:url]){
                NSString *httpUrl = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                [httpUrlArray addObject:httpUrl];
                found = YES;
                break;
            }
        }
        if (!found) {
            [httpUrlArray addObject:@""];
        }
    }
    if ([[AppDelegate instance].showVideoSwitch isEqualToString:@"2"]) {
        if (httpUrlArray.count > 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[httpUrlArray objectAtIndex:0]]];
        } else {
            [UIUtility showPlayVideoFailure:self.view];
        }
    } else {
        // 视频地址
        NSMutableArray *videoUrlsArray = [[NSMutableArray alloc]initWithCapacity:5];
        if ([[AppDelegate instance].showVideoSwitch isEqualToString:@"0"]) { // 0:先播放视频，再播放网页
            for (int i = num; i < episodeArray.count; i++) {
                NSMutableArray *urlsArray = [[NSMutableArray alloc]initWithCapacity:5];
                NSArray *videoUrlArray = [[episodeArray objectAtIndex:i] objectForKey:@"down_urls"];
                if(videoUrlArray.count > 0){
                    NSMutableArray *urlsDicArray = [[NSMutableArray alloc]initWithCapacity:5];
                    for(NSDictionary *tempVideo in videoUrlArray){
                        NSArray *urls = [tempVideo objectForKey:@"urls"];
                        [urlsDicArray addObjectsFromArray:urls];
                    }
                    urlsDicArray = [urlsDicArray sortedArrayUsingComparator:^(NSDictionary *a, NSDictionary *b) {
                        NSNumber *first =  [NSString stringWithFormat:@"%@", [a objectForKey:@"file"]];
                        NSNumber *second = [NSString stringWithFormat:@"%@", [b objectForKey:@"file"]];
                        return [second compare:first];
                    }];
                    for (NSDictionary *url in urlsDicArray) {
                        NSString *tempUrl = [url objectForKey:@"url"];
                        if([self validadUrl:tempUrl]){
                            [urlsArray addObject:[tempUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                        }
                    }
                }
                [videoUrlsArray addObject:urlsArray];
            }
        }

        VideoWebViewController *webViewController = [[VideoWebViewController alloc] init];
        webViewController.videoUrlsArray = videoUrlsArray;
        webViewController.videoHttpUrlArray = httpUrlArray;
        webViewController.prodId = self.prodId;
        webViewController.type = type;
        webViewController.startNum = num;
        webViewController.dramaDetailViewControllerDelegate = self;
        webViewController.subname = self.subname;
        webViewController.video = video;
        webViewController.name = [video objectForKey:@"name"];
        webViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [[AppDelegate instance].rootViewController pesentMyModalView:[[UINavigationController alloc]initWithRootViewController:webViewController]];
        
//        MyMediaPlayerViewController *viewController = [[MyMediaPlayerViewController alloc]init];
//        viewController.videoUrls = urlsArray;
//        viewController.videoHttpUrl = httpUrl;
//        viewController.prodId = self.prodId;
//        viewController.dramaDetailViewControllerDelegate = self;
//        viewController.type = type;
//        viewController.name = [video objectForKey:@"name"];
//        viewController.subname = self.subname;
//        viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
//        [[AppDelegate instance].rootViewController pesentMyModalView:[[UINavigationController alloc]initWithRootViewController:viewController]];
    }
}

- (BOOL)validadUrl:(NSString *)originalUrl
{
    NSString *formatUrl = [[originalUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    if([formatUrl hasPrefix:@"http://"] || [formatUrl hasPrefix:@"https://"]){
        return YES;
    }
    return NO;
}

// This callback method will be implemented by subclasses.
- (void)playNextEpisode{
    
}

@end