//
//  FeedBackViewController.m
//  comress
//
//  Created by Diffy Romano on 4/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedBackViewController.h"

@interface FeedBackViewController ()

@end

@implementation FeedBackViewController

@synthesize currentClientSurveyId,pushFromSurvey,pushFromSurveyDetail,postalCode,pushFromSurveyAndModalFromFeedback;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    //default selection
    self.selectedFeedBackLoc = @"survey";
    UIButton *btnSurveyDef = (UIButton *)[self.view viewWithTag:11];
    [btnSurveyDef setSelected:YES];
    
    //get the client_survey_address_id and client_resident_address_id from survey using self.currentClientSurveyId
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsAdd = [db executeQuery:@"select * from su_survey where client_survey_id = ?",self.currentClientSurveyId];
       
        NSNumber *surveyAddressId;
        NSNumber *residentAddressId;
        NSNumber *zero = [NSNumber numberWithInt:0];
        
        while ([rsAdd next]) {
            surveyAddressId = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_survey_address_id"]];
            residentAddressId = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_resident_address_id"]];
        }
        
        if (surveyAddressId == zero && residentAddressId == zero) {
            self.selectedFeedBackLoc = @"others";
            
            //check the 'Others' radio button
            UIButton *btnSurvey = (UIButton *)[self.view viewWithTag:11];
            UIButton *btnResident = (UIButton *)[self.view viewWithTag:12];
            UIButton *btnOthers = (UIButton *)[self.view viewWithTag:13];
            
            [btnSurvey setSelected:NO]; //reset to radio off. default is radio on
            [btnResident setSelected:NO];
            [btnOthers setSelected:YES];
            
            //disable survey and resident btn
            btnSurvey.enabled = NO;
            btnResident.enabled = NO;
        }
    }];
    
    
    //add border to the textview
    [[self.feedBackTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.feedBackTextView layer] setBorderWidth:1];
    [[self.feedBackTextView layer] setCornerRadius:15];
    
    self.selectedFeeBackTypeArr = [[NSMutableArray alloc] init];
    self.selectedFeeBackTypeStringArr = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(push_survey_detail:) name:@"push_survey_detail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(go_back_to_survey) name:@"go_back_to_survey" object:nil];
    
}

- (void)go_back_to_survey
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)push_survey_detail:(NSNotification *)notif
{
    NSNumber *surveyId = [[notif userInfo] valueForKey:@"surveyId"];
    
    [self performSegueWithIdentifier:@"push_survey_detail" sender:surveyId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"modal_create_issue"])
    {
        Survey *survey = [[Survey alloc] init];
        NSDictionary *dict = [survey surveyForId:currentClientSurveyId forAddressType:self.selectedFeedBackLoc];
        
        NSMutableString *contractString = [[NSMutableString alloc] init];
        
        for (int i = 0; i < self.selectedFeeBackTypeStringArr.count; i++) {
            NSString *str = [self.selectedFeeBackTypeStringArr objectAtIndex:i];
            [contractString appendString:[NSString stringWithFormat:@"%@, ",str]];
        }
        
        CreateIssueViewController *cvc = [segue destinationViewController];
        cvc.surveyId = currentClientSurveyId;
        cvc.feedBackId = sender;
        cvc.surveyDetail = dict;
        cvc.postalCode = postalCode;
        cvc.selectedContractTypesArr = self.selectedFeeBackTypeArr;
        cvc.selectedContractTypesString = contractString;
        if(pushFromSurveyAndModalFromFeedback)
            cvc.pushFromSurveyAndModalFromFeedback = YES;
    }
    
    if([segue.identifier isEqualToString:@"push_survey_detail"])
    {
        self.tabBarController.tabBar.hidden = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.navigationController.navigationBar.hidden = NO;
        
        SurveyDetailViewController *sdvc = [segue destinationViewController];
        NSNumber *surveyId = sender;
        sdvc.surveyId = surveyId;
        sdvc.pushFromIssue = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //only if push from survey since survey is in landscape mode
    if(pushFromSurvey)
    {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    if(pushFromSurveyDetail == NO)
        self.navigationItem.hidesBackButton = YES;
    
    if(pushFromSurveyDetail == YES)
    {
        self.segment.hidden = YES;
        self.title = @"New Feedback";
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

-(IBAction)toggleSegment:(id)sender
{
    if(self.segment.selectedSegmentIndex == 0)
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (IBAction)toggleFeedBackLocation:(id)sender
{
    UIButton *sur = (UIButton *)[self.view viewWithTag:11];
    UIButton *res = (UIButton *)[self.view viewWithTag:12];
    UIButton *oth = (UIButton *)[self.view viewWithTag:13];

    UIButton *btn = (UIButton *)sender;
    
    int tag = (int)btn.tag;
    
    [btn setSelected:!btn.selected];
    
    if(tag == 11)
    {
        [sur setSelected:YES];
        [res setSelected:NO];
        [oth setSelected:NO];
        
        self.selectedFeedBackLoc = @"survey";
    }
    else if (tag == 12)
    {
        [res setSelected:YES];
        [sur setSelected:NO];
        [oth setSelected:NO];
        
        self.selectedFeedBackLoc = @"resident";
    }
    else if (tag == 13)
    {
        [oth setSelected:YES];
        [res setSelected:NO];
        [sur setSelected:NO];
        
        self.selectedFeedBackLoc = @"others";
    }
}

- (IBAction)selectFeedbackType:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    if([self.selectedFeeBackTypeArr containsObject:tag] == NO)
    {
        [self.selectedFeeBackTypeArr addObject:tag];
    }
    else
    {
        [self.selectedFeeBackTypeArr removeObject:tag];
    }
    
    //add contract type strings
    NSString *contractypeString;
    int intTag = [tag intValue];
    switch (intTag) {
        case 1:
            contractypeString = @"Conservancy";
            break;
            
        case 2:
            contractypeString = @"Horticulture";
            break;
            
        case 4:
            contractypeString = @"Pump";
            break;
            
        case 5:
            contractypeString = @"Mosquito";
            break;
            
        case 19:
            contractypeString = @"General";
            break;
            
        case 6:
            contractypeString = @"LTA";
            break;
            
        case 7:
            contractypeString = @"HDB";
            break;
            
        case 8:
            contractypeString = @"Others";
            break;
            
        default:
            contractypeString = @"General";
            break;
    }
    
    if([self.selectedFeeBackTypeStringArr containsObject:contractypeString] == NO)
    {
        [self.selectedFeeBackTypeStringArr addObject:contractypeString];
    }
    else
    {
        [self.selectedFeeBackTypeStringArr removeObject:contractypeString];
    }
    
    [btn setSelected:!btn.selected];
}


- (IBAction)addFeedBack:(id)sender
{
    
//    NSArray *comressTypes = @[[NSNumber numberWithInt:2],[NSNumber numberWithInt:3],[NSNumber numberWithInt:4],[NSNumber numberWithInt:5]];
//    
//    int foundComressTypes = 0;
//    
//    for (int i = 0; i < self.selectedFeeBackTypeArr.count; i++) {
//        NSNumber *selected = [self.selectedFeeBackTypeArr objectAtIndex:i];
//        
//        if([comressTypes containsObject:selected])
//            foundComressTypes ++;
//        
//    }
    
    NSString *message = [NSString stringWithFormat:@"Are you sure you want to create %lu issues?",(unsigned long)self.selectedFeeBackTypeStringArr.count];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];

    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1) //YES!
    {
        //save feedback!
        __block NSNumber *feedBackId;
        __block BOOL feedbackSaved = NO;
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            //get the client_survey_address_id and client_resident_address_id from survey using self.currentClientSurveyId
            
            FMResultSet *rsAdd = [db executeQuery:@"select * from su_survey where client_survey_id = ?",self.currentClientSurveyId];
            NSNumber *client_survey_address_id;
            NSNumber *client_resident_address_id;
            
            while ([rsAdd next]) {
                client_survey_address_id = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_survey_address_id"]];
                client_resident_address_id = [NSNumber numberWithInt:[rsAdd intForColumn:@"client_resident_address_id"]];
            }
            
            
            NSNumber *client_address_id;
            
            if([self.selectedFeedBackLoc isEqualToString:@"survey"])
            {
                client_address_id = client_survey_address_id;
            }
            else if ([self.selectedFeedBackLoc isEqualToString:@"resident"])
            {
                client_address_id = client_resident_address_id;
            }
            else
            {
                //get address info of this client_address_id
                FMResultSet *rsAddInfo = [db executeQuery:@"select * from su_address where client_address_id = ?",client_address_id];
                
                NSDictionary *dictAddInfo;
                
                while ([rsAddInfo next]) {
                    dictAddInfo = [rsAddInfo resultDictionary];
                }
                
                
                //save the 'Others' address
                BOOL ins = [db executeUpdate:@"insert into su_address(address,unit_no,specify_area) values (?,?,?)",self.othersAddTxtField.text,[dictAddInfo valueForKey:@"unit_no"],[dictAddInfo valueForKey:@"specify_area"]];
                
                if(!ins)
                {
                    *rollback = YES;
                    return;
                }
                
                client_address_id = [NSNumber numberWithLongLong:[db lastInsertRowId]];
            }
            
            //finally, save the feedback
            
            BOOL insFeedBack = [db executeUpdate:@"insert into su_feedback (client_survey_id,description,client_address_id) values (?,?,?)",currentClientSurveyId,self.feedBackTextView.text,client_address_id];
            
            if(!insFeedBack)
            {
                *rollback = YES;
                return;
            }
            else
            {
                feedbackSaved = YES;
                
                feedBackId = [NSNumber numberWithLongLong:[db lastInsertRowId]];
            }
        }];
        
        
        if(feedbackSaved)
        {
            //segue to issues and pass selected contract types;
            [self performSegueWithIdentifier:@"modal_create_issue" sender:feedBackId];
        }
    }
}



@end
