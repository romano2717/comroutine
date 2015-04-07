//
//  SurveyDetailViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyDetailViewController.h"

@interface SurveyDetailViewController ()

@end

@implementation SurveyDetailViewController

@synthesize surveyId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    survey = [[Survey alloc] init];
    
    
    //get average rating of this survey
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select average_rating from su_survey where client_survey_id = ?",surveyId];
        
        int averageRating = 0;
        while ([rs next]) {
            averageRating = [rs intForColumn:@"average_rating"];
        }
        
        if(averageRating >= 5)
            self.averageRatingImageView.image = [UIImage imageNamed:@"fivestars@2x"];
        if(averageRating <= 4)
            self.averageRatingImageView.image = [UIImage imageNamed:@"fourstars@2x"];
        if(averageRating <= 3)
            self.averageRatingImageView.image = [UIImage imageNamed:@"threestars@2x"];
        if(averageRating <= 2)
            self.averageRatingImageView.image = [UIImage imageNamed:@"twostars@2x"];
        if(averageRating <= 1)
            self.averageRatingImageView.image = [UIImage imageNamed:@"onestar@2x"];
        
    }];
    
    [self fetchSurveyDetail];
}

- (IBAction)popResidentInfForThisSurvey:(id)sender
{
    NSDictionary *residentInfo = [survey surveDetailForId:surveyId];
    
    ResidentPopInfoViewController *postInfoVc = [self.storyboard instantiateViewControllerWithIdentifier:@"ResidentPopInfoViewController"];
    postInfoVc.residentInfo = residentInfo;
    
    popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:postInfoVc];
    popover.arrowDirection = FPPopoverArrowDirectionRight;
    popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.90, CGRectGetHeight(self.view.frame) * 0.80);
    
    [popover presentPopoverFromView:sender];
}

-(void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound)
    {
        [self backButtonPressed];
        [self.navigationController popViewControllerAnimated:NO];
        
    }
    [super viewWillDisappear:animated];
}

-(void)backButtonPressed
{ 
    if(self.pushFromResidentInfo)
    {
        //pop to tab
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    if(self.pushFromIssue)
    {
        //pop to tab
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleSegment:(id)sender
{
    [self fetchSurveyDetail];
}

- (void)fetchSurveyDetail
{
    self.dataArray = [survey surveyDetailForSegment:self.segment.selectedSegmentIndex forSurveyId:surveyId];
    
    [self.surveyDetailTableView reloadData];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_add_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.currentClientSurveyId = surveyId;
        fvc.pushFromSurveyDetail = YES;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.segment.selectedSegmentIndex == 0)
    {
        static NSString *questionCell = @"quetionsCell";
        QuestionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:questionCell forIndexPath:indexPath];
        
        NSDictionary *dict = [self.dataArray objectAtIndex:indexPath.row];
        
        [cell initCellWithResultSet:dict];
        return cell;
    }
    
    else
    {
        static NSString *feedBackCell = @"feedbackCell";
        FeedbackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:feedBackCell forIndexPath:indexPath];
        NSDictionary *dict = [self.dataArray objectAtIndex:indexPath.row];
        
        [cell initCellWithResultSet:dict];
        
        return cell;
    }
}

- (IBAction)addFeedBack:(id)sender
{
    [self performSegueWithIdentifier:@"push_add_feedback" sender:self];
}


- (IBAction)startChat:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    int tag = (int)btn.tag;
    
    
}


@end
