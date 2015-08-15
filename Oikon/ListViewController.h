//
//  ListViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 25/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface ListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSUserDefaults *settings;

@property (strong, nonatomic) NSManagedObject *selectedExpense;

@property (strong, nonatomic) IBOutlet UITableView *expensesTableView;
@property (strong, nonatomic) IBOutlet UIView *fromDateView;
@property (strong, nonatomic) IBOutlet UIView *toDateView;

@property (strong, nonatomic) NSMutableArray *expenses;

@property (strong, nonatomic) IBOutlet UILabel *fromDateDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *fromDateMonthLabel;
@property (strong, nonatomic) IBOutlet UILabel *toDateDayLabel;
@property (strong, nonatomic) IBOutlet UILabel *toDateMonthLabel;

@property (strong, nonatomic) IBOutlet UITextField *fromDateTextView;
@property (strong, nonatomic) IBOutlet UITextField *toDateTextView;

@property (strong, nonatomic) NSDate *currentFromDate;
@property (strong, nonatomic) NSDate *currentToDate;
@property (strong, nonatomic) NSMutableArray *currentFilterTypes;
@property (strong, nonatomic) NSString *currentFilterName;

@property (strong, nonatomic) IBOutlet UILabel *tableHeaderName;
@property (strong, nonatomic) IBOutlet UILabel *tableHeaderType;
@property (strong, nonatomic) IBOutlet UILabel *tableHeaderValue;

@property (strong, nonatomic) NSDate *lastiCloudFetch;


@property (strong, nonatomic) IBOutlet UILabel *totalExpensesValueLabel;

- (IBAction) exportCSVToEmail;
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
- (void) fetchSearchSettings;
- (void) getAllExpenses;

@end
