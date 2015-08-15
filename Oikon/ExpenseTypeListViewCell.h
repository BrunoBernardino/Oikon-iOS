//
//  ExpenseTypeListViewCell.h
//  Oikon
//
//  Created by Bruno Bernardino on 07/06/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExpenseTypeListViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *expensesCountLabel;

@end
