//
//  FeedBackViewController.h
//  comress
//
//  Created by Diffy Romano on 4/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "CreateIssueViewController.h"
#import "Survey.h"

@interface FeedBackViewController : UIViewController<UIScrollViewDelegate,UIAlertViewDelegate>
{
    Database *myDatabase;
}
@property (nonatomic)BOOL pushFromSurvey;
@property (nonatomic)BOOL pushFromSurveyDetail;

@property (nonatomic, strong) NSNumber *currentClientSurveyId;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet UITextView *feedBackTextView;

@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocSurveyAddBtn;
@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocResidentAddBtn;
@property (nonatomic, weak) IBOutlet UIButton *feedBackToLocOthersAddBtn;
@property (nonatomic, weak) IBOutlet UITextField *othersAddTxtField;

@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;

@property (nonatomic, strong) NSString *selectedFeedBackLoc;
@property (nonatomic, strong) NSMutableArray *selectedFeeBackTypeArr;
@property (nonatomic, strong) NSMutableArray *selectedFeeBackTypeStringArr;

@property (nonatomic, strong) NSString *postalCode;

@property (nonatomic) BOOL pushFromSurveyAndModalFromFeedback;

@end
