//
//  FeedBackInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 15/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "FeedBackInfoViewController.h"

@interface FeedBackInfoViewController ()

@end

@implementation FeedBackInfoViewController

@synthesize feedbackDict,feedbackId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    feedback = [[Feedback alloc] init];
    
    feedbackDict = [feedback fullFeedbackDetailsForFeedbackClientId:feedbackId];
    
//    {
//        address =     {
//            address = "BLK30 Holland Close";
//            "address_id" = 138;
//            "client_address_id" = 235;
//            "postal_code" = 270030;
//            "specify_area" = lobby;
//            "unit_no" = "#09-762";
//        };
//        feedBackIssues =     (
//                              {
//                                  feedbackIssues =             {
//                                      "auto_assignme" = 1;
//                                      "client_feedback_id" = 173;
//                                      "client_feedback_issue_id" = 87;
//                                      "client_post_id" = 608;
//                                      "feedback_id" = 0;
//                                      "feedback_issue_id" = 58;
//                                      "issue_des" = test;
//                                      "post_id" = 559;
//                                      status = 0;
//                                  };
//                                  post =             {
//                                      address = "BLK30 Holland Close";
//                                      "block_id" = 978;
//                                      "client_post_id" = 608;
//                                      "contract_type" = 1;
//                                      isUpdated = 1;
//                                      level = "";
//                                      "post_by" = chandra;
//                                      "post_date" = "1429071091.326331";
//                                      "post_id" = 559;
//                                      "post_topic" = test;
//                                      "post_type" = 1;
//                                      "postal_code" = 270030;
//                                      seen = 1;
//                                      severity = 2;
//                                      status = 0;
//                                      statusWasUpdated = 0;
//                                      "updated_on" = "1429071091.326331";
//                                  };
//                              }
//                              );
//        feedback =     {
//            "address_id" = 0;
//            "client_address_id" = 235;
//            "client_feedback_id" = 173;
//            "client_survey_id" = 470;
//            description = test;
//            "feedback_id" = 120;
//            "survey_id" = 0;
//        };
//    }

    
    NSString *locationStr;
    NSString *feedbackStr;
    NSString *statusStr = @"Pending";
    __block NSString *contractTypeStr;
    
    NSMutableArray *feedBackIssuesArr = [[NSMutableArray alloc] init];
    NSMutableArray *relateContractTypes = [[NSMutableArray alloc] init];
    
    int feedbackStatus = -1;
    int postStatus = -1;
    int contractTypeInt = -1;

    NSDictionary *feedbackData = [feedbackDict objectForKey:@"feedback"];
    NSDictionary *addressData = [feedbackDict objectForKey:@"address"];
    NSArray *feedbackIssuesData = [feedbackDict objectForKey:@"feedBackIssues"];
    
    
    if(addressData != nil)
    {
        if([addressData valueForKey:@"address"] != [NSNull null] && [addressData valueForKey:@"address"] != nil)
            locationStr = [addressData valueForKey:@"address"];
    }
    
    
    if(feedbackData != nil)
    {
        if([feedbackData valueForKey:@"description"] != [NSNull null] && [feedbackData valueForKey:@"description"] != nil)
            feedbackStr = [feedbackData valueForKey:@"description"];
    }
    
    
    //feedback issues
    for (int i = 0; i < feedbackIssuesData.count; i++) {
        NSDictionary *topDict = [feedbackIssuesData objectAtIndex:i];
        
        NSDictionary *feedbackIssues = [topDict objectForKey:@"feedbackIssues"];
        NSDictionary *post = [topDict objectForKey:@"post"];
        
        feedbackStatus = [[feedbackIssues valueForKey:@"status"] intValue];
        postStatus = [[post valueForKey:@"status"] intValue];
        
        if([feedbackIssues valueForKey:@"client_post_id"] != [NSNull null] && [feedbackIssues valueForKey:@"client_post_id"] != nil && [[feedbackIssues valueForKey:@"client_post_id"] intValue] > 0)
        {
            feedbackStatus = [[feedbackIssues valueForKey:@"status"] intValue];
        }
        if([post valueForKey:@"status"] != [NSNull null] && [post valueForKey:@"status"] != nil)
        {
            postStatus = [[post valueForKey:@"status"] intValue];
            contractTypeInt = [[post valueForKey:@"contract_type"] intValue];
        }
    }
    
    if(feedbackStatus > 0)
    {
        switch (feedbackStatus) {
            case 1:
                statusStr = @"Completed";
                break;
            case 4:
                statusStr = @"Closed";
                break;
                
            default:
                statusStr = @"Pending";
                break;
        }
    }
    
    if(postStatus > 0)
    {
        switch (postStatus) {
            case 1:
                statusStr = @"Start";
                break;
                
            case 2:
                statusStr = @"Stop";
                break;
                
            case 3:
                statusStr = @"Completed";
                break;
                
            case 4:
                statusStr = @"Close";
                break;
                
            default:
                statusStr = @"Pending";
                break;
        }
    }
    
    //get contract type
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsContract = [db executeQuery:@"select * from contract_type where id = ?",[NSNumber numberWithInt:contractTypeInt]];
        
        while ([rsContract next]) {
            contractTypeStr = [rsContract stringForColumn:@"contract"];
        }
    }];
    
    
    self.locationLabel.text = locationStr;
    self.feedBackLabel.text = feedbackStr;
    self.statusLabel.text = statusStr;
    self.relatedContract.text = contractTypeStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
