//
//  ResidentPopInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 7/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResidentPopInfoViewController : UIViewController

@property (nonatomic, strong) NSDictionary *residentInfo;

@property (nonatomic, weak) IBOutlet UILabel *surveyAddressLabel;
@property (nonatomic, weak) IBOutlet UILabel *areaLabel;
@property (nonatomic, weak) IBOutlet UILabel *residentNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *ageLabel;
@property (nonatomic, weak) IBOutlet UILabel *genderLabel;
@property (nonatomic, weak) IBOutlet UILabel *raceLabel;
@property (nonatomic, weak) IBOutlet UILabel *residentAddressLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitNoLabel;
@property (nonatomic, weak) IBOutlet UILabel *contactLabel;


@end
