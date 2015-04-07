//
//  SurveyListingViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyListingViewController.h"

@interface SurveyListingViewController ()

@end

@implementation SurveyListingViewController

@synthesize surveyArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    survey = [[Survey alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.hidesBottomBarWhenPushed = NO;
    
    [self fetchSurvey];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.surveyTableView reloadData];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"push_survey_detail_from_list"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        int surveyId = [[[[surveyArray objectAtIndex:indexPath.row] objectForKey:@"survey"] valueForKey:@"client_survey_id"] intValue];
        
        SurveyDetailViewController *sdvc = [segue destinationViewController];
        sdvc.surveyId = [NSNumber numberWithInt:surveyId];
    }
}


- (void)fetchSurvey
{
    surveyArray = [survey fetchSurvey];
    
    [self.surveyTableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return surveyArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    SurveyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
 
    NSDictionary *dict = [surveyArray objectAtIndex:indexPath.row];
    
    [cell initCellWithResultSet:dict];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"push_survey_detail_from_list" sender:indexPath];
}


@end
