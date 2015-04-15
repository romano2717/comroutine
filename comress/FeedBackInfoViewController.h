//
//  FeedBackInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Feedback.h"

@interface FeedBackInfoViewController : UIViewController
{
    Database *myDatabase;
    Feedback *feedback;
}

@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedBackLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *relatedContract;


@property (nonatomic, strong) NSNumber *feedbackId;
@property (nonatomic, strong) NSDictionary *feedbackDict;


@end
