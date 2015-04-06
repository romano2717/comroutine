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

@synthesize currentClientSurveyId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    
    //add border to the textview
    [[self.feedBackTextView layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[self.feedBackTextView layer] setBorderWidth:1];
    [[self.feedBackTextView layer] setCornerRadius:15];
    
    self.selectedFeeBackTypeArr = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    
    self.navigationItem.hidesBackButton = YES;
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
    
    [btn setSelected:!btn.selected];
}


- (IBAction)addFeedBack:(id)sender
{
    NSArray *comressTypes = @[[NSNumber numberWithInt:2],[NSNumber numberWithInt:3],[NSNumber numberWithInt:4],[NSNumber numberWithInt:5]];
    
    int foundComressTypes = 0;
    
    for (int i = 0; i < self.selectedFeeBackTypeArr.count; i++) {
        NSNumber *selected = [self.selectedFeeBackTypeArr objectAtIndex:i];
        
        if([comressTypes containsObject:selected])
            foundComressTypes ++;
        
    }
    
    NSString *message = [NSString stringWithFormat:@"Are you sure you want to create %d issues?",foundComressTypes];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback" message:message delegate:self cancelButtonTitle:@"" otherButtonTitles:@"Yes", nil];

    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        //save feedback!
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
//            client_survey_id
//            description
//            client_address_id
            
            //get the client_address_id of this feedback based on self.selectedFeedBackLoc
            

        }];
    }
}



@end
