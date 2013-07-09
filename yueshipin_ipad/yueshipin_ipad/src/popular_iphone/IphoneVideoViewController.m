//
//  IphoneVideoViewController.m
//  yueshipin
//
//  Created by 08 on 13-1-10.
//  Copyright (c) 2013年 joyplus. All rights reserved.
//

#import "IphoneVideoViewController.h"
#import "AppDelegate.h"
#import "SendWeiboViewController.h"
#import "AFSinaWeiboAPIClient.h"
#import "CMConstants.h"
#import "ContainerUtility.h"
#import "ServiceConstants.h"
#import "AFServiceAPIClient.h"
#import "SendWeiboViewController.h"
#import "ActionUtility.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomNavigationViewController.h"
#import "CacheUtility.h"
#import "TimeUtility.h"
#import "UIImage+Scale.h"
#import "IphoneAVPlayerViewController.h"
#import "IphoneWebPlayerViewController.h"
#import "CustomNavigationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WXApi.h"
#import "UIImageView+WebCache.h"
#import "TSActionSheet.h"
#import "Reachability.h"
#import "MobClick.h"
#import "CustomNavigationViewControllerPortrait.h"
#import "UIUtility.h"
#import "UIImage+ResizeAdditions.h"
#import "CommonMotheds.h"
#import "IphoneAVPlayerViewController.h"

#define VIEWTAG   123654

@interface IphoneVideoViewController ()

@property (nonatomic) int willPlayIndex;

@end

@implementation IphoneVideoViewController
@synthesize mySinaWeibo = _mySinaWeibo;
@synthesize infoDic = infoDic_;
@synthesize episodesArr = episodesArr_;
@synthesize prodId = prodId_;
@synthesize subName = subName_;
@synthesize name = name_;
@synthesize videoUrlsArray = videoUrlsArray_;
@synthesize httpUrlArray = httpUrlArray_;
@synthesize isNotification = isNotification_;
@synthesize segmentedControl = segmentedControl_;
@synthesize wechatImgStr = wechatImgStr_;
@synthesize willPlayIndex;
@synthesize canPlayVideo;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (isNotification_) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"top_bg_common.png"] forBarMetrics:UIBarMetricsDefault];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSuccessModalView) name:@"wechat_share_success" object:nil];
    
    UIView *footview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    footview.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footview;
}
- (void)viewDidUnload{

 [super viewDidUnload];
 
}
-(void)viewWillDisappear:(BOOL)animated{
    [BundingTVManager shareInstance].sendClient.delegate = (id)[BundingTVManager shareInstance];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *)downloadedItem:(NSString *)Id
                           index:(NSInteger)index
{
    NSArray * playlists = [CommonMotheds localPlaylists:Id type:type_];
    
    if (0 == playlists.count)
    {
        return nil;
    }
    
    NSDictionary * playInfo = [episodesArr_ objectAtIndex:index];
    
    if (COMIC_TYPE == type_
        || DRAMA_TYPE == type_)
    {
        for (NSDictionary * dic in playlists)
        {
            if ([[dic objectForKey:@"name"] isEqualToString:[NSString stringWithFormat:@"%@_%@",[dic objectForKey:@"itemId"],[playInfo objectForKey:@"name"]]])
            {
                return dic;
            }
        }
    }
    else if (SHOW_TYPE == type_)
    {
        NSString * showId = [NSString stringWithFormat:@"%@_%d",Id,(index + 1)];
        for (NSDictionary * dic in playlists)
        {
            if ([[dic objectForKey:@"subItemId"] isEqualToString:showId])
            {
                return dic;
            }
        }
    }
    else
    {
        for (NSDictionary * dic in playlists)
        {
            if ([[dic objectForKey:@"itemId"] isEqualToString:Id])
            {
                return dic;
            }
        }
    }
    return nil;
}

-(NSMutableDictionary *)checkDownloadUrls:(NSDictionary *)iDic
{
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:iDic];
    NSMutableArray * downloadArr = [NSMutableArray arrayWithArray:[dic objectForKey:@"down_urls"]];
    
    for (int i = 0; i < downloadArr.count; i++)
    {
        NSMutableDictionary * downloadInfo = [NSMutableDictionary dictionaryWithDictionary:[downloadArr objectAtIndex:i]];
        if (![[downloadInfo objectForKey:@"source"] isEqualToString:@"baidu_wangpan"])
        {
            continue;
        }
        
        NSArray * urlArr = [downloadInfo objectForKey:@"urls"];
        NSMutableArray * newArr = [NSMutableArray array];
        if (0 != urlArr.count)
        {
            NSDictionary * urlDic = [urlArr objectAtIndex:0];
            NSString * tureDownloadURL = [CommonMotheds getDownloadURLWithHTML:[urlDic objectForKey:@"url"]];
            NSMutableDictionary * newDic = [NSMutableDictionary dictionary];
            [newDic setObject:[urlDic objectForKey:@"file"] forKey:@"file"];
            [newDic setObject:[urlDic objectForKey:@"type"] forKey:@"type"];
            [newDic setObject:tureDownloadURL forKey:@"url"];
            [newArr addObject:newDic];
        }
        [downloadInfo setObject:newArr forKey:@"urls"];
        [downloadArr replaceObjectAtIndex:i withObject:downloadInfo];
    }
    
    [dic setObject:downloadArr forKey:@"down_urls"];
    
    return dic;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

- (void)showOpSuccessModalView:(float)closeTime with:(int)type
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    view.tag = VIEWTAG;
    [view setBackgroundColor:[UIColor clearColor]];
   
    if (type == REPORT)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 80)];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.text = @"您提交的错误我们已经收到，我们会尽快处理，谢谢您的支持.";
        label.center = view.center;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:12];
        label.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        label.layer.cornerRadius = 4;
        label.textColor = [UIColor whiteColor];
        [view addSubview:label];
    }
    else if (type == DING
             || ADDEXPECT == type)
    {
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 92, 27)];
        label.backgroundColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.alpha = 0.9;
        label.center = view.center;
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 6.0;
        label.text = @"操作成功";
        [view addSubview:label];
        
    }
    else if(type == ADDFAV){
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 92, 27)];
        label.backgroundColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.alpha = 0.9;
        label.center = view.center;
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 6.0;
        label.text = @"收藏成功";
        [view addSubview:label];
    }
    else if(type == UN_ADDFAV){
        UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 92, 27)];
        label.backgroundColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.alpha = 0.9;
        label.center = view.center;
        label.layer.masksToBounds = YES;
        label.layer.cornerRadius = 6.0;
        label.text = @"取消成功";
        [view addSubview:label];
    }
    
    [self.view addSubview:view];
    [NSTimer scheduledTimerWithTimeInterval:closeTime target:self selector:@selector(removeOverlay) userInfo:nil repeats:NO];
}
- (void)showOpFailureModalView:(float)closeTime with:(int)type
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    view.tag = VIEWTAG;
    [view setBackgroundColor:[UIColor clearColor]];
    UILabel *label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 92, 27)];
    label.backgroundColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.alpha = 0.9;
    label.center = view.center;
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 6.0;
    if (type == DING) {
       label.text = @"已顶过";
        
    }
    else if (type == ADDFAV) {
       label.text = @"已收藏过";
    }
    else if (ADDEXPECT == type)
    {
        NSString * text = @"想看影片已加入收藏记录";
        CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:12]];
        label.frame = CGRectMake(0, 0, size.width + 15, 27);
        label.text = @"想看影片已加入收藏记录";
        label.center = view.center;
    }
    [view addSubview:label];
  
     [self.view addSubview:view];
    [NSTimer scheduledTimerWithTimeInterval:closeTime target:self selector:@selector(removeOverlay) userInfo:nil repeats:NO];
}
- (void)removeOverlay
{
  for(UIView *view in self.view.subviews ){
      if (view.tag == VIEWTAG) {
          [view removeFromSuperview];
          break;
     }
  
  }
    
}


-(void)share:(id)sender event:(UIEvent *)event{
    
    if (![self checkNetWork]) {
        [UIUtility showNetWorkError:self.view];
        return;
    }
//    TSActionSheet *actionSheet = [[TSActionSheet alloc] initWithTitle:@"分享到："];
//    [actionSheet addButtonWithTitle:@"新浪微博" block:^{
//        [self selectIndex:0];
//    }];
//    [actionSheet addButtonWithTitle:@"微信好友" block:^{
//        [self selectIndex:1];
//    }];
//    [actionSheet addButtonWithTitle:@"微信朋友圈" block:^{
//        [self selectIndex:2];
//    }];
//    [actionSheet cancelButtonWithTitle:@"取消" block:nil];
//    actionSheet.cornerRadius = 5;
//    
//    [actionSheet showWithTouch:event];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"分享到：" delegate:self cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"新浪微博",@"微信好友",@"微信朋友圈", nil];
    sheet.tag = 10000001;
     [sheet showFromTabBar:self.tabBarController.tabBar];

    
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (![self checkNetWork]) {
        [UIUtility showNetWorkError:self.view];
        return;
    }
    if (actionSheet.tag == 10000001) {
        if (buttonIndex == 0) {
            [self sinaShare];
        }
        else if(buttonIndex == 1 || buttonIndex == 2){
            if ([WXApi isWXAppInstalled]) {
                if (buttonIndex == 1){
                    [self wechatShare:WXSceneSession];
                    [MobClick event:@"ue_wechat_friend_share"];
                }
                else if(buttonIndex == 2){
                    [self wechatShare:WXSceneTimeline];
                    [MobClick event:@"ue_wechat_social_share"];
                }
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"亲，你还没有安装微信，请安装后再试。" delegate:self cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil];
                [alert show];
            }
        }
    }
    else if (actionSheet.tag == 10000002){
        if (buttonIndex == 0) {
            [self beginPlayVideo:playNum_];
        }
        else if (buttonIndex == 1){  //play with tv;
        
        }
    }
    
}

-(void)sinaShare{
    _mySinaWeibo = [AppDelegate instance].sinaweibo;
    _mySinaWeibo.delegate = self;
    if ([_mySinaWeibo isLoggedIn]) {
        SendWeiboViewController *sendV = [[SendWeiboViewController alloc] init];
        sendV.infoDic = infoDic_;
        [self presentViewController:[[CustomNavigationViewControllerPortrait alloc] initWithRootViewController:sendV] animated:YES completion:nil];
    }
    else{
        [_mySinaWeibo logIn];
        
    }
}

-(void)wechatShare:(int)sence{
        WXMediaMessage *message = [WXMediaMessage message];
        NSString *name = name_;
        if (sence == 0) {
            message.title = @"分享部影片给你 ";
            message.description = [NSString stringWithFormat:@"我正在看《%@》，不错哦，推荐给你~",name];
        }
        else if (sence == 1){
            message.title = [NSString stringWithFormat:@"我正在看《%@》，不错哦，推荐给你~",name];;
        }
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:wechatImgStr_]]];
        UIImage *newImage = [image resizedImage:CGSizeMake(image.size.width*0.5, image.size.height*0.5) interpolationQuality:kCGInterpolationLow];
        [message setThumbImage:newImage];
    
        WXWebpageObject *ext = [WXWebpageObject object];
        ext.webpageUrl = [NSString stringWithFormat:@"http://weixin.joyplus.tv/info.php?prod_id=%@",prodId_];
        message.mediaObject = ext;
    
        SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        req.bText = NO;
        req.message = message;
        req.scene = sence;
        
        [WXApi sendReq:req];

}
-(void)removeView{
    [segmentedControl_ removeFromSuperview];
}


- (void)showSuccessModalView
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    view.tag = 100000001;
    [view setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
    UIImageView *temp = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"success_img"]];
    temp.frame = CGRectMake(0, 0, 200, 100);
    temp.center = view.center;
    [view addSubview:temp];
    [self.view addSubview:view];
    [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(removeSucceedOverlay) userInfo:nil repeats:NO];
}

- (void)removeSucceedOverlay
{
    UIView *view = (UIView *)[self.view viewWithTag:100000001];
    for(UIView *subview in view.subviews){
        [subview removeFromSuperview];
    }
    [view removeFromSuperview];
    view = nil;
}



#pragma mark - SinaWeibo Delegate
- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo{
    
    SendWeiboViewController *sendV = [[SendWeiboViewController alloc] init];
    sendV.infoDic = infoDic_;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:sendV] animated:YES completion:nil];
    
    NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                              sinaweibo.accessToken, @"AccessTokenKey",
                              sinaweibo.expirationDate, @"ExpirationDateKey",
                              sinaweibo.userID, @"UserIDKey",
                              sinaweibo.refreshToken, @"refresh_token", nil];
    [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"SinaWeiboAuthData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [sinaweibo requestWithURL:@"users/show.json"
                       params:[NSMutableDictionary dictionaryWithObject:sinaweibo.userID forKey:@"uid"]
                   httpMethod:@"GET"
                     delegate:self];
    
}
- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo{
    NSLog(@"sinaweiboDidLogOut");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
    [[ContainerUtility sharedInstance] removeObjectForKey:kUserAvatarUrl];
    [[ContainerUtility sharedInstance] removeObjectForKey:kUserNickName];
    [ActionUtility generateUserId:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SINAWEIBOCHANGED" object:nil];
    }];
    
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo{
    NSLog(@"sinaweiboLogInDidCancel");
    
}
- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error{
    NSLog(@"sinaweibo logInDidFailWithError %@", error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"网络数据错误，请重新登陆。"
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}
- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error{
    NSLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                        message:@"Token已过期，请重新登陆。"
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}
#pragma mark - SinaWeiboRequest Delegate

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)userInfo{
    if ([request.url hasSuffix:@"users/show.json"])
    {
        NSString *username = [userInfo objectForKey:@"screen_name"];
        [[ContainerUtility sharedInstance] setAttribute:username forKey:kUserNickName];
        NSString *avatarUrl = [userInfo objectForKey:@"avatar_large"];
        [[ContainerUtility sharedInstance] setAttribute:avatarUrl forKey:kUserAvatarUrl];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"SINAWEIBOCHANGED" object:nil];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys: [userInfo objectForKey:@"idstr"], @"source_id", @"1", @"source_type", nil];
        [[AFServiceAPIClient sharedClient] postPath:kPathUserValidate parameters:parameters success:^(AFHTTPRequestOperation *operation, id result) {
            NSString *responseCode = [result objectForKey:@"res_code"];
            if(responseCode == nil){
                NSString *user_id = [result objectForKey:@"user_id"];
                [[AFServiceAPIClient sharedClient] setDefaultHeader:@"user_id" value:user_id];
                [[ContainerUtility sharedInstance] setAttribute:user_id forKey:kUserId];
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


-(void)playVideo:(int)num{
    if(![[UIApplication sharedApplication].delegate performSelector:@selector(isWifiReachable)]){
        willPlayIndex = num;
        UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil
                                                           message:@"播放视频会消耗大量流量，您确定要在非WiFi环境下播放吗？"
                                                          delegate:self
                                                 cancelButtonTitle:@"取消"
                                                 otherButtonTitles:@"确定", nil];
        alertView.tag = 8888;
        [alertView show];
    } else {
        [self willPlayVideo:num];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 8888) {
        if(buttonIndex == 1){
            [self willPlayVideo:willPlayIndex];
        }
    }
    else if(alertView.tag == 9999){
        NSDictionary *dic = [episodesArr_ objectAtIndex:playNum_];
        NSArray *webUrlArr = [dic objectForKey:@"video_urls"];
        NSDictionary *urlInfo = [webUrlArr objectAtIndex:0];
       
        if (buttonIndex == 0) {
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[urlInfo objectForKey:@"url"]]];
        }
        else if(buttonIndex == 1){
         [self beginPlayVideo:playNum_];
        }
    
    }
    
}

- (void)willPlayVideo:(int)num
{
    if (num < 0 || num >= episodesArr_.count) {
        return;
    }
    playNum_ = num;
    if ([[AppDelegate instance].showVideoSwitch isEqualToString:@"2"]) {
        NSDictionary *dic = [episodesArr_ objectAtIndex:num];
        NSArray *webUrlArr = [dic objectForKey:@"video_urls"];
        NSDictionary *urlInfo = [webUrlArr objectAtIndex:0];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[urlInfo objectForKey:@"url"]]];
        return;
    }
    else if([[AppDelegate instance].showVideoSwitch isEqualToString:@"3"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"将使用何种方式来播放？" delegate:self cancelButtonTitle:@"Safari" otherButtonTitles:@"内置浏览器", nil];
        alert.tag = 9999;
        [alert show];
        return;
    }
    
    [self beginPlayVideo:num];
    
//    NSString *userId = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:@"kUserId"];
//    NSDictionary * data = (NSDictionary *)[[ContainerUtility sharedInstance] attributeForKey:[NSString stringWithFormat:@"%@_isBunding",userId]];
//    NSNumber * isbunding = [data objectForKey:KEY_IS_BUNDING];
//    isbunding = [NSNumber numberWithInt:1];
//    if ([isbunding boolValue]){
//        if (![BundingTVManager shareInstance].isConnected)
//        {
//            NSString * sendChannel = [NSString stringWithFormat:@"/screencast/CHANNEL_TV_%@",[data objectForKey:KEY_MACADDRESS]];
//            [[BundingTVManager shareInstance] connecteServerWithChannel:sendChannel];
//        }
//        [BundingTVManager shareInstance].sendClient.delegate = (id <FayeClientDelegate>)self;
//        
//        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"使用哪种方式打开：" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"直接打开",@"使用悦视频TV版播放", nil];
//        sheet.tag = 10000002;
//        [sheet showInView:self.tabBarController.tabBar];
//    }
//    else{
//      [self beginPlayVideo:num];
//    }
    
   
}

-(void)beginPlayVideo:(int)num{

    NSDictionary * info = [self downloadedItem:self.prodId index:num];
    if (nil != info)
    {
        IphoneAVPlayerViewController *iphoneAVPlayerViewController = [[IphoneAVPlayerViewController alloc] init];
        
        iphoneAVPlayerViewController.local_file_path = [info objectForKey:@"videoUrl"];
        if ([[info objectForKey:@"downloadType"] isEqualToString:@"m3u8"])
        {
            [[AppDelegate instance] startHttpServer];
            iphoneAVPlayerViewController.isM3u8 = YES;
            iphoneAVPlayerViewController.playDuration = [[info objectForKey:@"duration"] doubleValue];
            iphoneAVPlayerViewController.playNum = num;
        }
        iphoneAVPlayerViewController.islocalFile = YES;
        NSInteger type = [[info objectForKey:@"type"] intValue];
        NSString * subitemId = [info objectForKey:@"subItemId"];
        
        NSString *str = subitemId;
        if (type == 2)
        {
            //            NSString *name = [[name1 componentsSeparatedByString:@"_"] objectAtIndex:0];
            //            NSString *sub_name = [[subitemId componentsSeparatedByString:@"_"] objectAtIndex:1];
            iphoneAVPlayerViewController.nameStr = self.name;
            iphoneAVPlayerViewController.playNum = num;
            iphoneAVPlayerViewController.videoType = DRAMA_TYPE;
        }
        else if (type == 3){
            //            iphoneAVPlayerViewController.nameStr =  [[name1 componentsSeparatedByString:@"_"] lastObject];
            //            NSString *sub_name = [[subitemId componentsSeparatedByString:@"_"] objectAtIndex:1];
            iphoneAVPlayerViewController.playNum = num;
            iphoneAVPlayerViewController.videoType = SHOW_TYPE;
        }
        else if (MOVIE_TYPE == type)
        {
            subitemId = [info objectForKey:@"itemId"];
            iphoneAVPlayerViewController.nameStr = self.name;
            iphoneAVPlayerViewController.playNum = 0;
            iphoneAVPlayerViewController.videoType = MOVIE_TYPE;
            str = [NSString stringWithFormat:@"%@_1",prodId_];
        }
        
        NSNumber *cacheResult = [[CacheUtility sharedCache] loadFromCache:str];
        iphoneAVPlayerViewController.lastPlayTime = CMTimeMakeWithSeconds(cacheResult.floatValue + 1, NSEC_PER_SEC);
        iphoneAVPlayerViewController.prodId = self.prodId;
        iphoneAVPlayerViewController.episodesArr = episodesArr_;
        
        [self presentViewController:iphoneAVPlayerViewController animated:YES completion:nil];
        return;
    }
    
    IphoneWebPlayerViewController *iphoneWebPlayerViewController = [[IphoneWebPlayerViewController alloc] init];
    iphoneWebPlayerViewController.playNum = num;
    iphoneWebPlayerViewController.nameStr = name_;
    iphoneWebPlayerViewController.episodesArr = episodesArr_;
    iphoneWebPlayerViewController.videoType = type_;
    iphoneWebPlayerViewController.prodId = prodId_;
    NSString *str = [NSString stringWithFormat:@"%@_%@",prodId_,[NSString stringWithFormat:@"%d",(num+1) ]];
    NSNumber *cacheResult = [[CacheUtility sharedCache] loadFromCache:str];
    
    iphoneWebPlayerViewController.playBackTime = cacheResult;
    [self presentViewController:[[CustomNavigationViewController alloc] initWithRootViewController:iphoneWebPlayerViewController] animated:YES completion:nil];

}

-(BOOL)checkNetWork{
    //Reachability *hostReach = [Reachability reachabilityForInternetConnection];
    if([[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]){
        return YES;
    }
    else{
        return NO;
    }

}

- (void)checkCanPlayVideo
{
    for (NSDictionary *epi in episodesArr_) {
        NSArray *videoUrls = [epi objectForKey:@"video_urls"];
        for (NSDictionary *videoUrl in videoUrls) {
            NSString *url = [videoUrl objectForKey:@"url"];
            NSString *source = [videoUrl objectForKey:@"source"];
            NSString *trimUrl = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([source isEqualToString:@"yuanxian"]) {
                canPlayVideo = NO;
                return;
            }
            if (trimUrl && trimUrl.length > 0) {
                canPlayVideo = YES;
                break;
            }
        }
        if (canPlayVideo) {
            break;
        } else {
            NSArray *downUrls = [epi objectForKey:@"down_urls"];
            for (NSDictionary *downUrl in downUrls) {
                NSArray *urls = [downUrl objectForKey:@"urls"];
                for (NSDictionary *url in urls) {
                    NSString *realurl = [url objectForKey:@"url"];
                    NSString *trimUrl = [realurl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if (trimUrl && trimUrl.length > 0) {
                        canPlayVideo = YES;
                        break;
                    }
                }
                if (canPlayVideo) {
                    break;
                }
            }
        }
    }
}

#pragma mark -
#pragma mark FayeObjc delegate
- (void) messageReceived:(NSDictionary *)messageDict
{
    if ([[messageDict objectForKey:@"push_type"] isEqualToString:@"31"])
    {
        
    }
    else if ([[messageDict objectForKey:@"push_type"] isEqualToString:@"32"])
    {
        
    }
    else if ([[messageDict objectForKey:@"push_type"] isEqualToString:@"42"])
    {
        isTVReady = YES;
    }
}

- (void)connectedToServer
{
    
}

- (void)disconnectedFromServer
{
    [[BundingTVManager shareInstance] reconnectToServer];
    [BundingTVManager shareInstance].sendClient.delegate = (id<FayeClientDelegate>)self;
}

- (void)socketDidSendMessage:(ZTWebSocket *)aWebSocket
{
    
}

- (void)subscriptionFailedWithError:(NSString *)error
{
    
}
- (void)subscribedToChannel:(NSString *)channel
{
    
}

#pragma mark -
#pragma mark - 控制投放TV接口(private)
- (void)controlCloundTV:(NSInteger)controlType
{
    NSString *userId = (NSString *)[[ContainerUtility sharedInstance]attributeForKey:@"kUserId"];
    NSDictionary * data = (NSDictionary *)[[ContainerUtility sharedInstance] attributeForKey:[NSString stringWithFormat:@"%@_isBunding",userId]];
    NSString * sendChannel = [NSString stringWithFormat:@"CHANNEL_TV_%@",[data objectForKey:KEY_MACADDRESS]];
//    double curTime = mScrubber.value * CMTimeGetSeconds([self playerItemDuration]);
    NSNumber * type = [NSNumber numberWithInt:type_];
    NSString * cType = @"403";
//    NSDictionary *reqData = [NSDictionary dictionaryWithObjectsAndKeys:
//                             cType, @"push_type",
//                             userId, @"user_id",
//                             sendChannel, @"tv_channel",
//                             [NSNumber numberWithFloat:curTime],@"prod_time",
//                             workingUrl_,@"prod_url",
//                             prodId_,@"prod_id",
//                             nameStr_,@"prod_name",
//                             type,@"prod_type",
//                             nil];
//    
//    [[BundingTVManager shareInstance] sendMsg:reqData];
}


@end
