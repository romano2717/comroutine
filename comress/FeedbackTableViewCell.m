//
//  FeedbackTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedbackTableViewCell.h"

@implementation FeedbackTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    DDLogVerbose(@"%@",dict);
    
    NSDictionary *address = [dict objectForKey:@"address"];
    NSDictionary *feedBack = [dict objectForKey:@"feedback"];
    
    self.addressLabel.text = [address valueForKey:@"address"];
    self.feedbackLabel.text = [feedBack valueForKey:@"description"];
}

@end
