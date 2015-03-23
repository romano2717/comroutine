//
//  CheckListViewController.m
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "CheckListViewController.h"

@interface CheckListViewController ()

@end

@implementation CheckListViewController

@synthesize blockId,scheduleArrayRaw,selectedCheckList,selectedJobTypes;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    check_list = [[Check_list alloc] init];
    
    self.sectionsArray = [[NSMutableArray alloc] init];
    self.scheduleArray = [[NSMutableArray alloc] init];
    self.checkListArray = [[NSMutableArray alloc] init];
    
    selectedJobTypes = [[NSMutableArray alloc] init];
    selectedCheckList = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self fetchCheckList];
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

- (void)fetchCheckList
{
    self.scheduleArray = [check_list fetchCheckListForBlockId:blockId];
    scheduleArrayRaw = self.scheduleArray;
    
    //create sections array and group it!
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.scheduleArray.count; i++) {
        NSDictionary *dict = [self.scheduleArray objectAtIndex:i];
        [self.sectionsArray addObject:[dict valueForKey:@"w_jobtype"]];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[dict valueForKey:@"w_jobtypeId"] intValue]];
        
        [arr addObject:[check_list checklistForJobTypeId:jobTypeId]];
    }
    
    self.scheduleArray = arr;
    
    
    //set the area
    
    NSString *area = [NSString stringWithFormat:@"Area: %@",[[self.scheduleArrayRaw lastObject] valueForKey:@"w_area"]];
    
    if(self.scheduleArray.count == 0)
        area = @"No Schedule for today.";
    
    self.areaLabel.text = area;
    
    [self.checkListTable reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.scheduleArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionsArray objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDictionary *dict = [self.scheduleArrayRaw objectAtIndex:section];
    
    CheckListHeader* ch = [tableView dequeueReusableCellWithIdentifier:@"headerCell"];
    
    [ch initCellWithResultSet:dict];
    
    //job type toggle
    ch.checkBoxBtn.tag = (int)section;
    [ch.checkBoxBtn addTarget:self action:@selector(toggleJobTypeCheckBox:) forControlEvents:UIControlEventTouchUpInside];
    
    if([selectedJobTypes containsObject:[NSNumber numberWithInt:(int)section]])
    {
        [ch.checkBoxBtn setSelected:YES];
    }
    else
    {
        [ch.checkBoxBtn setSelected:NO];
    }


    //finish and save
    ch.saveBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    [ch.saveBtn addTarget:self action:@selector(saveCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    ch.finishBtn.tag = [[dict valueForKey:@"w_scheduleid"] integerValue];
    [ch.finishBtn addTarget:self action:@selector(finishCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    return ch;
}

- (IBAction)saveCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;

    DDLogVerbose(@"save checklist %@",selectedCheckList);
    DDLogVerbose(@"save job type %@",selectedJobTypes);
    DDLogVerbose(@"job type section %d",(int)btn.tag);
    
    [btn setSelected:!btn.selected];
}

- (IBAction)finishCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    DDLogVerbose(@"finish checklist %@",selectedCheckList);
    DDLogVerbose(@"save job type %@",selectedJobTypes);
    DDLogVerbose(@"job type section %d",(int)btn.tag);
    
    [btn setSelected:!btn.selected];
}

- (IBAction)toggleJobTypeCheckBox:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    DDLogVerbose(@"toggle job type check box for %@",tag);
    
    [btn setSelected:!btn.selected];
    
    if([selectedJobTypes containsObject:tag] == NO)
    {
        [selectedJobTypes addObject:tag];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:btn.tag] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];

        //check all checklist under this section
        for (int i = 0; i < checkList.count; i++) {
            NSDictionary *dict = [checkList objectAtIndex:i];
            [selectedCheckList addObject:[NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]]];
        }
    }
    
    else
    {
        [selectedJobTypes removeObject:tag];
        
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:btn.tag] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];
        
        //un-check all checklist under this section
        for (int i = 0; i < checkList.count; i++) {
            NSDictionary *dict = [checkList objectAtIndex:i];
            [selectedCheckList removeObject:[NSNumber numberWithInt:[[dict valueForKey:@"id"] intValue]]];
        }
    }
    
    [self.checkListTable reloadData];
}

- (IBAction)toggleCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    DDLogVerbose(@"toggle check list for %ld",(long)btn.tag);
    
    [btn setSelected:!btn.selected];
    
    CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkListTable];
    NSIndexPath *indexPath = [self.checkListTable indexPathForRowAtPoint:buttonOriginInTableView];
    
    if([selectedCheckList containsObject:tag] == NO)
    {
        [selectedCheckList addObject:tag];
        
        //mark check this section if all contents of checkList is found inside
        NSNumber *jobTypeId = [NSNumber numberWithInt:[[[scheduleArrayRaw objectAtIndex:indexPath.section] valueForKey:@"w_jobtypeId"] intValue]] ;
        NSArray *checkList = [check_list checklistForJobTypeId:jobTypeId];
        NSMutableArray *checkedIds = [[NSMutableArray alloc] init];
        
        //save the only ids
        for (int i = 0; i < checkList.count; i++) {
            NSNumber *ids = [NSNumber numberWithInt:[[[checkList objectAtIndex:i] valueForKey:@"id"] intValue]];
            [checkedIds addObject:ids];
        }
        
        BOOL found = YES;
        for (int i = 0; i < checkedIds.count; i++) {
            NSNumber *chklst = [checkedIds objectAtIndex:i];
            DDLogVerbose(@"chklst %@",chklst);
            DDLogVerbose(@"selectedCheckList %@",selectedCheckList);
            if([selectedCheckList containsObject:chklst] == NO)
            {
                found = NO;
                break;
            }
            
        }
        
        if(found)
        {
            [selectedJobTypes addObject:[NSNumber numberWithInt:(int)indexPath.section]];
        }
    }
    else
    {
        [selectedCheckList removeObject:tag];
        
        //un-check the section of this checklist
        CGPoint buttonOriginInTableView = [sender convertPoint:CGPointZero toView:self.checkListTable];
        NSIndexPath *indexPath = [self.checkListTable indexPathForRowAtPoint:buttonOriginInTableView];
        
        [selectedJobTypes removeObject:[NSNumber numberWithInt:(int)indexPath.section]];
    }
    
    
    
    DDLogVerbose(@"selectedCheckList %@",selectedCheckList);

    
    [self.checkListTable reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CheckListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    NSDictionary *dict = [[self.scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    [cell initCellWithResultSet:dict];
    
    //add method to checkbox
    [cell.checkBoxBtn addTarget:self action:@selector(toggleCheckList:) forControlEvents:UIControlEventTouchUpInside];
    
    NSNumber *tag = [NSNumber numberWithInt:(int)cell.checkBoxBtn.tag];
    
    if([selectedCheckList containsObject:tag] ==  YES)
    {
        [cell.checkBoxBtn setSelected:YES];
    }
    else
    {
        [cell.checkBoxBtn setSelected:NO];
    }
    
    return cell;
}

@end
