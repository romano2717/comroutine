//
//  ResidentPopInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 7/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ResidentPopInfoViewController.h"
#import "Synchronize.h"

@interface ResidentPopInfoViewController ()

@end

@implementation ResidentPopInfoViewController

@synthesize surveyId,blockId,clientSurveyId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    mySurvey = [[Survey alloc] init];
    myDatabase = [Database sharedMyDbManager];
    blocks = [[Blocks alloc] init];
    
    self.ageRangeArray = [NSArray arrayWithObjects:@"Above 70",@"50 to 70",@"30 to 50",@"18 to 30",@"below 18", nil];
    self.raceArray = [NSArray arrayWithObjects:@"Chinese",@"Malay",@"Indian",@"Other", nil];
    
    NSDictionary *dict = [mySurvey surveDetailForId:surveyId forClientSurveyId:clientSurveyId];
    
    NSDictionary *surveyDict = [dict objectForKey:@"survey"];
    NSDictionary *residentAddressDict = [dict objectForKey:@"residentAddress"];
    NSDictionary *surveyAddressDict = [dict objectForKey:@"surveyAddress"];
    
    self.client_resident_address_id = [[surveyDict valueForKey:@"client_resident_address_id"] longLongValue];
    self.client_survey_address_id = [[surveyDict valueForKey:@"client_survey_address_id"] longLongValue];
    self.surveyAddressPostalCode = [surveyAddressDict valueForKey:@"postal_code"];

    NSString *surveyAddress;
    NSString *area;
    NSString *residentName;
    NSString *ageRange;
    NSString *genderSel;
    NSString *raceSel;
    NSString *residentAddress;
    NSString *unitNo;
    NSString *contact;
    NSString *otherContact;
    NSString *email;
    
    if([surveyAddressDict valueForKey:@"address"] != [NSNull null] && [surveyAddressDict valueForKey:@"address"] != nil)
        surveyAddress = [surveyAddressDict valueForKey:@"address"];
    
    if([surveyAddressDict valueForKey:@"specify_area"] != [NSNull null] && [surveyAddressDict valueForKey:@"specify_area"] != nil)
        area = [surveyAddressDict valueForKey:@"specify_area"];
    
    if([surveyDict valueForKey:@"resident_name"] != [NSNull null] && [surveyDict valueForKey:@"resident_name"] != nil)
        residentName = [surveyDict valueForKey:@"resident_name"];
    
    if([surveyDict valueForKey:@"resident_age_range"] != [NSNull null] && [surveyDict valueForKey:@"resident_age_range"] != nil)
        ageRange = [surveyDict valueForKey:@"resident_age_range"];
    
    if([surveyDict valueForKey:@"resident_gender"] != [NSNull null] && [surveyDict valueForKey:@"resident_gender"] != nil)
        genderSel = [surveyDict valueForKey:@"resident_gender"];
    
    if([surveyDict valueForKey:@"resident_race"] != [NSNull null] && [surveyDict valueForKey:@"resident_race"] != nil)
        raceSel = [surveyDict valueForKey:@"resident_race"];
    
    if([residentAddressDict valueForKey:@"address"] != [NSNull null] && [residentAddressDict valueForKey:@"address"] != nil)
        residentAddress = [residentAddressDict valueForKey:@"address"];
    
    if([residentAddressDict valueForKey:@"unit_no"] != [NSNull null] && [residentAddressDict valueForKey:@"unit_no"] != nil)
        unitNo = [residentAddressDict valueForKey:@"unit_no"];
    
    if([surveyDict valueForKey:@"resident_contact"] != [NSNull null] && [surveyDict valueForKey:@"resident_contact"] != nil)
        contact = [surveyDict valueForKey:@"resident_contact"];
    
    if([surveyDict valueForKey:@"other_contact"] != [NSNull null] && [surveyDict valueForKey:@"other_contact"] != nil)
        otherContact = [surveyDict valueForKey:@"other_contact"];
    
    if([surveyDict valueForKey:@"resident_email"] != [NSNull null] && [surveyDict valueForKey:@"resident_email"] != nil)
        email = [surveyDict valueForKey:@"resident_email"];
    

    self.surveyAddressTxtFld.text = surveyAddress;
    self.areaTxtFld.text = area;
    self.residentNameTxtFld.text = residentName;
    
    NSString *age = ageRange;
    [self.ageBtn setTitle:age forState:UIControlStateNormal];
    if([self.ageRangeArray containsObject:age])
        self.selectedAgeRange = age;
    
    NSString *gender = genderSel;
    UIButton *genderButtonToggleM = (UIButton *)[self.view viewWithTag:1];
    UIButton *genderButtonToggleF = (UIButton *)[self.view viewWithTag:2];

    if([gender isEqualToString:@"M"])
    {
        [genderButtonToggleM setSelected:YES];
        self.selectedGender = @"M";
    }
    else
    {
        [genderButtonToggleF setSelected:YES];
        self.selectedGender = @"F";
    }
    
    NSString *race = raceSel;
    [self.raceBtn setTitle:race forState:UIControlStateNormal];
    self.selectedRace = race;
    
    self.residentAddressTxtFld.text = residentAddress;
    self.unitNoTxtFld.text = unitNo;
    self.contactTxtFld.text = contact;
    self.otherContactTxtFld.text = otherContact;
    self.emailTxFld.text = email;
    
    DDLogVerbose(@"%@",dict);
    
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
    self.surveyAddressPostalCode = [[result objectForKey:@"CustomObject"] valueForKey:@"postal_code"];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender
{
    //change status of this survey as 1 to upload this survey
//    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
//        BOOL requireSync = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ?",[NSNumber numberWithInt:1], surveyId];
//        if (!requireSync) {
//            *rollback = YES;
//            return;
//        }
//    }];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *resident_name = self.residentNameTxtFld.text;
        NSString *resident_age_range = self.ageBtn.titleLabel.text;
        NSString *resident_gender = self.selectedGender;
        NSString *resident_race = self.selectedRace;

        NSString *resident_contact = self.contactTxtFld.text;
        NSString *resident_email = self.emailTxFld.text;
        NSString *other_contact = self.otherContactTxtFld.text;
        
        if(self.client_survey_address_id == 0)
        {
            BOOL insSurveyAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area, postal_code) values (?,?,?,?)",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.surveyAddressPostalCode];
            
            if(!insSurveyAddress)
            {
                *rollback = YES;
                return;
            }
            self.client_survey_address_id = [db lastInsertRowId];
        }
        else
        {
            BOOL insSurveyAddress = [db executeUpdate:@"update su_address set address = ?, unit_no = ?, specify_area = ?, postal_code = ? where client_address_id = ?",self.surveyAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, self.surveyAddressPostalCode, [NSNumber numberWithLongLong:self.client_survey_address_id]];
            
            if(!insSurveyAddress)
            {
                *rollback = YES;
                return;
            }
        }
        
        
        
        
        if(self.client_resident_address_id == 0)
        {
            BOOL insResidentAddress = [db executeUpdate:@"insert into su_address (address, unit_no, specify_area) values (?,?,?)",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text];
            
            if(!insResidentAddress)
            {
                *rollback = YES;
                return;
            }
            self.client_survey_address_id = [db lastInsertRowId];
        }
        else
        {
            BOOL insResidentAddress = [db executeUpdate:@"update su_address set address = ?, unit_no = ?, specify_area = ? where client_address_id = ?",self.residentAddressTxtFld.text, self.unitNoTxtFld.text, self.areaTxtFld.text, [NSNumber numberWithLongLong:self.client_resident_address_id]];
            
            if(!insResidentAddress)
            {
                *rollback = YES;
                return;
            }
        }
        
        NSNumber *theSurveyId = [NSNumber numberWithInt:0];
        if(clientSurveyId > 0)
            theSurveyId = clientSurveyId;
        else
            theSurveyId = surveyId;
        
        BOOL up = [db executeUpdate:@"update su_survey set client_survey_address_id = ?, resident_name = ?, resident_age_range = ?, resident_gender = ?, resident_race = ?, client_resident_address_id = ?, resident_contact = ?, status = ?, resident_email = ?, other_contact = ? where client_survey_id = ?",[NSNumber numberWithLongLong:self.client_survey_address_id],resident_name,resident_age_range,resident_gender,resident_race,[NSNumber numberWithLongLong:self.client_resident_address_id],resident_contact,[NSNumber numberWithInt:1],resident_email,other_contact,theSurveyId];
        
        if(!up)
        {
            *rollback = YES;
            return;
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber *theSurveyId = [NSNumber numberWithInt:0];
        if(clientSurveyId > 0)
            theSurveyId = clientSurveyId;
        else
            theSurveyId = surveyId;
        
        Synchronize *sync = [Synchronize sharedManager];
        [sync uploadResidentInfoEditForSurveyId:theSurveyId];
    });
}

@end
