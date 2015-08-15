//
//  FilterViewCell.m
//  Oikon
//
//  Created by Bruno Bernardino on 01/09/14.
//  Copyright (c) 2014 emotionLoop. All rights reserved.
//

#import "FilterViewCell.h"

@implementation FilterViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
