//
//  Schedule.m
//  comress
//
//  Created by Diffy Romano on 17/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Schedule.h"

@implementation Schedule

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchScheduleForMe
{
    NSMutableArray *skedArr = [[NSMutableArray alloc] init];

    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        FMResultSet *rsblk = [db executeQuery:@"select b.block_id, b.block_no,b.street_name from blocks b, blocks_user bu where b.block_id = bu.block_id"];
        
        while ([rsblk next]) {
            
            NSDictionary *blockDict = [NSDictionary dictionaryWithObject:[rsblk resultDictionary] forKey:[NSString stringWithFormat:@"%d",[rsblk intForColumn:@"block_id"]]];
            
            NSMutableDictionary *blockDictMutable = [[NSMutableDictionary alloc] initWithDictionary:blockDict];
            
            [skedArr addObject:blockDictMutable];
        }
        
        
        //move the blocks with current schedule on top
        for (int i = 0; i < skedArr.count; i++) {
            NSDictionary *topDict = [skedArr objectAtIndex:i];
            int key = [[[topDict allKeys] objectAtIndex:0] intValue];
            
            NSMutableDictionary *blockDict = [[NSMutableDictionary alloc] initWithDictionary:[topDict objectForKey:[NSString stringWithFormat:@"%d",key]]];
            
            NSNumber *block_id =  [blockDict valueForKey:@"block_id"];
            
            FMResultSet *rsSked = [db executeQuery:@"select w_blkid from ro_schedule where w_blkid = ? order by w_scheduledate desc",block_id];
            
            if([rsSked next])
            {
                [blockDict setObject:[rsSked resultDictionary] forKey:@"schedule"];
                [skedArr insertObject:blockDict atIndex:0];
            }
        }
        
    }];
    
    return skedArr;
}

- (NSArray *)fetchScheduleForOthersAtPage:(NSNumber *)limit
{
    NSNumber *start = [NSNumber numberWithInt:0];
    
    NSMutableArray *skedArr = [[NSMutableArray alloc] init];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = YES;
        FMResultSet *rsblk = [db executeQuery:@"select b.block_id,b.block_no,b.street_name, rs.* from blocks b, ro_schedule rs, blocks_user bu where b.block_id = rs.w_blkid and rs.w_blkid != bu.block_id group by rs.w_blkid"];
        
        while ([rsblk next]) {
            
            NSDictionary *blockDict = [NSDictionary dictionaryWithObject:[rsblk resultDictionary] forKey:[NSString stringWithFormat:@"%d",[rsblk intForColumn:@"block_id"]]];

            [skedArr addObject:blockDict];
        }
        
        //add the rest of the blocks that are not found in blocks_users
        FMResultSet *rsAllBlk = [db executeQuery:@"select * from blocks where block_id not in(select block_id from blocks_user) limit ?, ?",start,limit];
        
        while ([rsAllBlk next]) {
            NSDictionary *blockDict = [NSDictionary dictionaryWithObject:[rsAllBlk resultDictionary] forKey:[NSString stringWithFormat:@"%d",[rsAllBlk intForColumn:@"block_id"]]];
            
            [skedArr addObject:blockDict];
        }

    }];
    
    DDLogVerbose(@"%@",skedArr);
    
    return skedArr;
}


- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from ro_schedule_last_req_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into ro_schedule_last_req_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update ro_schedule_last_req_date set date = ? ",date];
            
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
