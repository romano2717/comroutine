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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(waitingForLocation) name:@"waitingForLocation" object:self];
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

@end
