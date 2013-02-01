//
//  MovieDetailViewController.h
//  yueshipin
//
//  Created by 08 on 12-12-28.
//  Copyright (c) 2012年 joyplus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IphoneVideoViewController.h"
#import "MNMBottomPullToRefreshManager.h"
@interface IphoneMovieDetailViewController : IphoneVideoViewController< MNMBottomPullToRefreshManagerClient>{
    NSDictionary *infoDic_;
    NSDictionary *videoInfo_;
    int videoType_;
    NSString *summary_;
    NSMutableArray *commentArray_;
    NSArray *relevantList_;
    int favCount_;
    int supportCount_;
    UIImageView *summaryBg_;
    UILabel *summaryLabel_;
    UIButton *moreBtn_;
    BOOL _reloading;
    NSUInteger reloads_;
    MNMBottomPullToRefreshManager *pullToRefreshManager_;

}
@property (nonatomic, strong) NSDictionary *infoDic;
@property (nonatomic, strong) NSDictionary *videoInfo;
@property (nonatomic, assign) int videoType;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSMutableArray *commentArray;
@property (nonatomic, strong) NSArray *relevantList;
@property (nonatomic, strong) UIImageView *summaryBg;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIButton *moreBtn;
@property (strong, nonatomic) MNMBottomPullToRefreshManager *pullToRefreshManager;
//- (void)showOpSuccessModalView:(int)closeTime;
@end



