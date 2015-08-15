//
//  ListFilterTypeViewController.h
//  Oikon
//
//  Created by Bruno Bernardino on 01/09/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface ListFilterTypeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSUserDefaults *settings;

@property (strong, nonatomic) MainViewController *mainViewControllerReference;

@property (strong, nonatomic) NSMutableArray *currentFilterTypes;

@property (strong, nonatomic) IBOutlet UIButton *showAllButton;

@property (strong, nonatomic) IBOutlet UITableView *TypeListTableView;

@end
