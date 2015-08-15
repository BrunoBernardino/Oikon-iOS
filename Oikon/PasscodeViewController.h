//
//  PasscodeViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 14/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PasscodeViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSNumber *attempts;

@property (strong, nonatomic) IBOutlet UITextField *passcodeTextField;

@end
