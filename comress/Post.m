//
//  Post.m
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Post.h"
#import "Synchronize.h"

@implementation Post

@synthesize
client_post_id,
post_id,
post_topic,
post_by,
post_date,
updated_on,
post_type,
severity,
address,
status,
level,
block_id,
postal_code,
seen,
contract_type;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    return self;
}

- (long long)savePostWithDictionary:(NSDictionary *)dict
{
    __block BOOL postSaved;
    __block long long posClienttId = 0;
    
    client_post_id  = [[dict valueForKey:@"client_post_id"] intValue];
    post_id         = [[dict valueForKey:@"post_id"] intValue];
    post_topic      = [dict valueForKey:@"post_topic"];
    post_by         = [dict valueForKey:@"post_by"];
    post_date       = [dict valueForKey:@"post_date"];
    post_type       = [dict valueForKey:@"post_type"];
    severity        = [dict valueForKey:@"severity"];
    address         = [dict valueForKey:@"address"];
    status          = [dict valueForKey:@"status"];
    level           = [dict valueForKey:@"level"];
    block_id        = [dict valueForKey:@"block_id"];
    postal_code     = [dict valueForKey:@"postal_code"];
    updated_on      = [dict valueForKey:@"updated_on"];
    seen            = [dict valueForKey:@"seen"];
    contract_type   = [dict valueForKey:@"contract_type"];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        postSaved = [db executeUpdate:@"insert into post (post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,isUpdated,postal_code,updated_on,seen,contract_type) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,[NSNumber numberWithBool:YES],postal_code,updated_on,seen,contract_type];
        
        if(!postSaved)
        {
            *rollback = YES;
            DDLogVerbose(@"%@ [%@-%@]",[db lastError],THIS_FILE,THIS_METHOD);
        }
        posClienttId = [db lastInsertRowId];
    }];
    
    return posClienttId;
}


- (long long)savePostWithDictionary:(NSDictionary *)dict forBlockId:(NSNumber *)blockId
{
    __block BOOL postSaved;
    __block long long posClienttId = 0;
    
    client_post_id  = [[dict valueForKey:@"client_post_id"] intValue];
    post_id         = [[dict valueForKey:@"post_id"] intValue];
    post_topic      = [dict valueForKey:@"post_topic"];
    post_by         = [dict valueForKey:@"post_by"];
    post_date       = [dict valueForKey:@"post_date"];
    post_type       = [dict valueForKey:@"post_type"];
    severity        = [dict valueForKey:@"severity"];
    address         = [dict valueForKey:@"address"];
    status          = [dict valueForKey:@"status"];
    level           = [dict valueForKey:@"level"];
    block_id        = [dict valueForKey:@"block_id"];
    postal_code     = [dict valueForKey:@"postal_code"];
    updated_on      = [dict valueForKey:@"updated_on"];
    seen            = [dict valueForKey:@"seen"];
    
    if(block_id == nil)
        return 0;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = YES;
        NSNumber *postTypeRoutine = [NSNumber numberWithInt:2];
        
        FMResultSet *rs = [db executeQuery:@"select block_id, post_type from post where post_type = ? and block_id = ?",postTypeRoutine, blockId];
        
        if([rs next] == NO) //does not exist, create!
        {
            postSaved = [db executeUpdate:@"insert into post (post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,isUpdated,postal_code,updated_on,seen) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",post_topic,post_by,post_date,post_type,severity,address,status,level,block_id,[NSNumber numberWithBool:YES],postal_code,updated_on,seen];
            
            if(!postSaved)
            {
                *rollback = YES;
                DDLogVerbose(@"%@ [%@-%@]",[db lastError],THIS_FILE,THIS_METHOD);
            }
            posClienttId = [db lastInsertRowId];
        }
    }];
    
    return posClienttId;
}

- (NSArray *)fetchIssuesWithParams:(NSDictionary *)params forPostId:(NSNumber *)postId filterByBlock:(BOOL)filter newIssuesFirst:(BOOL)newIssuesFirst onlyOverDue:(BOOL)onlyOverDue
{
    @try {
        int __block overDueIssues = 0;
        
        myDatabase.allPostWasSeen = YES;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        
        client_post_id      = [[params valueForKey:@"client_post_id"] intValue];
        post_id             = [[params valueForKey:@"post_id"] intValue];
        post_topic          = [params valueForKey:@"post_topic"];
        post_by             = [params valueForKey:@"post_by"];
        post_date           = [params valueForKey:@"post_date"];
        post_type           = [params valueForKey:@"post_type"];
        severity            = [params valueForKey:@"severity"];
        address             = [params valueForKey:@"address"];
        status              = [params valueForKey:@"status"];
        level               = [params valueForKey:@"level"];
        
        /*
         change query to also get all the images for the post
         */
        NSMutableString *q;
        
        NSDate *now = [NSDate date];
        NSDate *daysAgo = [now dateByAddingTimeInterval:-overDueDays*24*60*60];
        double timestampDaysAgo = [daysAgo timeIntervalSince1970];
        
        NSNumber *finishedStatus = [NSNumber numberWithInt:4];
        
        if(postId == nil) //for listing
        {
            if(onlyOverDue == NO)
            {
                if(filter == YES) //ME, don't display overdue
                    q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where post_type = 1 and post_date >= %f and status != %@ ",timestampDaysAgo,finishedStatus] ]; //post_type = 1 is ISSUES
                else // Others
                    q = [[NSMutableString alloc] initWithString:@"select * from post where post_type = 1 " ]; //post_type = 1 is ISSUES
            }
            
            else
            {
                q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where post_type = 1 and post_date <= '%f' and status != %@ ",timestampDaysAgo, finishedStatus]]; //post_type = 1 is ISSUES
            }
        }
        
        else //for chat
        {
            if(onlyOverDue == NO)
            {
                q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where client_post_id = %@ ",postId]];
            }
            else
            {
                q = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"select * from post where client_post_id = %@ and post_date <= '%f' and status != %@ ",postId,timestampDaysAgo,finishedStatus]];
            }
        }
        
        
        if([params valueForKey:@"order"])
        {
            [q appendString:[params valueForKey:@"order"]];
        }
        
        
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            db.traceExecution = YES;
            FMResultSet *rsPost = [db executeQuery:q];
            
            while ([rsPost next]) {
                
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"client_post_id"]];
                NSNumber *serverPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
                
                NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
                
                if([rsPost boolForColumn:@"seen"] == NO && onlyOverDue == YES) //if we found at leas one we flag it to no
                    myDatabase.allPostWasSeen = NO;
                
                /*
                 add post info to our dict. this will be the top most level of our dictionary entry.
                 but first check if this post under this block belongs to current user or others
                 */
                
                if(filter == YES)
                {
                    FMResultSet *rsBlock = [db executeQuery:@"select block_id from blocks_user where block_id = ?",[rsPost stringForColumn:@"block_id"]];
                    
                    if([rsBlock next] == NO)
                        continue;
                }
                else
                {
                    FMResultSet *rsBlock = [db executeQuery:@"select block_id from blocks_user where block_id = ?",[rsPost stringForColumn:@"block_id"]];
                    
                    if([rsBlock next] == YES)
                        continue;
                }
                
                [postChild setObject:[rsPost resultDictionary] forKey:@"post"];
                
                if(onlyOverDue == YES)
                    overDueIssues ++;
                
                
                //check if this post is not yet read by the user
                NSNumber *newCommentsCount = [NSNumber numberWithInt:0];
                FMResultSet *rsRead = [db executeQuery:@"select count(*) as count from comment_noti where post_id = ? and status = ? group by post_id",serverPostId,[NSNumber numberWithInt:1]];
                if([rsRead next] == YES)
                    newCommentsCount = [NSNumber numberWithInt:[rsRead intForColumn:@"count"]];
                
                [postChild setObject:newCommentsCount forKey:@"newCommentsCount"];
                
                
                
                //add all images of this post
                FMResultSet *rsPostImage;
                
                if([serverPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where post_id = ? order by client_post_image_id ",serverPostId];
                }
                else if([clientPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where client_post_id = ? order by client_post_image_id ",clientPostId];
                }
                
                NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
                
                while ([rsPostImage next]) {
                    [imagesArray addObject:[rsPostImage resultDictionary]];
                }
                
                [postChild setObject:imagesArray forKey:@"postImages"];
                
                
                //get all comments for this post including comment image if there's any
                FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where (client_post_id = ? or post_id = ?)  order by comment_on asc",clientPostId,serverPostId];
                NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
                
                while ([rsPostComment next]) {
                    
                    NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                    
                    if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                    {
                        //get the image path
                        FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]]];
                        
                        while ([rsImagePath next]) {
                            [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                        }
                    }
                    
                    [commentsArray addObject:commentsDict];
                    
                }
                
                [postChild setObject:commentsArray forKey:@"postComments"];
                
                [postDict setObject:postChild forKey:postId ? postId : clientPostId];
                
                [arr addObject:postDict];
            }
        }];
        
        NSMutableArray *mutArr = [[NSMutableArray alloc] initWithArray:arr];
        
        //re-order the posts according to unread messages
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from comment_noti order by id desc"];
            
            while ([rs next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                
                for (int i = 0; i < arr.count; i++) {
                    NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                    NSNumber *key = [[dict allKeys] lastObject];
                    NSNumber *postIdNum = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"];
                    
                    if([postIdNum isEqual:[NSNull null]])
                        return;
                    
                    if([postId intValue] == [postIdNum intValue])
                    {
                        [mutArr removeObject:dict];
                        [mutArr insertObject:dict atIndex:0];
                    }
                }
            }
        }];
        
        //reorder the posts according to new issues
        if(newIssuesFirst)
        {
            for (int i = 0; i < arr.count; i++) {
                NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                NSNumber *key = [[dict allKeys] lastObject];
                NSNumber *seenPost = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"seen"];
                
                if([seenPost intValue] == 0)
                {
                    [mutArr removeObject:dict];
                    [mutArr insertObject:dict atIndex:0];
                }
            }
        }
        
        DDLogVerbose(@"overdue %d",overDueIssues);
        if(overDueIssues > 0)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"thereAreOVerDueIssues" object:nil userInfo:@{@"count":[NSNumber numberWithInt:overDueIssues]}];
        }
        
        if(mutArr.count == arr.count)
            return mutArr;
        
        if(myDatabase.allPostWasSeen)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"allPostWasSeen" object:nil];
        }
       
        return arr;
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"fetchIssuesWithParams: %@",exception);
    }
    @finally {

    }
}

- (NSArray *)postsToSend
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from post where post_id IS NULL or post_id = ?",[NSNumber numberWithInt:0]];
        
        NSMutableArray *rsArray = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            
            NSDictionary *dict = @{
                                   @"PostTopic":[rs stringForColumn:@"post_topic"],
                                   @"PostBy":[rs stringForColumn:@"post_by"],
                                   @"PostType":[rs stringForColumn:@"post_type"],
                                   @"Severity":[NSNumber numberWithInt:[rs intForColumn:@"severity"]],
                                   @"ActionStatus":[rs stringForColumn:@"status"],
                                   @"ClientPostId":[NSNumber numberWithInt:[rs intForColumn:@"client_post_id"]],
                                   @"BlkId":[NSNumber numberWithInt:[rs intForColumn:@"block_id"]],
                                   @"Location":[rs stringForColumn:@"address"],
                                   @"PostalCode":[rs stringForColumn:@"postal_code"],
                                   @"Level":[rs stringForColumn:@"level"],
                                   @"IsUpdated":[NSNumber numberWithBool:NO]
                                   };
            
            
            [rsArray addObject:dict];
            
            dict = nil;
        }
        
        [db close];
    }];
    
    return nil;
}

- (BOOL)updatePostStatusForClientPostId:(NSNumber *)clientPostId withStatus:(NSNumber *)theStatus
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        BOOL upPost = [theDb executeUpdate:@"update post set status = ? where client_post_id = ?",theStatus,clientPostId];
        
        if(!upPost)
        {
            *rollback = YES;
            return ;
        }
        
        BOOL postWasUpdated = [theDb executeUpdate:@"update post set statusWasUpdated = ? where client_post_id = ?",[NSNumber numberWithBool:YES],clientPostId];
        
        if(!postWasUpdated)
        {
            *rollback = YES;
            return;
        }
    }];
    
    return YES;
}

- (BOOL)updateLastRequestDateWithDate:(NSString *)dateString
{
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
        FMResultSet *rs = [theDb executeQuery:@"select * from post_last_request_date"];
        
        if(![rs next])
        {
            BOOL qIns = [theDb executeUpdate:@"insert into post_last_request_date(date) values(?)",date];
            
            if(!qIns)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL qUp = [theDb executeUpdate:@"update post_last_request_date set date = ? ",date];
            
            if(!qUp)
            {
                *rollback = YES;
                return;
            }
        }
    }];
    
    return YES;
}

- (BOOL)updatePostAsSeen:(NSNumber *)clientPostId serverPostId:(NSNumber *)serverPostId
{
    __block BOOL ok = YES;
    NSNumber *zero = [NSNumber numberWithInt:0];
    
    myDatabase = [Database sharedMyDbManager];
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = YES;
        //update this post as seen
        NSNumber *wasSeen = [NSNumber numberWithBool:YES];

        BOOL postSeen = [db executeUpdate:@"update post set seen = ? where client_post_id = ?", wasSeen,clientPostId];
        if(!postSeen)
        {
            ok = NO;
            *rollback = YES;
            return;
        }
        
        //set status = 2 of this post from comment noti
        BOOL rmNoti = [db executeUpdate:@"update comment_noti set status = ? where post_id = ? and post_id != ?",[NSNumber numberWithInt:2],serverPostId,zero];
        
        if(!rmNoti)
        {
            ok = NO;
            *rollback = YES;
            return;
        }
        DDLogVerbose(@"rows affected %d",[db changes]);
    }];
    
    Synchronize *sync = [Synchronize sharedManager];
    
    [sync uploadCommentNotiAlreadyReadFromSelf:NO];
    
    return ok;
}


#pragma mark - routine posts

-(NSArray *)fetchPostsForBlockId:(NSNumber *)blockId
{
    @try {
        //myDatabase.allPostWasSeen = YES;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        
        /*
         change query to also get all the images for the post
         */


        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsPost = [db executeQuery:@"select * from post where block_id = ? and post_type = ?",blockId,[NSNumber numberWithInt:2]];
            
            while ([rsPost next]) {
                
                NSNumber *clientPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"client_post_id"]];
                NSNumber *serverPostId = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
                
                NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *postChild = [[NSMutableDictionary alloc] init];
                
                
                //if([rsPost boolForColumn:@"seen"] == NO) //if we found at leas one we flag it to no
                  //  myDatabase.allPostWasSeen = NO;
                
                [postChild setObject:[rsPost resultDictionary] forKey:@"post"];
                
                
                //check if this post is not yet read by the user
                NSNumber *newCommentsCount = [NSNumber numberWithInt:0];
                FMResultSet *rsRead = [db executeQuery:@"select count(*) as count from comment_noti where post_id = ? and status = ? group by post_id",serverPostId,[NSNumber numberWithInt:1]];
                if([rsRead next] == YES)
                    newCommentsCount = [NSNumber numberWithInt:[rsRead intForColumn:@"count"]];
                
                [postChild setObject:newCommentsCount forKey:@"newCommentsCount"];
                
                
                //add all images of this post
                FMResultSet *rsPostImage;
                
                if([serverPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where post_id = ? order by client_post_image_id ",serverPostId];
                }
                else if([clientPostId intValue] != 0)
                {
                    rsPostImage = [db executeQuery:@"select * from post_image where client_post_id = ? order by client_post_image_id ",clientPostId];
                }
                
                NSMutableArray *imagesArray = [[NSMutableArray alloc] init];
                
                while ([rsPostImage next]) {
                    [imagesArray addObject:[rsPostImage resultDictionary]];
                }
                
                [postChild setObject:imagesArray forKey:@"postImages"];
                
                
                //get all comments for this post including comment image if there's any
                FMResultSet *rsPostComment = [db executeQuery:@"select * from comment where (client_post_id = ? or post_id = ?)  order by comment_on desc",clientPostId,serverPostId];
                NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
                
                while ([rsPostComment next]) {
                    
                    NSMutableDictionary *commentsDict = [[NSMutableDictionary alloc] initWithDictionary:[rsPostComment resultDictionary]];
                    
                    if([[rsPostComment stringForColumn:@"comment"] isEqualToString:@"<image>"])
                    {
                        //get the image path
                        FMResultSet *rsImagePath = [db executeQuery:@"select image_path from post_image where client_comment_id = ? or comment_id = ?",[NSNumber numberWithInt:[rsPostComment intForColumn:@"client_comment_id"]],[NSNumber numberWithInt:[rsPostComment intForColumn:@"comment_id"]]];
                        
                        while ([rsImagePath next]) {
                            [commentsDict setObject:[rsImagePath stringForColumn:@"image_path"] forKey:@"image"];
                        }
                    }
                    
                    [commentsArray addObject:commentsDict];
                    
                }
                
                [postChild setObject:commentsArray forKey:@"postComments"];
                
                [postDict setObject:postChild forKey:blockId ? blockId : clientPostId];
                
                [arr addObject:postDict];
            }
        }];
        
        NSMutableArray *mutArr = [[NSMutableArray alloc] initWithArray:arr];
        
        //re-order the posts according to unread messages
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from comment_noti order by id desc"];
            
            while ([rs next]) {
                NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
                
                for (int i = 0; i < arr.count; i++) {
                    NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
                    NSNumber *key = [[dict allKeys] lastObject];
                    NSNumber *postIdNum = [[[dict objectForKey:key] objectForKey:@"post"] valueForKey:@"post_id"];
                    
                    if([postIdNum isEqual:[NSNull null]])
                        return;
                    
                    if([postId intValue] == [postIdNum intValue])
                    {
                        [mutArr removeObject:dict];
                        [mutArr insertObject:dict atIndex:0];
                    }
                }
            }
        }];
        
        
        if(mutArr.count == arr.count)
            return mutArr;
        
        //if(myDatabase.allPostWasSeen)
        //{
           // [[NSNotificationCenter defaultCenter] postNotificationName:@"allPostWasSeen" object:nil];
        //}
        
        return arr;
    }
    @catch (NSException *exception) {
        DDLogVerbose(@"fetchIssuesWithParams: %@",exception);
    }
    @finally {
        
    }
}

@end
