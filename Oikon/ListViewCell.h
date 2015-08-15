//
//  ListViewCell.h
//  Oikon
//
//  Created by Bruno Bernardino on 26/05/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UILabel *valueLabel;

@end
