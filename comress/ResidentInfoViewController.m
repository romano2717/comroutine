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

@end

@implementation ResidentInfoViewController

@synthesize surveyId,currentLocation,currentSurveyId,averageRating,placemark,didAcceptTerms,foundPlacesArray,blockId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    [self registerForKeyboardNotifications];
    
    [self generateData];
}


- (void)generateData
{
    self.addressArray = [[NSMutableArray alloc] init];
    
    NSArray *theBlocks = [blocks fetchBlocksWithBlockId:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [theBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *block_noAndPostal = [NSString stringWithFormat:@"%@ %@",[obj valueForKey:@"block_no"],[obj valueForKey:@"postal_code"]] ;
            NSString *street_name = [NSString stringWithFormat:@"%@ - %@",[obj valueForKey:@"street_name"],[obj valueForKey:@"postal_code"]];
            
            [self.addressArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:street_name,@"DisplayText",obj,@"CustomObject",block_noAndPostal,@"DisplaySubText", nil]];
        }];
        
    });
}

#pragma mark MPGTextField Delegate Methods

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
        return;
    
    self.surveyAddressTxtFld.text = [NSString stringWithFormat:@"%@ %@",[[result objectForKey:@"CustomObject"] valueForKey:@"block_no"],[[result objectForKey:@"CustomObject"] valueForKey:@"street_name"]];
    
    blockId = [[result objectForKey:@"CustomObject"] valueForKey:@"block_id"];
    self.postalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    
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
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    else //proceed
    {
        didAcceptTerms = YES;
        self.disclaimerView.hidden = YES;
        
        [self preFillOtherInfo];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"push_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.currentClientSurveyId =  [NSNumber numberWithLongLong:currentSurveyId];
        fvc.postalCode = self.postalCode;
    }
    else if([segue.identifier isEqualToString:@"push_survey_detail"])
    {
        SurveyDetailViewController *surveyDetail = [segue destinationViewController];
        surveyDetail.surveyId = [NSNumber numberWithLongLong:currentSurveyId];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    [UIView animateWithDuration: 0.3 animations: ^{
        self.view.frame = aRect;
    }];
}
     
- (void)keyboardWillHide:(NSNotification*)aNotification {
         NSDictionary* info = [aNotification userInfo];
         CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
         
         CGRect aRect = self.view.frame;
         aRect.size.height += kbSize.height;
         
         [UIView animateWithDuration: 0.3 animations: ^{
             self.view.frame = aRect;
         }];
}

- (void)preFillOtherInfo
{
    DDLogVerbose(@"found placemarks %@",foundPlacesArray);
    
    NSDictionary *topLocation = [foundPlacesArray firstObject];
    
    self.surveyAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.residentAddressTxtFld.text = [topLocation valueForKey:@"street_name"];
    self.postalCode = [topLocation valueForKey:@"postal_code"];
    
    
    NearbyLocationsViewController *postInfoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyLocationsViewController"];
    postInfoVc.delegate = self;
    postInfoVc.foundPlacesArray = foundPlacesArray;
    
    popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:postInfoVc];
    popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.90, CGRectGetHeight(self.view.frame) * 0.80);
    popover.delegate = self;
    [popover presentPopoverFromView:self.navigationController.navigationBar];
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

- (IBAction)action:(id)sender
{
    if(didAcceptTerms == NO)
        return;
    
    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action" message:@"Select what to do next" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Feedback",@"Done", nil];
    
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        
    }
    else
    {
        if(buttonIndex == 0)
        {
            [self saveResidentAdressWithSegueToFeedback:YES];
        }
        else
        {
            [self saveResidentAdressWithSegueToFeedback:NO];
        }
    }
    
}

- (void)saveResidentAdressWithSegueToFeedback:(BOOL)goToFeedback
{

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *survey_date = [NSDate date];
        NSString *resident_name = self.residentNameTxFld.text;
        NSString *resident_age_range = self.ageBtn.titleLabel.text;
        NSString *resident_gender = self.gender;
        NSString *resident_race = self.raceBtn.titleLabel.text;
        NSNumber *average_rating = averageRating;
        NSString *resident_contact = self.contactNoTxFld.text;
        NSString *resident_email = self.emailTxFld.text;
        
        BOOL insSurveyAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area, postal_code) values (?,?,?,?)",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.postalCode];
        
        if(!insSurveyAddress)
        {
            *rollback = YES;
            return;
        }
        
        long long lastSurveyAddressId = [db lastInsertRowId];
        
        
        BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area,postal_code) values (?,?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.postalCode];
        
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
        
        BOOL up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, survey_date = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, average_rating = ?, resident_contact = ?, status = ?, resident_email = ? where client_survey_id = ?",client_survey_address_id,survey_date,resident_name,resident_age_range,resident_gender,resident_race,client_resident_address_id,average_rating,resident_contact,[NSNumber numberWithInt:1],resident_email,[NSNumber numberWithLongLong:currentSurveyId]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Synchronize *sync = [Synchronize sharedManager];
            [sync uploadSurveyFromSelf:NO];
        });
        
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
