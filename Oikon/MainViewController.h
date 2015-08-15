//
//  MainViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 25/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) NSMutableArray *expenseTypes;

@property (strong, nonatomic) IBOutlet UITextField *expenseValueTextField;
@property (strong, nonatomic) IBOutlet UITextField *expenseNameTextField;
@property (strong, nonatomic) IBOutlet UIButton *moreOptionsButton;
@property (strong, nonatomic) IBOutlet UIButton *simpleAddExpenseButton;

@property (strong, nonatomic) IBOutlet UIImageView *moreOptionsImageView;
@property (strong, nonatomic) IBOutlet UIImageView *lessOptionsImageView;


@property (strong, nonatomic) IBOutlet UIButton *lessOptionsButton;
@property (strong, nonatomic) IBOutlet UITextField *expenseDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *expenseTypeTextField;
@property (strong, nonatomic) IBOutlet UIButton *advancedAddExpenseButton;

@property (strong, nonatomic) IBOutlet UIView *groupedView;
@property (strong, nonatomic) IBOutlet UIView *lessOptionsPageView;
@property (strong, nonatomic) IBOutlet UIView *moreOptionsPageView;

@property (strong, nonatomic) NSDate *lastiCloudFetch;

- (IBAction)saveExpense:(id)sender;
- (void)showMenu:(id)sender;

- (NSString *)formatDate:(NSDate *)date;
- (NSDate *)getDateFromString:(NSString *)date;
- (void)getAllExpenseTypes;
- (NSInteger)getIndexForExpenseTypeName:(NSString *)expenseTypeName;

@end
