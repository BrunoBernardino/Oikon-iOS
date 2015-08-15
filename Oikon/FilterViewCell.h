//
//  FilterViewCell.h
//  Oikon
//
//  Created by Bruno Bernardino on 01/09/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *expenseTypeNameLabel;
@property (strong, nonatomic) IBOutlet UISwitch *expenseTypeSwitch;


@end
