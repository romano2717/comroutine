//
//  CreateIssueViewController.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CreateIssueViewController.h"

@interface CreateIssueViewController ()

@end

@implementation CreateIssueViewController

@synthesize surveyId,surveyDetail,postalCode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    DDLogVerbose(@"survey detail %@",surveyDetail);
    DDLogVerbose(@"postal code %@",postalCode);
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //search postal code here then auto fill in form if found. if not found, prompt user that postal code was not found. ask continue search/type or cancel
    
    __block BOOL postalCodeFound = NO;
    __block NSString *postalCodeString;
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"select * from blocks where postal_code = ?",postalCode];
        
        if([rs next])
        {
            postalCodeString = [rs stringForColumn:@"postal_code"];
            postalCodeFound = YES;
        }
    }];
    
    if(postalCodeFound)
    {
        self.postalCodeTextField.text = postalCodeString;
    }
    
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Issue" message:[NSString stringWithFormat:@"Postal code %@ was not found in our system. Continue to create issue by searching for the correct Postal Code?",postalCode] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        
        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


- (IBAction)cance:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
