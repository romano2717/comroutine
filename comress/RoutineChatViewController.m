//
//  RoutineChatViewController.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "RoutineChatViewController.h"

@interface RoutineChatViewController ()

@end

@implementation RoutineChatViewController

@synthesize blockId,blockNo;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //save this routine as a post with type = 2
    post = [[Post alloc] init];
    schedule = [[Schedule alloc] init];
    myDatabase = [Database sharedMyDbManager];
    
    NSDictionary *schedDict = [schedule scheduleForBlockId:blockId];
    NSDate *post_date = [NSDate date];
    NSNumber *post_type = [NSNumber numberWithInt:2];
    NSNumber *severityNumber = [NSNumber numberWithInt:2];
    NSString *location = [NSString stringWithFormat:@"%@ %@",[schedDict valueForKey:@"block_no"],[schedDict valueForKey:@"street_name"]];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[schedDict valueForKey:@"w_area"],@"post_topic",[myDatabase.userDictionary valueForKey:@"user_id"],@"post_by",post_date,@"post_date",post_type,@"post_type",severityNumber,@"severity",@"0",@"status",location,@"address",@"nil",@"level",[schedDict valueForKey:@"postal_code"],@"postal_code",blockId,@"block_id",post_date,@"updated_on",[NSNumber numberWithBool:YES],@"seen", nil];
    
    long long postId = [post savePostWithDictionary:dict forBlockId:blockId];
    
    if(postId > 0)
    {
        DDLogVerbose(@"post saved for routine");
    }
    else
        DDLogVerbose(@"post already exist");
    
    
    //fetch comments for this post
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NavigationBarTitleWithSubtitleView *navigationBarTitleView = [[NavigationBarTitleWithSubtitleView alloc] init];
    [self.navigationItem setTitleView: navigationBarTitleView];
    [navigationBarTitleView setTitleText:blockNo];
    [navigationBarTitleView setDetailText:@"Tap here for info."];
    
    //add tap gestuer to the navbar for the pop-over post info
    UITapGestureRecognizer *tapNavBar = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popSkedInformation)];
    tapNavBar.numberOfTapsRequired = 1;
    
    [navigationBarTitleView addGestureRecognizer:tapNavBar];
}

- (void)popSkedInformation
{
    CheckListViewController *cvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CheckListViewController"];
    cvc.blockId = blockId;
    
    popover = [[FPPopoverKeyboardResponsiveController alloc] initWithViewController:cvc];
    popover.arrowDirection = FPPopoverArrowDirectionUp;
    popover.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame) * 0.99, CGRectGetHeight(self.view.frame) * 0.99);
    
    [popover presentPopoverFromView:self.navigationController.navigationBar];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)action:(id)sender
{
    DDLogVerbose(@"action");
}

@end
