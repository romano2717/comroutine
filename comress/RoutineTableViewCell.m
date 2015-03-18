//
//  RoutineTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineTableViewCell.h"

@implementation RoutineTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    NSString *key = [[dict allKeys] objectAtIndex:0];
    
    NSDictionary *blockDict = [dict objectForKey:key];
    
    NSString *blockNo = [blockDict valueForKey:@"block_no"];
    NSString *streetName = [blockDict valueForKey:@"street_name"];

    self.blockNoLabel.text = blockNo;
    
    self.streetLabel.text = streetName;
    
    self.unlockButton.tag = [key intValue];
    [self.unlockButton addTarget:self action:@selector(tappedUnlockButton:) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    self.lastMsgLabel.hidden = YES;
    self.lastMsgByLabel.hidden = YES;
    self.dateLabel.hidden = YES;
    self.msgCount.hidden = YES;
}


- (IBAction)tappedUnlockButton:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInteger:btn.tag];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedUnlockButton" object:nil userInfo:@{@"scheduleId":tag}];
}

@end
