//
//  IphoneSettingViewController.h
//  yueshipin
//
//  Created by 08 on 12-12-26.
//  Copyright (c) 2012年 joyplus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinaWeibo.h"
#import "UMUFPGridView.h"
@interface IphoneSettingViewController : UIViewController<SinaWeiboDelegate, SinaWeiboRequestDelegate,GridViewDelegate,GridViewDataSource,UMUFPTableViewDataLoadDelegate>{
    UISwitch *sinaSwith_;
     SinaWeibo *sinaweibo_;
    UILabel *weiboName_;
    
    UMUFPGridView *_mGridView;
}
@property (strong, nonatomic) UISwitch *sinaSwith;
@property (strong, nonatomic) SinaWeibo *sinaweibo;
@property (strong, nonatomic) UILabel *weiboName;

@property (nonatomic, strong)UMUFPGridView *mGridView;
@end
