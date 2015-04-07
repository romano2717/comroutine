//
//  ResidentPopInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 7/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentPopInfoViewController.h"

@interface ResidentPopInfoViewController ()

@end

@implementation ResidentPopInfoViewController

@synthesize residentInfo;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDictionary *survey = [residentInfo objectForKey:@"survey"];
    NSDictionary *residentAddress = [residentInfo objectForKey:@"residentAddress"];
    NSDictionary *surveyAddress = [residentInfo objectForKey:@"surveyAddress"];
    
    self.surveyAddressLabel.text = [surveyAddress valueForKey:@"address"];
    self.areaLabel.text = [surveyAddress valueForKey:@"specify_area"];
    self.ageLabel.text = [survey valueForKey:@"resident_age_range"];
    self.genderLabel.text = [survey valueForKey:@"resident_gender"];
    self.raceLabel.text = [survey valueForKey:@"resident_race"];
    self.residentAddressLabel.text = [residentAddress valueForKey:@"address"];
    self.unitNoLabel.text = [residentAddress valueForKey:@"unit_no"];
    self.contactLabel.text = [survey valueForKey:@"resident_contact"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
