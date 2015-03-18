//
//  RoutineListViewController.m
//  comress
//
//  Created by Diffy Romano on 11/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineListViewController.h"


@interface RoutineListViewController ()



@end

@implementation RoutineListViewController

@synthesize scheduleArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    schedule = [[Schedule alloc] init];
    
    //for qr code scanning
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(waitingForLocation) name:@"waitingForLocation" object:self];
    
    
    //when unlock/lock/report button is tapped
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tappedUnlockButton:) name:@"tappedUnlockButton" object:nil];
}

- (void)tappedUnlockButton:(NSNotification *)notif
{
    DDLogVerbose(@"sched %@",[[notif userInfo] valueForKey:@"scheduleId"]);
}


- (void)waitingForLocation
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Capturing location...";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanningQrCodeComplete:) name:@"scanningQrCodeComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locatingComplete:) name:@"locatingComplete" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = YES;
    self.hidesBottomBarWhenPushed = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self fetchSchedule];
}

- (void)scanningQrCodeComplete:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    [self passQrCodeAndLocation:dict];
}

- (void)locatingComplete:(NSNotification *)notif
{
    NSDictionary *dict = [notif userInfo];
    
    [self passQrCodeAndLocation:dict];
}

- (void)passQrCodeAndLocation:(NSDictionary *)dict
{
    CLLocation *location = (CLLocation *)[dict objectForKey:@"location"];
    NSString *scanValue = [dict valueForKey:@"scanValue"];
    
    if(location != nil && scanValue != nil && [location isEqual:[NSNull null]] == NO && [scanValue isEqual:[NSNull null]] == NO)
    {
        DDLogVerbose(@"pass qr code: %@",scanValue);
        DDLogVerbose(@"pass location: %@",location);
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Capturing location...";
        
        [myDatabase alertMessageWithMessage:[NSString stringWithFormat:@"scan: %@, loc: %@",scanValue,location]];
    }
    else
    {
        if(location == nil || [location isEqual:[NSNull null]] == YES)
        {
            [myDatabase alertMessageWithMessage:@"Unable to find your location. Please try again."];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)segmentControlChange:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *)sender;
    self.segment = segment;
    
    [self fetchSchedule];
}

- (void)fetchSchedule
{
    if(self.segment.selectedSegmentIndex == 0)
        scheduleArray = [schedule fetchScheduleForMe];
    else
        scheduleArray = [schedule fetchScheduleForOthersAtPage:[NSNumber numberWithInt:0]];
    
    [self.routineTableView reloadData];
}

#pragma mark - uitableview delegate and datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return scheduleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RoutineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *dict;
    
    dict = (NSDictionary *)[scheduleArray objectAtIndex:indexPath.row];
    
    [cell initCellWithResultSet:dict];
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if(decelerate)
    {
        if(self.routineTableView.contentOffset.y<0){
            //it means table view is pulled down like refresh
            return;
        }
        else if(self.routineTableView.contentOffset.y >= (self.routineTableView.contentSize.height - self.routineTableView.bounds.size.height)) {
            NSLog(@"scrollViewDidEndDragging bottom!");
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(self.routineTableView.contentOffset.y<0){
        //it means table view is pulled down like refresh
        return;
    }
    else if(self.routineTableView.contentOffset.y >= (self.routineTableView.contentSize.height - self.routineTableView.bounds.size.height)) {
        NSLog(@"scrollViewDidEndDecelerating bottom!");
    }
}



@end
