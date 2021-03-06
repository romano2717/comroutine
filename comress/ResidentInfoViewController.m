//
//  ResidentInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentInfoViewController.h"
#import "Synchronize.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface ResidentInfoViewController ()
{

}
@end

@implementation ResidentInfoViewController

@synthesize surveyId,currentLocation,currentSurveyId,averageRating,placemark,didTakeActionOnDataPrivacyTerms,foundPlacesArray,blockId,residentBlockId,didAddFeedBack;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    [self generateData];
    
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}


- (void)generateData
{
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *block_noAndPostal = [NSString stringWithFormat:@"%@ %@",[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]] ;
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@ %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]];
            
            [self.addressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:street_name,@"DisplayText",obj,@"CustomObject",block_noAndPostal,@"DisplaySubText", nil]];
        }];
        
    });
}

#pragma mark MPGTextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //move resident textfield up to give more space for auto suggest
    if(textField.tag == 300)
    {
        CGRect residentTextFieldRect = textField.frame;
        CGRect scrollViewFrame = self.scrollView.frame;
        
        [self.scrollView scrollRectToVisible:CGRectMake(scrollViewFrame.origin.x, residentTextFieldRect.origin.y - 10, scrollViewFrame.size.width, scrollViewFrame.size.height) animated:YES];
        
        textField.text = @"";
        [textField becomeFirstResponder];
    }
    
    else if (textField.tag == 100) //survey address
    {
        textField.text = @"";
        [textField becomeFirstResponder];
    }
}

- (NSArray *)dataForPopoverInTextField:(MPGTextField *)textField
{
    return self.addressArray;
}

- (BOOL)textFieldShouldSelect:(MPGTextField *)textField
{
    return YES;
}

- (void)textField:(MPGTextField *)textField didEndEditingWithSelection:(NSDictionary *)result
{
    if([[result valueForKey:@"CustomObject"] isKindOfClass:[NSDictionary class]] == NO) //user typed some shit!
    {
        if([textField isEqual:self.surveyAddressTxtFld])
            self.postalCode = @"-1"; //because tree got 0 postal code
        else if ([textField isEqual:self.residentAddressTxtFld])
            self.residentPostalCode = @"-1"; //because tree got 0 postal code
        
        return;
    }
    
    DDLogVerbose(@"result %@",result);
    
    if([textField isEqual:self.surveyAddressTxtFld])
    {
        self.surveyAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
        
        blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
        self.postalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    }
    else if ([textField isEqual:self.residentAddressTxtFld])
    {
        self.residentAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
        
        residentBlockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
        self.residentPostalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleDisclame:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    if(btn.tag == 20) //decline
    {
        //update survey as data_protection = 0;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            db.traceExecution = YES;
            BOOL upSu = [db executeUpdate:@"update su_survey set data_protection = ? where client_survey_id = ?",[NSNumber numberWithInt:0],surveyId];
            if(!upSu)
            {
                *rollback = YES;
                return;
            }
        }];
    }
    else //proceed
    {
       //update survey as data_protection = 1;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL upSu = [db executeUpdate:@"update su_survey set data_protection = ? where client_survey_id = ?",[NSNumber numberWithInt:1],surveyId];
            if(!upSu)
            {
                *rollback = YES;
                return;
            }
        }];
    }
    
    self.disclaimerView.hidden = YES;
    
    didTakeActionOnDataPrivacyTerms = YES;
    
    [self preFillOtherInfo];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.currentClientSurveyId =  [NSNumber numberWithLongLong:currentSurveyId];
        fvc.postalCode = self.postalCode;
        fvc.residentPostalCode = self.residentPostalCode;
    }
    else if([segue.identifier isEqualToString:@"push_survey_detail"])
    {
        SurveyDetailViewController *surveyDetail = [segue destinationViewController];
        surveyDetail.clientSurveyId = [NSNumber numberWithLongLong:currentSurveyId];
        surveyDetail.pushFromResidentInfo = YES;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //by default hide the action button until user agree to proceed
    self.navigationController.navigationItem.rightBarButtonItem.width = 0.01;
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.view.frame) * 1.5);
    
    if(didAddFeedBack)
    {
        [self action:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [locationManager stopUpdatingLocation];
}

- (void)preFillOtherInfo
{
    DDLogVerbose(@"found placemarks %@",foundPlacesArray);
    
    NSDictionary *topLocation = [foundPlacesArray firstObject];
    
    self.surveyAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.residentAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.postalCode = [topLocation valueForKey:@"postal_code"];
    self.residentPostalCode = [topLocation valueForKey:@"postal_code"];
    self.blockId = [topLocation valueForKey:@"block_id"];
    self.residentBlockId = [topLocation valueForKey:@"block_id"];
    
    
//    NearbyLocationsViewController *postInfoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyLocationsViewController"];
//    postInfoVc.delegate = self;
//    postInfoVc.foundPlacesArray = foundPlacesArray;
//    
//    popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:postInfoVc];
//    popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.90, CGRectGetHeight(self.view.frame) * 0.80);
//    popover.delegate = self;
//    [popover presentPopoverFromView:self.navigationController.navigationBar];
    
    
    NearbyLocationsViewController *postInfoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyLocationsViewController"];

    UIView *viewV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 160)];
    [viewV setBackgroundColor:[UIColor clearColor]];
    UIPopoverController *popOverController = [[UIPopoverController alloc] initWithContentViewController:postInfoVc];
    popOverController.popoverContentSize = CGSizeMake(150, 160);
    [popOverController setDelegate:self];
    
    [popOverController presentPopoverFromRect:self.navigationController.navigationBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)popoverControllerDidDismissPopover:(FPPopoverController *)popoverController
{
    if(self.dismissPopupByReload == NO)
        [self validatePostalCode];
}

#pragma mark - user tapped a nearby location from pop-up
-(void)selectedTableRow:(NSUInteger)rowNum
{
    [popover dismissPopoverAnimated:YES];
    
    self.surveyAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_no"],[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"street_name"]] ;
    self.residentAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"block_no"],[[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"street_name"]];
    self.postalCode = [[foundPlacesArray objectAtIndex:rowNum] valueForKey:@"postal_code"];
    
    [self validatePostalCode];
}

- (void)closePopUpWithLocationReload:(BOOL)reload
{
    [popover dismissPopoverAnimated:YES];
    
    if(reload)
    {
        self.foundPlacesArray = nil;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Capturing location...";
        
        self.dismissPopupByReload = YES;
        
        //init location manager
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = 100;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        
        [locationManager requestAlwaysAuthorization];
        [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
        
        [self performSelector:@selector(locationReloaded) withObject:nil afterDelay:7.0];
    }
}

#pragma mark - location manager
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    
    BOOL locationIsGood = YES;
    
    if (locationAge > 15.0)
    {
        locationIsGood = NO;
    }
    
    if (loc.horizontalAccuracy < 0)
    {
        locationIsGood = NO;
    }
    
    if(locationIsGood)
    {
        self.currentLocation = loc;
        self.currentLocationFound = YES;
        [locationManager stopUpdatingLocation];
        
        [self getNearbyBlocksWithinTheGrcForThisLocation:loc];
    }
}

- (void)getNearbyBlocksWithinTheGrcForThisLocation:(CLLocation *)location
{
    double current_lat = location.coordinate.latitude;
    double current_lng = location.coordinate.longitude;
    
//    double current_lat = 1.301435;
//    double current_lng = 103.797132;
    
    self.closeAreas = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *nearestBlocks = [db executeQuery:@"select * from blocks where latitude > 0 and longitude > 0"];
        
        while ([nearestBlocks next]) {
            
            NSDictionary *dict = [nearestBlocks resultDictionary];
            
            double lat = [nearestBlocks doubleForColumn:@"latitude"];
            double lng = [nearestBlocks doubleForColumn:@"longitude"];
            
            double distance = (acos(sin(current_lat * M_PI / 180) * sin(lat * M_PI / 180) + cos(current_lat * M_PI / 180) * cos(lat * M_PI / 180) * cos((current_lng - lng) * M_PI / 180)) * 180 / M_PI) * 60 * 1.1515 * 1.609344;
            
            double distanceInMeters = distance * 1000;
            
            if(distanceInMeters <= 500) //500 m
            {
                [self.closeAreas addObject:dict];
            }
        }
        
        self.foundPlacesArray = self.closeAreas;
    }];
}

- (void)locationReloaded
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [self preFillOtherInfo];
}

- (void)validatePostalCode
{
    __block BOOL validPostalCode = NO;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select postal_code from blocks where postal_code = ?",self.postalCode];
        
        if([rs next] == YES)
        {
            validPostalCode = YES;
        }
    }];
    
    if(validPostalCode == NO)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:@"Survey address is not within your GRC, Please select a valid address by typing inside the Survey address field" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        alert.tag = 100;
        [alert show];
    }
}

- (IBAction)selectAge:(id)sender
{
    [self.view endEditing:YES];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Contract type" rows:self.ageRangeArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        [self.ageBtn setTitle:[NSString stringWithFormat:@" %@",[self.ageRangeArray objectAtIndex:selectedIndex]] forState:UIControlStateNormal];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}


- (IBAction)selectRace:(id)sender
{
    [self.view endEditing:YES];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Contract type" rows:self.raceArray initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        [self.raceBtn setTitle:[NSString stringWithFormat:@" %@",[self.raceArray objectAtIndex:selectedIndex]] forState:UIControlStateNormal];
        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        
    } origin:sender];
}

-(IBAction)toggelGender:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    UIButton *femBtn = (UIButton *)[self.view viewWithTag:2];
    UIButton *maleBtn = (UIButton *)[self.view viewWithTag:1];
    
    int tag = (int)btn.tag;
    
    
    [btn setSelected:!btn.selected];
    
    if(tag == 1) //male
    {
        
        self.gender = @"M";
        
        [maleBtn setSelected:YES];
        [femBtn setSelected:NO];
    }
    else
    {
        self.gender = @"F";
        
        [femBtn setSelected:YES];
        [maleBtn setSelected:NO];
    }
}

//this method is replaced by - (IBAction)residentInfoAction:(id)sender
- (IBAction)action:(id)sender
{
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action" message:@"Select what to do next" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add more feedback",@"Complete this survey", nil];
    
    [alert show];
    
    didAddFeedBack = NO; //so this alert will not show again when VC is popped
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        
    }
    else
    {
        if(buttonIndex == 1)
        {
            [self saveResidentAdressWithSegueToFeedback:YES forBtnAction:@"feedback"];
        }
        else if(buttonIndex == 2)
        {
            [self saveResidentAdressWithSegueToFeedback:NO forBtnAction:@"done"];
        }
    }
    
}

- (IBAction)residentInfoAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    if (btn.tag == 1)
        [self saveResidentAdressWithSegueToFeedback:YES forBtnAction:@"feedback"];

    else
        [self saveResidentAdressWithSegueToFeedback:NO forBtnAction:@"done"];
        
}

- (void)saveResidentAdressWithSegueToFeedback:(BOOL)goToFeedback forBtnAction:(NSString *)action
{

    didAddFeedBack = YES;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *survey_date = [NSDate date];
        NSString *resident_name = self.residentNameTxFld.text;
        NSString *resident_age_range = self.ageBtn.titleLabel.text;
        NSString *resident_gender = self.gender;
        NSString *resident_race = self.raceBtn.titleLabel.text;
        NSNumber *average_rating = averageRating;
        NSString *resident_contact = self.contactNoTxFld.text;
        NSString *other_resident_contact = self.otherContactNoTxFld.text;
        NSString *resident_email = self.emailTxFld.text;
        
        BOOL up;
//        if([action isEqualToString:@"feedback"])
//        {
        DDLogVerbose(@"self.postalCode %@",self.postalCode);
        DDLogVerbose(@"self.residentPostalCode %@",self.residentPostalCode);
        
            BOOL insSurveyAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area, postal_code, block_id) values (?,?,?,?,?)",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.postalCode, blockId];
            
            if(!insSurveyAddress)
            {
                *rollback = YES;
                return;
            }
            
            long long lastSurveyAddressId = [db lastInsertRowId];
            
            
            BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area,postal_code, block_id) values (?,?,?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.residentPostalCode, residentBlockId];
            
            if(!insResidentAddress)
            {
                *rollback = YES;
                return;
            }
            
            long long lastResidentAddressId = [db lastInsertRowId];
            
            //get survey address
            FMResultSet *rsSurveyAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithLongLong:lastSurveyAddressId]];
            NSDictionary *surveyAddressDict;
            
            while ([rsSurveyAddress next]) {
                surveyAddressDict = [rsSurveyAddress resultDictionary];
            }
            
            //get resident address
            FMResultSet *rsResidentAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithLongLong:lastResidentAddressId]];
            NSDictionary *residentAddressDict;
            
            while ([rsResidentAddress next]) {
                residentAddressDict = [rsResidentAddress resultDictionary];
            }
            
            
            //update su_survey
            NSNumber *client_survey_address_id = [NSNumber numberWithInt:[[surveyAddressDict valueForKey:@"client_address_id"] intValue]];
            NSNumber *client_resident_address_id = [NSNumber numberWithInt:[[residentAddressDict valueForKey:@"client_address_id"] intValue]];
            
            up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, survey_date = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, average_rating = ?, resident_contact = ?, resident_email = ?,other_contact = ? where client_survey_id = ?",client_survey_address_id,survey_date,resident_name,resident_age_range,resident_gender,resident_race,client_resident_address_id,average_rating,resident_contact,resident_email,other_resident_contact,[NSNumber numberWithLongLong:currentSurveyId]];
//        }
        if ([action isEqualToString:@"done"])
        {
            up = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ? ",[NSNumber numberWithInt:1],[NSNumber numberWithLongLong:currentSurveyId]];
            
            //survey is Done!
            //upload this survey
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Synchronize *sync = [Synchronize sharedManager];
                [sync uploadSurveyFromSelf:NO];
            });
            
            didAddFeedBack = NO;
        }
        
        if(!up)
        {
            *rollback = YES;
            return;
        }
        
        if(goToFeedback)
        {
            //our survey is not yet finish so update the survey status to 0 w/c means upload is not required
            BOOL up = [db executeUpdate:@"update su_survey set status = ?  where client_survey_id = ?",[NSNumber numberWithInt:0],[NSNumber numberWithLongLong:currentSurveyId]];
            
            if(!up)
            {
                *rollback = YES;
                return;
            }
            
            [self performSegueWithIdentifier:@"push_feedback" sender:self];
        }
        
        else
            [self performSegueWithIdentifier:@"push_survey_detail" sender:self];
    }];
    
    
}


@end
