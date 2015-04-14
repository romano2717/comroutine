//
//  SurveyDetailViewController.h
//  ;;
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuestionsTableViewCell.h"
#import "FeedbackTableViewCell.h"
#import "Survey.h"
#import "Database.h"
#import "FeedBackViewController.h"
#import "FPPopoverKeyboardResponsiveController.h"
#import "ResidentPopInfoViewController.h"

@interface SurveyDetailViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Survey *survey;
    Database *myDatabase;
    FPPopoverKeyboardResponsiveController *popover;    
}
@property (nonatomic, strong) NSNumber *surveyId;

@property (nonatomic, weak) IBOutlet UITableView *surveyDetailTableView;
@property (nonatomic, weak) IBOutlet UIImageView *averageRatingImageView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic) BOOL pushFromResidentInfo;

@property (nonatomic) BOOL pushFromIssue;

@property (nonatomic, weak) IBOutlet UIButton *residentInfoBtn;

@end
