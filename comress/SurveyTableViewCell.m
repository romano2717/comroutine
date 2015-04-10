//
//  SurveyTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyTableViewCell.h"

@implementation SurveyTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    @try {
        NSDictionary *survey = [dict objectForKey:@"survey"];
        NSDictionary *address = [dict objectForKey:@"address"];
        
        if(survey != nil)
        {
            if([survey valueForKey:@"resident_name"] != [NSNull null])
                self.residentName.text = [survey valueForKey:@"resident_name"];
            
            double timeStamp = [[survey valueForKey:@"survey_date"] doubleValue];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
            
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"dd-MMM-YYYY h:mm"];
            NSString *datestring = [format stringFromDate:date];
            
            self.dateLabel.text = [NSString stringWithFormat:@"%@",datestring];
            
            int rating = [[survey valueForKey:@"average_rating"] intValue];

            if(rating <= 3)
                self.ratingImageView.image = [UIImage imageNamed:@"threeOfThreeStars@2x"];
            if(rating <= 2)
                self.ratingImageView.image = [UIImage imageNamed:@"twoOfThreeStars@2x"];
            if(rating <= 1)
                self.ratingImageView.image = [UIImage imageNamed:@"oneOfThreeStars@2x"];
        }
        
        

        if(address != nil)
        {
            if([survey valueForKey:@"address"] != [NSNull null])
                self.addressLabel.text = [address valueForKey:@"address"];
        }
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"NSException %@",exception);
    }
    @finally {

    }
}

@end
