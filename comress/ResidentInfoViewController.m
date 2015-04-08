//
//  ResidentInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentInfoViewController.h"
#import "Synchronize.h"

@interface ResidentInfoViewController ()

@end

@implementation ResidentInfoViewController

@synthesize surveyId,currentLocation,currentSurveyId,averageRating,placemark;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    [self registerForKeyboardNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    [self preFillOtherInfo];
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
    self.surveyAddressTxtFld.text = placemark.name;
    self.residentAddressTxtFld.text = placemark.name;
    self.postalCode = placemark.postalCode;
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

    //alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Action" message:@"Select what to do next" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Feedback",@"Done", nil];
    
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
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
        
        BOOL insSurveyAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area) values (?,?,?)",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text];
        
        if(!insSurveyAddress)
        {
            *rollback = YES;
            return;
        }
        
        long long lastSurveyAddressId = [db lastInsertRowId];
        
        
        BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area) values (?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text];
        
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
        
        BOOL up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, survey_date = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, average_rating = ?, resident_contact = ?, status = ?  where client_survey_id = ?",client_survey_address_id,survey_date,resident_name,resident_age_range,resident_gender,resident_race,client_resident_address_id,average_rating,resident_contact,[NSNumber numberWithInt:1],[NSNumber numberWithLongLong:currentSurveyId]];
        
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
