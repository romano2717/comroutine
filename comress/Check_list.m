//
//  Check_list.m
//  comress
//
//  Created by Diffy Romano on 16/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Check_list.h"

@implementation Check_list


- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchCheckListForBlockId:(NSNumber *)blkId
{
    NSMutableArray *skedAdrr = [[NSMutableArray alloc] init];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsSked = [db executeQuery:@"select * from ro_schedule where w_blkid = ? order by w_scheduledate asc",blkId];

        while ([rsSked next]) {
            [skedAdrr addObject:[rsSked resultDictionary]];
        }
    }];
    
    return skedAdrr;
}

- (NSArray *)checklistForJobTypeId:(NSNumber *)jobTypeId
{
    NSMutableArray *checkListArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsChkL = [db executeQuery:@"select * from ro_checklist where w_jobtypeid = ?",jobTypeId];
        
        while ([rsChkL next]) {
            NSNumber *w_chkareaid = [NSNumber numberWithInt:[rsChkL intForColumn:@"w_chkareaid"]];
            
            if([w_chkareaid intValue] == 0)
                [checkListArr addObject:[rsChkL resultDictionary]];
            else
            {
                FMResultSet *rsChkArea = [db executeQuery:@"select * from ro_checkarea where w_chkareaid = ?",w_chkareaid];
                while ([rsChkArea next]) {
                    [checkListArr addObject:[rsChkL resultDictionary]];
                }
            }
        }
    }];
    
    return checkListArr;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from ro_checklist_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into ro_checklist_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update ro_checklist_last_req_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

@end
