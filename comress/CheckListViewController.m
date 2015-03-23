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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //create a default slots for checklist based on number of schedule
        selectedCheckList = [[NSMutableArray alloc] initWithCapacity:scheduleArrayRaw.count];
        for (int i = 0; i < scheduleArrayRaw.count; i++) {
            [selectedCheckList addObject:@[@"temp"]];
        }
        
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
    });
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
        [ch.checkBoxBtn setImage:[UIImage imageNamed:@"checked@2x.png"] forState:UIControlStateNormal];
    }
    else
    {
        [ch.checkBoxBtn setImage:[UIImage imageNamed:@"check@2x.png"] forState:UIControlStateNormal];
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

    DDLogVerbose(@"save %ld",(long)btn.tag);
    
    
    [btn setSelected:!btn.selected];
}

- (IBAction)finishCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    DDLogVerbose(@"finish %ld",(long)btn.tag);
    
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

        
        NSMutableArray *rowsOfCheckList = [[NSMutableArray alloc] init];
        for (int i = 0; i < checkList.count; i++) {
            [rowsOfCheckList addObject:[NSNumber numberWithInt:i]];
        }
        
        [selectedCheckList replaceObjectAtIndex:btn.tag withObject:rowsOfCheckList];
        
    }
    
    else
    {
        [selectedJobTypes removeObject:tag];
        
        [selectedCheckList replaceObjectAtIndex:btn.tag withObject:@[@"temp"]];
    }
    
    DDLogVerbose(@"selectedJobTypes %@",selectedJobTypes);
    DDLogVerbose(@"selectedCheckList %@",selectedCheckList);


    [self.checkListTable reloadData];
}

- (IBAction)toggleCheckList:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSNumber *tag = [NSNumber numberWithInt:(int)btn.tag];
    
    DDLogVerbose(@"toggle check list for %ld",(long)btn.tag);
    
    [btn setSelected:!btn.selected];
    
    if([selectedCheckList containsObject:tag] == NO)
        [selectedCheckList addObject:tag];
    else
        [selectedCheckList removeObject:tag];
    
    [self.checkListTable reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CheckListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    NSDictionary *dict = [[self.scheduleArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    [cell initCellWithResultSet:dict];
    
    //add method to checkbox
    [cell.checkBoxBtn addTarget:self action:@selector(toggleCheckList:) forControlEvents:UIControlEventTouchUpInside];
    cell.checkBoxBtn.tag = indexPath.row;
    
    if([[selectedCheckList objectAtIndex:indexPath.section] containsObject:[NSNumber numberWithInt:(int)indexPath.row]])
    {
        [cell.checkBoxBtn setImage:[UIImage imageNamed:@"checked@2x.png"] forState:UIControlStateNormal];
    }
    else
    {
        [cell.checkBoxBtn setImage:[UIImage imageNamed:@"check@2x.png"] forState:UIControlStateNormal];
    }
    
    return cell;
}

@end
