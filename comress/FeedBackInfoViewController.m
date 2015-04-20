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

@synthesize feedbackId,feedbackDict,clientfeedbackId,dataArray,issueStatus,cmrStatus;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    contract_type = [[Contract_type alloc] init];
    
    feedbackDict = [[NSMutableDictionary alloc] init];
    
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_feedback where client_feedback_id = ? or (feedback_id = ? and feedback_id != ?)",clientfeedbackId,feedbackId,zero];
        
        while ([rs next]) {
            [feedbackDict setObject:[rs resultDictionary] forKey:@"feedback"];
            
            NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_address_id"]];
            NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"address_id"]];
            
            //get address
            FMResultSet *rsGetAdd = [db executeQuery:@"select * from su_address where client_address_id = ? or (address_id = ? and address_id != ?)",clientAddressId,addressId,zero];
            
            while ([rsGetAdd next]) {
                [feedbackDict setObject:[rsGetAdd resultDictionary] forKey:@"address"];
            }
            
            //get feedback_issue
            FMResultSet *rsFi = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ? or (feedback_id = ? and feedback_id != ?)",clientfeedbackId,feedbackDict, zero];
            
            NSMutableArray *fIArray = [[NSMutableArray alloc] init];
            NSMutableArray *postArray = [[NSMutableArray alloc] init];
            
            while ([rsFi next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rsFi intForColumn:@"post_id"]];
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsFi intForColumn:@"client_post_id"]];
                
                if([postId intValue] == 0 || [clientPostId intValue] == 0)
                    [fIArray addObject:[rsFi resultDictionary]];
                
                //get post
                FMResultSet *rsGetPost = [db executeQuery:@"select * from post where client_post_id = ? or (post_id = ? and post_id != ?)",clientPostId,postId,zero];
                
                while ([rsGetPost next]) {
                    [postArray addObject:[rsGetPost resultDictionary]];
                }
            }
            
            [feedbackDict setObject:postArray forKey:@"post"];
            [feedbackDict setObject:fIArray forKey:@"feedback_issue"];
        }
    }];
    issueStatus = [NSArray arrayWithObjects:@"Pending",@"Start",@"Stop",@"Completed",@"Close", nil];
    cmrStatus = [NSArray arrayWithObjects:@"Pending",@"Complete",@"Close", nil];
    
    NSDictionary *feedback = [feedbackDict objectForKey:@"feedback"];
    NSDictionary *address = [feedbackDict objectForKey:@"address"];
    NSArray *feedback_issue_array = [feedbackDict objectForKey:@"feedback_issue"];
    NSArray *post_array = [feedbackDict objectForKey:@"post"];
    
    self.locationLabel.text = [address valueForKey:@"address"];
    self.feedBackLabel.text = [feedback valueForKey:@"description"];
    
    NSString *titleStr = @"Feedback";
    
    if([address valueForKey:@"address"] != [NSNull null] && [address valueForKey:@"address"] != nil)
        titleStr = [address valueForKey:@"address"];
    
    self.title = titleStr;
    
    
    //prepare data for the table
    dataArray = [[NSMutableArray alloc] init];
    
    [dataArray addObject:feedback_issue_array];
    [dataArray addObject:post_array];
    
    //remove feedback_issue with post since we already have post dict
//    DDLogVerbose(@"first object %@",[dataArray firstObject]);
//    for (int i = 0; i < [[dataArray firstObject] count]; i++) {
//        NSDictionary *dict = [[dataArray firstObject] objectAtIndex:i];
//        DDLogVerbose(@"%@",dict);
//        if([[dict valueForKey:@"client_post_id"] intValue] > 0 || [[dict valueForKey:@"post_id"] intValue] > 0)
//        {
//            [[dataArray firstObject] removeObject:dict];
//        }
//    }
    
    DDLogVerbose(@"%@",dataArray);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[dataArray objectAtIndex:section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return dataArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        NSString *crmCount = [NSString stringWithFormat:@"Crm(%lu)",(unsigned long)[[dataArray firstObject] count]];
        return crmCount;
    }
    else
    {
        NSString *issueCount = [NSString stringWithFormat:@"Issues(%lu)",(unsigned long)[[dataArray lastObject] count]];
        return issueCount;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    

    if(indexPath.section == 0)
    {
        NSDictionary *dict = [[dataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict valueForKey:@"issue_des"];
        cell.detailTextLabel.text = [cmrStatus objectAtIndex:[[dict valueForKey:@"status"] intValue]];
    }
    else
    {
        NSDictionary *dict = [[dataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict valueForKey:@"post_topic"];
        cell.detailTextLabel.text = [issueStatus objectAtIndex:[[dict valueForKey:@"status"] intValue]];
    }
    
    return cell;
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
