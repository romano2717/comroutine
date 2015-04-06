//
//  ResidentInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ActionSheetStringPicker.h"
#import "Database.h"
#import "FeedBackViewController.h"
#import "SurveyDetailViewController.h"

@interface ResidentInfoViewController : UIViewController<UIAlertViewDelegate>
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITextField *surveyAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *areaTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *residentNameTxFld;

@property (nonatomic, weak) IBOutlet UITextField *residentAddressTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *unitNoTxtFld;
@property (nonatomic, weak) IBOutlet UITextField *contactNoTxFld;

@property (nonatomic, weak) IBOutlet UIButton *ageBtn;
@property (nonatomic, weak) IBOutlet UIButton *raceBtn;

@property (nonatomic, strong) NSNumber *surveyId;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic,strong) NSString *postalCode;

@property (nonatomic, strong) NSArray *ageRangeArray;
@property (nonatomic, strong) NSArray *raceArray;
@property (nonatomic, strong) NSString *gender;

@property (nonatomic) long long currentSurveyId;

@property (nonatomic, strong) NSNumber *averageRating;



@end
