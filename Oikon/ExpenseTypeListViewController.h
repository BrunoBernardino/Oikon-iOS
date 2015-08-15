//
//  ExpenseTypeListViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 07/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExpenseTypeListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *expenseTypeListTableView;
@property (strong, nonatomic) IBOutlet UIButton *addExpenseTypeButton;

@property (strong, nonatomic) NSMutableArray *expenseTypes;

@property (strong, nonatomic) NSManagedObject *expenseTypeBeingUpdated;

@property (strong, nonatomic) NSDate *lastiCloudFetch;

@end
