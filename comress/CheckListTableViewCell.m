//
//  CheckListTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListTableViewCell.h"

@implementation CheckListTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    self.checkList.text = [dict valueForKey:@"w_item"];
    self.checkBoxBtn.tag = [[dict valueForKey:@"id"] intValue];
}

@end
