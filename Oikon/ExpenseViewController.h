//
//  ExpenseViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 08/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface ExpenseViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) NSManagedObject *currentExpense;
@property (strong, nonatomic) MainViewController *mainViewControllerReference;

@property (strong, nonatomic) IBOutlet UIView *expenseNameView;
@property (strong, nonatomic) IBOutlet UITextField *expenseNameTextField;

@property (strong, nonatomic) IBOutlet UIView *expenseTypeView;
@property (strong, nonatomic) IBOutlet UITextField *expenseTypeTextField;

@property (strong, nonatomic) IBOutlet UIView *expenseDateView;
@property (strong, nonatomic) IBOutlet UITextField *expenseDateTextField;

@property (strong, nonatomic) IBOutlet UIView *expenseValueView;
@property (strong, nonatomic) IBOutlet UITextField *expenseValueTextField;

@property (strong, nonatomic) NSDate *lastiCloudFetch;

@end
