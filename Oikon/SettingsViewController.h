//
//  SettingsViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 14/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UIAlertViewDelegate>

@property (strong, nonatomic) NSUserDefaults *settings;

@property (strong, nonatomic) NSNumber *attempts;
@property (strong, nonatomic) NSString *temporaryPasscode;

@property (strong, nonatomic) IBOutlet UIView *passcodeView;
@property (strong, nonatomic) IBOutlet UISwitch *passcodeSwitch;

@property (strong, nonatomic) IBOutlet UIView *iCloudView;
@property (strong, nonatomic) IBOutlet UISwitch *iCloudSwitch;

@property (strong, nonatomic) IBOutlet UIView *syncStatusView;
@property (strong, nonatomic) IBOutlet UILabel *syncStatusLabel;

@property (strong, nonatomic) IBOutlet UIButton *removeAllDataButton;

@property (strong, nonatomic) NSDate *lastiCloudFetch;

@end
