//

//  Synchronize.m
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Synchronize.h"

@implementation Synchronize

@synthesize syncKickstartTimerOutgoing,syncKickstartTimerIncoming,imagesArr,imageDownloadComplete,downloadIsTriggeredBySelf,stop;

-(id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
        imagesArr = [[NSMutableArray alloc] init];
    }
    return self;
}

+(id)sharedManager {
    static Synchronize *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)kickStartSync
{
    stop = NO;
    
    //outgoing
    //[self uploadPostFromSelf:YES];
    syncKickstartTimerOutgoing = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(uploadPost) userInfo:nil repeats:YES];

    //[self startDownload];
    downloadIsTriggeredBySelf = YES;
    syncKickstartTimerIncoming = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(startDownload) userInfo:nil repeats:YES];
}


- (void)uploadPost
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    [self uploadPostFromSelf:YES];
}


- (void)startDownload
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if([syncKickstartTimerIncoming isValid])
        [syncKickstartTimerIncoming invalidate]; //init is done, no need for timer. post, comment, image, etc will recurse automatically.
    
    //incoming
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //__block NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];


        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download post
            FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
            
            if([rs next])
            {
                jsonDate = (NSDate *)[rs dateForColumn:@"date"];
                
            }
            [self startDownloadPostForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download post image
            FMResultSet *rs2 = [db executeQuery:@"select date from post_image_last_request_date"];
            
            if([rs2 next])
            {
                jsonDate = (NSDate *)[rs2 dateForColumn:@"date"];
                
            }
            [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download comments
            FMResultSet *rs3 = [db executeQuery:@"select date from comment_last_request_date"];
            
            if([rs3 next])
            {
                jsonDate = (NSDate *)[rs3 dateForColumn:@"date"];
            }
            [self startDownloadCommentsForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download comment noti
            FMResultSet *rs4 = [db executeQuery:@"select date from comment_noti_last_request_date"];
            
            if([rs4 next])
            {
                jsonDate = (NSDate *)[rs4 dateForColumn:@"date"];
            }
            [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download questions
            FMResultSet *rs55 = [db executeQuery:@"select date from su_questions_last_req_date"];
            
            if([rs55 next])
            {
                jsonDate = (NSDate *)[rs55 dateForColumn:@"date"];
            }
            [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download survey
            FMResultSet *rs5 = [db executeQuery:@"select date from su_survey_last_req_date"];
            
            if([rs5 next])
            {
                jsonDate = (NSDate *)[rs5 dateForColumn:@"date"];
            }
            [self startDownloadSurveyPage:1 totalPage:0 requestDate:jsonDate];
            
            
            jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
            //download feedback issues list
            FMResultSet *rs6 = [db executeQuery:@"select date from su_feedback_issues_last_req_date"];
            
            if([rs6 next])
            {
                jsonDate = (NSDate *)[rs5 dateForColumn:@"date"];
            }
            [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:jsonDate];
            
        }];
    });
}

- (void)uploadPostStatusChangeFromSelf:(BOOL)thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

        FMResultSet *rs = [db executeQuery:@"select * from post where statusWasUpdated = ? and post_id is not null",[NSNumber numberWithBool:YES]];
        
        NSMutableArray *posts = [[NSMutableArray alloc] init];

        while([rs next])
        {
            DDLogVerbose(@"upload post status for post_id %d, client_post_id %d",[rs intForColumn:@"post_id"],[rs intForColumn:@"client_post_id"]);
            
            NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSNumber *status = [NSNumber numberWithInt:[rs intForColumn:@"status"]];
            
            NSDictionary *postList = @{@"PostId":postId,@"ActionStatus":status};
            
            [posts addObject:postList];
        }
        
        if(posts.count == 0)
        {
            if(thisSelf == YES)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostFromSelf:YES];
                });
            }
            
            return;
        }
        
        NSDictionary *dict = @{@"postList":posts};
        
        DDLogVerbose(@"post to update %@",[myDatabase toJsonString:dict]);
        
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_update_post_status] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            NSDictionary *dict = (NSDictionary *) responseObject;
            NSArray *dictArr   = (NSArray *)[dict objectForKey:@"AckPostObj"];
            
            for (int i = 0 ; i < dictArr.count; i ++) {
                NSDictionary *postAck = [dictArr objectAtIndex:i];
                
                NSNumber *postId = [NSNumber numberWithInt:[[postAck valueForKey:@"PostId"] intValue]];
                NSString *error = [postAck valueForKey:@"ErrorMessage"];
                NSNumber *statusWasUpdatedNo = [NSNumber numberWithBool:NO];
                
                if([error isEqualToString:@"Successful"] == YES)
                {
                    BOOL upPostStat = [db executeUpdate:@"update post set statusWasUpdated = ? where post_id = ?",statusWasUpdatedNo,postId];
                    
                    if(!upPostStat)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
                if(thisSelf)
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self uploadPostFromSelf:YES];
                    });
                }

            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostFromSelf:YES];
                });
            }
            
        }];
        
    }];
}

#pragma mark - upload new data to server

- (void)uploadPostFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    if([syncKickstartTimerOutgoing isValid])
        [syncKickstartTimerOutgoing invalidate]; //init is done, no need for timer. post, comment and image will recurse automatically.
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = YES;
        //get the posts need to be uploaded
        
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
                                   @"IsUpdated":[NSNumber numberWithBool:NO],
                                   @"PostGroup": [NSNumber numberWithInt:[rs intForColumn:@"contract_type"]]
                                   };
            
            
            [rsArray addObject:dict];
            
            dict = nil;
        }
        
        DDLogVerbose(@"postsToSend %@",rsArray);
        
        if(rsArray.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadImageFromSelf:YES];
                });
                return;
            }
        }
        
        
        NSMutableArray *postListArray     = [[NSMutableArray alloc] init];
        NSMutableDictionary *postListDict = [[NSMutableDictionary alloc] init];
        
        for (int i = 0; i < rsArray.count; i++) {
            NSDictionary *dict = [rsArray objectAtIndex:i];
            
            [postListArray addObject:dict];
            
            dict = nil;
        }
        
        [postListDict setObject:postListArray forKey:@"postList"];
        
        if(postListArray.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadImageFromSelf:YES];
                });
                return;
            }
        }
        
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_post_send] parameters:postListDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            NSDictionary *dict = (NSDictionary *)responseObject;
            DDLogVerbose(@"uploadPost Ack %@",dict);
            NSArray *arr = [dict objectForKey:@"AckPostObj"];
            
            for (int i = 0; i < arr.count; i++) {
                
                NSDictionary *dict = [arr objectAtIndex:i];
                
                NSNumber *clientPostId = [dict valueForKey:@"ClientPostId"];
                NSNumber *postId = [dict valueForKey:@"PostId"];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    
                    [theDb  executeUpdate:@"update post set post_id = ? where client_post_id = ?",postId, clientPostId];
                    
                    BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_id = ? where client_post_id = ?",postId, clientPostId];
                    
                    if(!qPostImage)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    BOOL qComment = [theDb executeUpdate:@"update comment set post_id = ? where client_post_id = ?",postId, clientPostId];
                    
                    if(!qComment)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    
                    BOOL qFeedBackIssue = [theDb executeUpdate:@"update su_feedback_issue set post_id = ? where client_post_id = ?",postId, clientPostId];
                    if(!qFeedBackIssue)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                    {
                        //update the status of this survey so we can upload it
                        FMResultSet *rsGetIssueFeedBackIssueDets = [db executeQuery:@"select client_feedback_id from su_feedback_issue where post_id = ?",postId];
                        NSNumber *clientSurveyIdForThisPost;
                        
                        while ([rsGetIssueFeedBackIssueDets next]) {
                            FMResultSet *rsGetFeedBackDets = [db executeQuery:@"select client_survey_id from su_feedback where client_feedback_id = ?",[NSNumber numberWithInt:[rsGetIssueFeedBackIssueDets intForColumn:@"client_feedback_id"]]];
                            
                            while ([rsGetFeedBackDets next]) {
                                clientSurveyIdForThisPost = [NSNumber numberWithInt:[rsGetFeedBackDets intForColumn:@"client_survey_id"]];
                            }
                        }
                        
                        BOOL upSurvey = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ?",[NSNumber numberWithInt:1],clientSurveyIdForThisPost];
                        
                        if(!upSurvey)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }];
            }
            
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadImageFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadImageFromSelf:YES];
                });
            }
        }];
    }];
}


- (void)uploadCommentFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    NSNumber *zero = [NSNumber numberWithInt:0];

    NSMutableArray *commentListArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *commentListDict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //update comment and post relationship first
        FMResultSet *rsComment = [db executeQuery:@"select * from comment where post_id is null or post_id = ? and comment order by comment_on asc",zero];
        
        while ([rsComment next]) {
            
            NSNumber *comment_client_post_id = [NSNumber numberWithInt:[rsComment intForColumn:@"client_post_id"]];
            
            FMResultSet *rsPost = [db executeQuery:@"select * from post where client_post_id = ?",comment_client_post_id];
            
            while ([rsPost next]) {
                NSNumber *post_client_id = [NSNumber numberWithInt:[rsPost intForColumn:@"post_id"]];
                
                BOOL commentUpQ = [db executeUpdate:@"update comment set post_id = ? where client_post_id = ?",post_client_id,comment_client_post_id];
                
                if(!commentUpQ)
                {
                    *rollback = YES;
                    return;
                }
            }
        }
        
        FMResultSet *rs = [db executeQuery:@"select * from comment where comment_id  is null or comment_id = ? order by comment_on asc",zero];
        
        while ([rs next]) {
            NSNumber *ClientCommentId = [NSNumber numberWithInt:[rs intForColumn:@"client_comment_id"]];
            NSNumber *postId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSString *CommentString = [rs stringForColumn:@"comment"];
            NSString *CommentBy = [rs stringForColumn:@"comment_by"];
            NSString *CommentType = [rs stringForColumn:@"comment_type"];
            
            NSDictionary *dict = @{ @"ClientCommentId": ClientCommentId , @"PostId" : postId ,@"CommentString" : CommentString , @"CommentBy" : CommentBy , @"CommentType" : CommentType};
            
            [commentListArray addObject:dict];
            
            dict = nil;
        }
        
        [commentListDict setObject:commentListArray forKey:@"commentList"];
        
        NSDictionary *dict = commentListDict;
        
        DDLogVerbose(@"commentsToSend %@",dict);
        NSArray *commentList = [dict objectForKey:@"commentList"];
        if(commentList.count == 0)
        {
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostStatusChangeFromSelf:YES];
                });
                
                return;
            }
        }
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_comment_send] parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            NSArray *arr = [responseObject objectForKey:@"AckCommentObj"];
            
            DDLogVerbose(@"uploadComment Ack %@",responseObject);
            
            for(int i = 0; i < arr.count; i++)
            {
                NSDictionary *dict = [arr objectAtIndex:i];
                
                NSNumber *clientCommentId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientCommentId"] intValue]];
                NSNumber *commentId = [NSNumber numberWithInt:[[dict valueForKey:@"CommentId"] intValue]];
                
                BOOL qComment = [db executeUpdate:@"update comment set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qComment)
                {
                    *rollback = YES;
                    return;
                }
                
                BOOL qCommentImage = [db executeUpdate:@"update post_image set comment_id = ? where client_comment_id = ?",commentId,clientCommentId];
                if(!qCommentImage)
                {
                    *rollback = YES;
                    return;
                }
                
            }
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadPostStatusChangeFromSelf:YES];
                    
                    [self uploadCommentNotiAlreadyReadFromSelf:YES];
                });
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    
                    [self uploadCommentNotiAlreadyReadFromSelf:YES];
                });
            }
        }];
    }];
}

- (void)uploadCommentNotiAlreadyReadFromSelf:(BOOL)thisSelf
{
    NSMutableArray *posts = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *commentNotiUp = [db executeQuery:@"select * from comment_noti where status = ? and uploaded = ?",[NSNumber numberWithInt:2],[NSNumber numberWithBool:NO]];
        
        while ([commentNotiUp next]) {
            NSNumber *postId = [NSNumber numberWithInt:[commentNotiUp intForColumn:@"post_id"]];
            NSNumber *commentId = [NSNumber numberWithInt:[commentNotiUp intForColumn:@"comment_id"]];
            NSString *userId = [commentNotiUp stringForColumn:@"user_id"];
            NSNumber *status = [NSNumber numberWithInt:2];
            
            NSDictionary *rows = [NSDictionary dictionaryWithObjectsAndKeys:postId,@"PostId",commentId,@"CommentId",userId,@"UserId",status,@"Status", nil];
            
            [posts addObject:rows];
            
            rows = nil;
        }
    }];
        
    NSDictionary *params = @{@"commentNotiList":posts};
    DDLogVerbose(@"comment noti to upload: %@",params);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *AckCommentNotiObj = (NSDictionary *)responseObject;
       
        NSArray *postsAckArray = [AckCommentNotiObj objectForKey:@"AckCommentNotiObj"];
        
        for (int i = 0; i < postsAckArray.count; i++) {
            NSDictionary *ackDict   = (NSDictionary *)[postsAckArray objectAtIndex:i];
            NSNumber *CommentId     = [NSNumber numberWithInt:[[ackDict valueForKey:@"CommentId"] intValue]];
            NSNumber *PostId        = [NSNumber numberWithInt:[[ackDict valueForKey:@"PostId"] intValue]];
            NSString *UserId        = [ackDict valueForKey:@"UserId"];
            BOOL IsSuccessful       = [[ackDict valueForKey:@"IsSuccessful"] boolValue];
            
            if(IsSuccessful)
            {
                [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    BOOL up = [db executeUpdate:@"update comment_noti set uploaded = ? where post_id = ? and comment_id = ? and user_id = ?",[NSNumber numberWithBool:YES],PostId,CommentId,UserId];
                    
                    if(!up)
                    {
                        *rollback = YES;
                        return;
                    }
                }];
            }
        }
        
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadPostStatusChangeFromSelf:YES];
            });
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadPostStatusChangeFromSelf:YES];
            });
        }
    }];
    
}


- (void)uploadImageFromSelf:(BOOL )thisSelf
{
    if(myDatabase.initializingComplete == NO)
        return;
    
    __block NSMutableDictionary *imagesDict = [[NSMutableDictionary alloc] init];
    
    __block NSMutableArray *imagesInDb = [[NSMutableArray alloc] init];
    
    //get images to send!
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"select * from post_image where post_image_id is null or post_image_id = ?",[NSNumber numberWithInt:0]];

        while ([rs next]) {
            NSNumber *ImageType = [NSNumber numberWithInt:[rs intForColumn:@"image_type"]];
            NSNumber *CilentPostImageId = [NSNumber numberWithInt:[rs intForColumn:@"client_post_image_id"]];
            NSNumber *PostId = [NSNumber numberWithInt:[rs intForColumn:@"post_id"]];
            NSNumber *CommentId = [NSNumber numberWithInt:[rs intForColumn:@"comment_id"]];
            NSString *CreatedBy = [myDatabase.userDictionary valueForKey:@"user_id"];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:[rs stringForColumn:@"image_path"]];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            if([fileManager fileExistsAtPath:filePath] == NO) //file does not exist
                continue ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            NSString *imageString = [imageData base64EncodedStringWithSeparateLines:NO];
            
            if([ImageType intValue] == 1)//post image
            {
                CommentId = [NSNumber numberWithInt:0];
            }
            else if([ImageType intValue] == 2)
            {
                PostId = [NSNumber numberWithInt:0];
            }
            
            
            NSDictionary *dict = @{@"CilentPostImageId":CilentPostImageId,@"PostId":PostId,@"CommentId":CommentId,@"CreatedBy":CreatedBy,@"ImageType":ImageType,@"Image":imageString};
            
            [imagesInDb addObject:dict];
        }
        [imagesDict setObject:imagesInDb forKey:@"postImageList"];
    }];
    
    
    if(imagesDict == nil)
    {
        imagesInDb = nil;
        
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadCommentFromSelf:YES];
            });
            return;
        }
        
    }
    
    NSArray *imagesArray_temp = [imagesDict objectForKey:@"postImageList"];
    DDLogVerbose(@"images to send %lu",(unsigned long)imagesArray_temp.count);
    if (imagesArray_temp.count == 0) {
        
        imagesInDb = nil;

        if(thisSelf)
        {
                                                                // call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
            return;
        }
    }
    imagesArray_temp = nil;
    
    //send images
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_send_images] parameters:imagesDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        imagesInDb = nil;
        
        NSArray *arr = [responseObject objectForKey:@"AckPostImageObj"];
        
        DDLogVerbose(@"uploadImage Ack %@",arr);
        
        for (int i = 0; i < arr.count; i++) {
            NSDictionary *dict = [arr objectAtIndex:i];
            
            NSNumber *ClientPostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientPostImageId"] intValue]];
            NSNumber *PostImageId = [NSNumber numberWithInt:[[dict valueForKey:@"PostImageId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                BOOL qPostImage = [theDb executeUpdate:@"update post_image set post_image_id = ?, uploaded = ? where client_post_image_id = ?  ",PostImageId,@"YES",ClientPostImageId];
                
                if(!qPostImage)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        if(thisSelf)
        {
                                                                    //call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        imagesInDb = nil;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);

        if(thisSelf)
        {
                                                                    //call this faster
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadInspectionResultFromSelf:YES];
            });
        }
    }];
}


#pragma mark - upload inspection result
- (void)uploadInspectionResultFromSelf:(BOOL)thisSelf
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSNumber *requiredSync = [NSNumber numberWithInt:1];
        
        FMResultSet *rs = [db executeQuery:@"select * from ro_inspectionresult where w_required_sync = ? limit 1,10",requiredSync];
        NSMutableArray *inspArr = [[NSMutableArray alloc] init];
        
        while ([rs next]) {

            NSNumber *ScheduleId = [NSNumber numberWithInt:[rs intForColumn:@"w_scheduleid"]];
            NSNumber *CheckListId = [NSNumber numberWithInt:[rs intForColumn:@"w_checklistid"]];
            NSNumber *ChkAreaId = [NSNumber numberWithInt:[rs intForColumn:@"w_chkareaid"]];
            NSString *ReportBy = [rs stringForColumn:@"w_reportby"];
            NSNumber *Checked = [NSNumber numberWithInt:[rs intForColumn:@"w_checked"]];
            NSNumber *SPOChecked = [NSNumber numberWithInt:[rs intForColumn:@"w_spochecked"]];
            
            NSDictionary *dict = @{ @"ScheduleId" : ScheduleId , @"CheckListId": CheckListId , @"ChkAreaId" : ChkAreaId, @"ReportBy" : ReportBy, @"Checked" :  Checked , @"SPOChecked" : SPOChecked};
            
            [inspArr addObject:dict];
        }
        
        NSDictionary *inspDict = @{@"inspectionResultList":inspArr};
        DDLogVerbose(@"inspectionResultList to send %@",[myDatabase toJsonString:inspDict]);
       [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_inspection_res] parameters:inspDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
           if(stop)return;
           
           NSDictionary *topDict = (NSDictionary *)responseObject;
           
           NSArray *AckInspectionResultObj = [topDict objectForKey:@"AckInspectionResultObj"];
           
           DDLogVerbose(@"AckInspectionResultObj %@",AckInspectionResultObj);
           
           for (int i = 0; i < AckInspectionResultObj.count; i++) {
               NSDictionary *dict = [AckInspectionResultObj objectAtIndex:i];
               
               NSNumber *CheckListId = [NSNumber numberWithInt:[[dict valueForKey:@"CheckListId"] intValue]];
               NSNumber *ChkAreaId = [NSNumber numberWithInt:[[dict valueForKey:@"ChkAreaId"] intValue]];
               NSNumber *ScheduleId = [NSNumber numberWithInt:[[dict valueForKey:@"ScheduleId"] intValue]];
               BOOL Successful = [[dict valueForKey:@"Successful"] boolValue];
               
               if(Successful)
               {
                   NSNumber *syncNotRequired = [NSNumber numberWithInt:0];
                   BOOL up = [db executeUpdate:@"update ro_inspectionresult set w_required_sync = ? where w_checklistid = ? and w_chkareaid = ? and w_scheduleid = ?",syncNotRequired,CheckListId,ChkAreaId,ScheduleId];
                   
                   if(!up)
                   {
                       *rollback = YES;
                       return;
                   }
               }
           }
           
           if(thisSelf)
           {
                                                                        // call this faster
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   [self uploadSurveyFromSelf:YES];
               });
           }
           
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           if(stop)return;
           
           DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
           
           if(thisSelf)
           {
                                                                        // call this faster
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   [self uploadSurveyFromSelf:YES];
               });
           }
       }];
        
    }];
}


#pragma mark - upload survey
- (void)uploadSurveyFromSelf:(BOOL)thisSelf
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSMutableDictionary *surveyDict = [[NSMutableDictionary alloc] init];
        NSDictionary *surveyContainer;
        
        BOOL doUpload = NO;

        FMResultSet *rsSurvey = [db executeQuery:@"select * from su_survey where status = ? order by survey_date desc limit 0, 1",[NSNumber numberWithInt:1]];
        
        while ([rsSurvey next]) {
            doUpload = YES;
            
            int ClientSurveyId = [rsSurvey intForColumn:@"client_survey_id"];
            int ClientSurveyAddressId = [rsSurvey intForColumn:@"client_survey_address_id"];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
            NSDate *surveyNsDate = [rsSurvey dateForColumn:@"survey_date"];
            NSString *surveyDateJsonString = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [surveyNsDate timeIntervalSince1970],[formatter stringFromDate:surveyNsDate]];
            
            NSString *ResidentName = [rsSurvey stringForColumn:@"resident_name"] ? [rsSurvey stringForColumn:@"resident_name"] : @"";
            NSString *ResidentAgeRange = [rsSurvey stringForColumn:@"resident_age_range"] ? [rsSurvey stringForColumn:@"resident_age_range"] : @"";
            NSString *ResidentGender = [rsSurvey stringForColumn:@"resident_gender"] ? [rsSurvey stringForColumn:@"resident_gender"] : @"";
            NSString *ResidentRace = [rsSurvey stringForColumn:@"resident_race"] ? [rsSurvey stringForColumn:@"resident_race"] : @"";
            int ClientResidentAddressId = [rsSurvey intForColumn:@"client_resident_address_id"];
            NSString *ResidentContact = [rsSurvey stringForColumn:@"resident_contact"] ? [rsSurvey stringForColumn:@"resident_contact"] : @"" ;
            NSString *Resident2ndContact = [rsSurvey stringForColumn:@"other_contact"] ? [rsSurvey stringForColumn:@"other_contact"] : @"" ;
            NSString *ResidentEmail = [rsSurvey stringForColumn:@"resident_email"] ? [rsSurvey stringForColumn:@"resident_email"] : @"" ;
            NSNumber *DataProtection = [NSNumber numberWithInt:[rsSurvey intForColumn:@"data_protection"]];
            
            [surveyDict setObject:[NSNumber numberWithInt:ClientSurveyId] forKey:@"ClientSurveyId"];
            [surveyDict setObject:[NSNumber numberWithInt:ClientSurveyAddressId] forKey:@"ClientSurveyAddressId"];
            [surveyDict setObject:surveyDateJsonString forKey:@"SurveyDate"];
            [surveyDict setObject:ResidentName forKey:@"ResidentName"];
            [surveyDict setObject:ResidentAgeRange forKey:@"ResidentAgeRange"];
            [surveyDict setObject:ResidentGender forKey:@"ResidentGender"];
            [surveyDict setObject:ResidentRace forKey:@"ResidentRace"];
            [surveyDict setObject:[NSNumber numberWithInt:ClientResidentAddressId] forKey:@"ClientResidentAddressId"];
            [surveyDict setObject:ResidentContact forKey:@"ResidentContact"];
            [surveyDict setObject:Resident2ndContact forKey:@"Resident2ndContact"];
            [surveyDict setObject:ResidentEmail forKey:@"ResidentEmail"];
            [surveyDict setObject:DataProtection forKey:@"DataProtection"];
            
            
            //get answers list
            FMResultSet *rsAnswers = [db executeQuery:@"select * from su_answers where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *answersArray = [[NSMutableArray alloc] init];
            while ([rsAnswers next]) {
                NSNumber *ClientAnswerId = [NSNumber numberWithInt:[rsAnswers intForColumn:@"client_answer_id"]];
                NSNumber *QuestionId = [NSNumber numberWithInt:[rsAnswers intForColumn:@"question_id"]];
                NSNumber *Rating = [NSNumber numberWithInt:[rsAnswers intForColumn:@"rating"]];
                
                NSDictionary *dictRowAnswers = @{@"ClientAnswerId":ClientAnswerId,@"QuestionId":QuestionId,@"Rating":Rating};
                
                [answersArray addObject:dictRowAnswers];
            }
            
            [surveyDict setObject:answersArray forKey:@"AnswerList"];
            
            
            //get feedbacks issue
            FMResultSet *rsFeedbackIssuesList = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *rsfiArr = [[NSMutableArray alloc] init];
            while ([rsFeedbackIssuesList next]) {
                NSNumber *client_feedback_id = [NSNumber numberWithInt:[rsFeedbackIssuesList intForColumn:@"client_feedback_id"]];
                
                //get su_feedback_issue
                FMResultSet *rsFI = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ?",client_feedback_id];

                while ([rsFI next]) {
                    NSNumber *ClientFeedbackIssueId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_feedback_issue_id"]];
                    NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_feedback_id"]];
                    
                    NSNumber *PostId = [NSNumber numberWithInt:[rsFI intForColumn:@"post_id"]];
                    NSNumber *ClientPostId = [NSNumber numberWithInt:[rsFI intForColumn:@"client_post_id"]];
                    
                    if([ClientPostId intValue] > 0 && [PostId intValue] == 0) //this post was not yet uploaded, don't upload this survey
                    {
                        doUpload = NO;
                        continue;
                    }
                    
                    NSString *IssueDes = [rsFI stringForColumn:@"issue_des"];
                    NSNumber *AutoAssignMe = [NSNumber numberWithBool:[rsFI boolForColumn:@"auto_assignme"]];
                    
                    NSDictionary *rsFIDict = @{@"ClientFeedbackIssueId":ClientFeedbackIssueId,@"ClientFeedbackId":ClientFeedbackId,@"PostId":PostId,@"IssueDes":IssueDes,@"AutoAssignMe":AutoAssignMe};
                    
                    [rsfiArr addObject:rsFIDict];
                }
            }
            
            [surveyDict setObject:rsfiArr forKey:@"FeedbackIssueList"];
            
            //get address
            NSMutableArray *addressArray = [[NSMutableArray alloc] init];
            
            //get the addresses base on survey address
            FMResultSet *rsAddressSurvey = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:ClientSurveyAddressId]];
            
            while ([rsAddressSurvey next]) {
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddressSurvey intForColumn:@"client_address_id"]];
                NSString *Location = [rsAddressSurvey stringForColumn:@"address"] ? [rsAddressSurvey stringForColumn:@"address"] : @"";
                NSString *UnitNo = [rsAddressSurvey stringForColumn:@"unit_no"] ? [rsAddressSurvey stringForColumn:@"unit_no"] : @"";
                NSString *SpecifyArea = [rsAddressSurvey stringForColumn:@"specify_area"] ? [rsAddressSurvey stringForColumn:@"specify_area"] : @"";
                NSString *PostalCode = [rsAddressSurvey stringForColumn:@"postal_code"] ? [rsAddressSurvey stringForColumn:@"postal_code"] : @"0";
                NSNumber *BlkId = [NSNumber numberWithInt:[rsAddressSurvey intForColumn:@"block_id"]];
                
                NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                
                [addressArray addObject:dictAddSurvey];
            }
            
            //get the addresses base on resident address
            FMResultSet *rsAddressSurvey2 = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:ClientResidentAddressId]];
            
            while ([rsAddressSurvey2 next]) {
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddressSurvey2 intForColumn:@"client_address_id"]];
                NSString *Location = [rsAddressSurvey2 stringForColumn:@"address"] ? [rsAddressSurvey2 stringForColumn:@"address"] : @"";
                NSString *UnitNo = [rsAddressSurvey2 stringForColumn:@"unit_no"] ? [rsAddressSurvey2 stringForColumn:@"unit_no"] : @"";
                NSString *SpecifyArea = [rsAddressSurvey2 stringForColumn:@"specify_area"] ? [rsAddressSurvey2 stringForColumn:@"specify_area"] : @"";
                NSString *PostalCode = [rsAddressSurvey2 stringForColumn:@"postal_code"] ? [rsAddressSurvey2 stringForColumn:@"postal_code"] : @"0";
                NSNumber *BlkId = [NSNumber numberWithInt:[rsAddressSurvey2 intForColumn:@"block_id"]];
                
                NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                
                [addressArray addObject:dictAddSurvey];
            }
            
            
            //get the addresses based on feedback
            FMResultSet *rsAddressFeedback = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            while ([rsAddressFeedback next]) {
                NSNumber *client_address_id = [NSNumber numberWithInt:[rsAddressFeedback intForColumn:@"client_address_id"]];
                
                FMResultSet *rsAddFeedBack = [db executeQuery:@"select * from su_address where client_address_id = ?",client_address_id];
                
                while ([rsAddFeedBack next]) {
                    NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddFeedBack intForColumn:@"client_address_id"]];
                    NSString *Location = [rsAddFeedBack stringForColumn:@"address"] ? [rsAddFeedBack stringForColumn:@"address"] : @"";
                    NSString *UnitNo = [rsAddFeedBack stringForColumn:@"unit_no"] ? [rsAddFeedBack stringForColumn:@"unit_no"] : @"";
                    NSString *SpecifyArea = [rsAddFeedBack stringForColumn:@"specify_area"] ? [rsAddFeedBack stringForColumn:@"specify_area"] : @"";
                    NSString *PostalCode = [rsAddFeedBack stringForColumn:@"postal_code"] ? [rsAddFeedBack stringForColumn:@"postal_code"] : @"0";
                    NSNumber *BlkId = [NSNumber numberWithInt:[rsAddFeedBack intForColumn:@"block_id"]];
                    
                    NSDictionary *dictAddSurvey = @{@"ClientAddressId":ClientAddressId,@"Location":Location,@"UnitNo":UnitNo,@"SpecifyArea":SpecifyArea,@"PostalCode":PostalCode,@"BlkId":BlkId};
                    
                    [addressArray addObject:dictAddSurvey];
                }
            }
            
            [surveyDict setObject:addressArray forKey:@"AddressList"];
            
            
            //get feedback
            FMResultSet *rsFeedBack = [db executeQuery:@"select * from su_feedback where client_survey_id = ?",[NSNumber numberWithInt:ClientSurveyId]];
            NSMutableArray *feedBackArray = [[NSMutableArray alloc] init];
            
            while ([rsFeedBack next]) {
                NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[rsFeedBack intForColumn:@"client_feedback_id"]];
                NSString *Description = [rsFeedBack stringForColumn:@"description"];
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsFeedBack intForColumn:@"client_address_id"]];
                
                NSDictionary *dictFeedRow = @{@"ClientFeedbackId":ClientFeedbackId,@"Description":Description,@"ClientAddressId":ClientAddressId};
                
                [feedBackArray addObject:dictFeedRow];
            }
            
            [surveyDict setObject:feedBackArray forKey:@"FeedbackList"];
            
            surveyContainer = @{@"surveyContainer":surveyDict};
            

            
        } //end of while ([rsSurvey next])
        
        if(doUpload == NO)
        {
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
            }
            
            return;
        }
        
        DDLogVerbose(@"surveyContainer %@",[myDatabase toJsonString:surveyContainer]);
        DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
        DDLogVerbose(@"%@%@",myDatabase.api_url,api_upload_survey);
        
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_survey] parameters:surveyContainer success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if(stop)return;
            
            NSDictionary *topDict = (NSDictionary *)responseObject;
            
            NSDictionary *AckSurveyContainer = [topDict objectForKey:@"AckSurveyContainer"];
            DDLogVerbose(@"AckSurveyContainer %@",AckSurveyContainer);
            
            NSArray *AckAddressList = [AckSurveyContainer objectForKey:@"AckAddressList"];
            NSArray *AckAnswerList = [AckSurveyContainer objectForKey:@"AckAnswerList"];
            NSArray *AckFeedbackIssueList = [AckSurveyContainer objectForKey:@"AckFeedbackIssueList"];
            NSArray *AckFeedbackList = [AckSurveyContainer objectForKey:@"AckFeedbackList"];
            
            NSNumber *ClientSurveyId = [NSNumber numberWithInt:[[AckSurveyContainer valueForKey:@"ClientSurveyId"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[AckSurveyContainer valueForKey:@"SurveyId"] intValue]];
            
            BOOL massUpdateOk = YES;
            
            //update survey
            BOOL upSurvey = [db executeUpdate:@"update su_survey set survey_id = ? where client_survey_id = ?",SurveyId,ClientSurveyId];
            if(!upSurvey)
            {
                *rollback = YES;
                return;
            }
            
            //update answers
            for (int i = 0; i < AckAnswerList.count; i++) {
                NSNumber *AnswerId = [NSNumber numberWithInt:[[[AckAnswerList objectAtIndex:i] valueForKey:@"AnswerId"] intValue]];
                NSNumber *ClientAnswerId = [NSNumber numberWithInt:[[[AckAnswerList objectAtIndex:i] valueForKey:@"ClientAnswerId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_answers set answer_id = ?, survey_id = ? where client_answer_id = ?",AnswerId,SurveyId,ClientAnswerId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
            }
            
            
            //update address
            for (int i = 0; i < AckAddressList.count; i++) {
                NSNumber *AddressId = [NSNumber numberWithInt:[[[AckAddressList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[[[AckAddressList objectAtIndex:i] valueForKey:@"ClientAddressId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_address set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];
                

                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
                
                //update survey_address_id and resident_address_id
                BOOL upSuAdds = [db executeUpdate:@"update su_survey set survey_address_id = ? where client_survey_address_id = ?",AddressId,ClientAddressId];
                BOOL upSuAdds2 = [db executeUpdate:@"update su_survey set resident_address_id = ? where client_resident_address_id = ?",AddressId,ClientAddressId];
                
                
                //update feedback address_id
                BOOL feedAddId = [db executeUpdate:@"update su_feedback set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];
            }
            
            
            //update AckFeedbackIssueList
            for (int i = 0; i < AckFeedbackIssueList.count; i++) {

                NSNumber *ClientFeedbackIssueId = [NSNumber numberWithInt:[[[AckFeedbackIssueList objectAtIndex:i] valueForKey:@"ClientFeedbackIssueId"] intValue]];
                NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[[AckFeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackIssueId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_feedback_issue set feedback_issue_id = ? where client_feedback_issue_id = ?",FeedbackIssueId,ClientFeedbackIssueId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
            }
            
            
            //update AckFeedbackList
            for (int i = 0; i < AckFeedbackList.count; i++) {
                NSNumber *ClientFeedbackId = [NSNumber numberWithInt:[[[AckFeedbackList objectAtIndex:i] valueForKey:@"ClientFeedbackId"] intValue]];
                NSNumber *FeedbackId = [NSNumber numberWithInt:[[[AckFeedbackList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
                BOOL upAns = [db executeUpdate:@"update su_feedback set feedback_id = ?, survey_id = ? where client_feedback_id = ?",FeedbackId,SurveyId,ClientFeedbackId];
                if(!upAns)
                {
                    *rollback = YES;
                    massUpdateOk = NO;
                    return;
                }
                
                //update feedback_issue
                BOOL upFbI = [db executeUpdate:@"update su_feedback_issue set feedback_id = ? where client_feedback_id = ?",FeedbackId,ClientFeedbackId];

                if(!upFbI)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            if(massUpdateOk == YES)
            {
                BOOL upSurveySync = [db executeUpdate:@"update su_survey set status = ? where client_survey_id = ?",[NSNumber numberWithInt:0],ClientSurveyId];
                if(!upSurveySync)
                {
                    *rollback = YES;
                    return;
                }
            }
            
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(stop)return;
            
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            if(thisSelf)
            {
                // call this faster
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadCommentFromSelf:YES];
                });
            }
        }];
        
    }];
}

#pragma mark - upload resident info edit
- (void)uploadResidentInfoEditForSurveyId:(NSNumber *)surveyId
{
    NSMutableDictionary *surveyContainer = [[NSMutableDictionary alloc] init];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        
        NSMutableArray *addressArray = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            NSNumber *SurveyId = [NSNumber numberWithInt:[rs intForColumn:@"survey_id"]];
            NSString *ResidentName = [rs stringForColumn:@"resident_name"] ? [rs stringForColumn:@"resident_name"] : @"";
            NSString *ResidentAgeRange = [rs stringForColumn:@"resident_age_range"] ? [rs stringForColumn:@"resident_age_range"] : @"";
            NSString *ResidentGender = [rs stringForColumn:@"resident_gender"] ? [rs stringForColumn:@"resident_gender"] : @"";
            NSString *ResidentRace = [rs stringForColumn:@"resident_race"] ? [rs stringForColumn:@"resident_race"] : @"";
            NSString *ResidentContact = [rs stringForColumn:@"resident_contact"] ? [rs stringForColumn:@"resident_contact"] : @"";
            NSString *Resident2ndContact = [rs stringForColumn:@"other_contact"] ? [rs stringForColumn:@"other_contact"] : @"";
            NSString *ResidentEmail = [rs stringForColumn:@"resident_email"] ? [rs stringForColumn:@"resident_email"] : @"";
            NSNumber *ClientResidentAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_resident_address_id"]];
            NSNumber *ResidentAddressId = [NSNumber numberWithInt:[rs intForColumn:@"resident_address_id"]];
            
            
            [surveyContainer setObject:SurveyId forKey:@"SurveyId"];
            [surveyContainer setObject:ResidentName forKey:@"ResidentName"];
            [surveyContainer setObject:ResidentAgeRange forKey:@"ResidentAgeRange"];
            [surveyContainer setObject:ResidentGender forKey:@"ResidentGender"];
            [surveyContainer setObject:ResidentRace forKey:@"ResidentRace"];
            [surveyContainer setObject:ResidentContact forKey:@"ResidentContact"];
            [surveyContainer setObject:Resident2ndContact forKey:@"Resident2ndContact"];
            [surveyContainer setObject:ResidentEmail forKey:@"ResidentEmail"];
            [surveyContainer setObject:ClientResidentAddressId forKey:@"ClientResidentAddressId"];
            [surveyContainer setObject:ResidentAddressId forKey:@"ResidentAddressId"];
            
            
            //get address
            FMResultSet *rsAddres = [db executeQuery:@"select * from su_address where client_address_id = ?",ClientResidentAddressId];
            
            while ([rsAddres next]) {
                NSNumber *ClientAddressId = [NSNumber numberWithInt:[rsAddres intForColumn:@"client_address_id"]];
                NSNumber *AddressId = [NSNumber numberWithInt:[rsAddres intForColumn:@"address_id"]];
                NSString *Location = [rsAddres stringForColumn:@"address"];
                NSString *UnitNo = [rsAddres stringForColumn:@"unit_no"];
                NSString *SpecifyArea = [rsAddres stringForColumn:@"specify_area"];
                NSString *PostalCode = [rsAddres stringForColumn:@"postal_code"];
                
                NSDictionary *dictAd = @{@"ClientAddressId" : ClientAddressId, @"AddressId" : AddressId, @"Location" : Location , @"UnitNo" : UnitNo , @"SpecifyArea" : SpecifyArea, @"PostalCode": PostalCode };
                
                [addressArray addObject:dictAd];
            }
            
            [surveyContainer setObject:addressArray forKey:@"AddressList"];
        }
    }];
    

    NSDictionary *surveyDict = @{@"surveyContainer" : surveyContainer};
    
    DDLogVerbose(@"surveyContainer %@",[myDatabase toJsonString:surveyDict]);
    DDLogVerbose(@"guid %@",[myDatabase.userDictionary valueForKey:@"guid"]);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_upload_resident_info_edit] parameters:surveyDict success:^(AFHTTPRequestOperation *operation, id responseObject) {

        
        NSDictionary *topDict = (NSDictionary *)responseObject;
        
        NSArray *AckAddress = [topDict objectForKey:@"AckAddress"];
        
        for (int i = 0; i < AckAddress.count; i++) {
            NSDictionary *dict = [AckAddress objectAtIndex:i];
            NSNumber *AddressId = [NSNumber numberWithInt:[[dict valueForKey:@"AddressId"] intValue]];
            NSNumber *ClientAddressId = [NSNumber numberWithInt:[[dict valueForKey:@"ClientAddressId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                BOOL upAddId;
                
                if([ClientAddressId intValue] > 0)
                    upAddId = [db executeUpdate:@"update su_address set address_id = ? where client_address_id = ?",AddressId,ClientAddressId];

                if(!upAddId)
                {
                    *rollback = YES;
                    return;
                }
            }];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DDLogVerbose(@"%@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
    }];
}

- (void)startDownloadQuestionsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    __block Questions *questions = [[Questions alloc] init];
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"startDownloadQuestionsForPage %@",[myDatabase toJsonString:params]);
    DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"QuestionContainer"];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [dict valueForKey:@"LastRequestDate"];
        
        NSArray *dictArray = [dict objectForKey:@"QuestionList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictList = [dictArray objectAtIndex:i];
            NSString *CNQuestion = [dictList valueForKey:@"CNQuestion"];
            NSString *ENQuestion = [dictList valueForKey:@"ENQuestion"];
            NSString *INQuestion = [dictList valueForKey:@"INQuestion"];
            NSString *MYQuestion = [dictList valueForKey:@"MYQuestion"];
            NSNumber *QuestionId = [NSNumber numberWithInt:[[dictList valueForKey:@"QuestionId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rs = [theDb executeQuery:@"select question_id from su_questions where question_id = ?",QuestionId];
                
                if([rs next] == NO)//does not exist
                {
                    BOOL ins = [theDb executeUpdate:@"insert into su_questions (cn,en,my,ind,question_id) values (?,?,?,?,?)",CNQuestion,ENQuestion,MYQuestion,INQuestion,QuestionId];
                    
                    if(!ins)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadQuestionsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
                [questions updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - download new data from server
- (void)startDownloadFeedBackIssuesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"Post params %@",[myDatabase toJsonString:params]);
    DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
    DDLogVerbose(@"%@%@",myDatabase.api_url,api_download_feedback_issues);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_feedback_issues] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"FeedbackIssueContainer"];
        
        DDLogVerbose(@"New feedback issues %@",dict);
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"FeedbackIssueList"];

        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictPost = [dictArray objectAtIndex:i];
            
            NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[dictPost valueForKey:@"FeedbackIssueId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictPost valueForKey:@"Status"] intValue]];
            
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select feedback_issue_id from su_feedback_issue where feedback_issue_id = ?",FeedbackIssueId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into su_feedback_issue (feedback_issue_id,status) values (?,?)",FeedbackIssueId,Status];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadFeedBackIssuesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                //update last request date
                NSString *dateString = [dict valueForKey:@"LastRequestDate"];
                NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
                NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
                
                [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                    FMResultSet *rs = [theDb executeQuery:@"select * from su_feedback_issues_last_req_date"];
                    
                    if(![rs next])
                    {
                        BOOL qIns = [theDb executeUpdate:@"insert into su_feedback_issues_last_req_date(date) values(?)",date];
                        
                        if(!qIns)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                    else
                    {
                        BOOL qUp = [theDb executeUpdate:@"update su_feedback_issues_last_req_date set date = ? ",date];
                        
                        if(!qUp)
                        {
                            *rollback = YES;
                            return;
                        }
                    }
                }];
            }
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        DDLogVerbose(@"Post params %@",[myDatabase toJsonString:params]);
        DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
        DDLogVerbose(@"%@%@",myDatabase.api_url,api_download_feedback_issues);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadFeedBackIssuesForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}

#pragma mark - download survey
- (void)startDownloadSurveyPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"survey params %@",[myDatabase toJsonString:params]);
    DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
    DDLogVerbose(@"%@%@",myDatabase.api_url,api_download_survey);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_survey] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"ResturnSurveyContainer"];
        
        DDLogVerbose(@"new survey %@",dict);
        
        //save address
        NSArray *AddressList = [dict objectForKey:@"AddressList"];
        for (int i = 0; i < AddressList.count; i++) {
            NSNumber *AddressId = [NSNumber numberWithInt:[[[AddressList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
            NSNumber *Location = [[AddressList objectAtIndex:i] valueForKey:@"Location"];
            NSString *SpecifyArea = [[AddressList objectAtIndex:i] valueForKey:@"SpecifyArea"];
            NSString *UnitNo = [[AddressList objectAtIndex:i] valueForKey:@"UnitNo"];
            NSString *PostalCode = [[AddressList objectAtIndex:i] valueForKey:@"PostalCode"];
            NSNumber *BlkId = [NSNumber numberWithInt:[[[AddressList objectAtIndex:i] valueForKey:@"BlkId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_address where address_id = ?",AddressId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_address(address_id,address,unit_no,specify_area,postal_code,block_id) values (?,?,?,?,?,?)",AddressId,Location,UnitNo,SpecifyArea,PostalCode,BlkId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save answers
        NSArray *AnswerList = [dict objectForKey:@"AnswerList"];
        for (int i = 0; i < AnswerList.count; i++) {
            NSNumber *AnswerId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"AnswerId"] intValue]];
            NSNumber *QuestionId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"QuestionId"] intValue]];
            NSNumber *Rating = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"Rating"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[AnswerList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_answers where answer_id = ?",AnswerId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_answers(answer_id,question_id,rating,survey_id) values (?,?,?,?)",AnswerId,QuestionId,Rating,SurveyId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save FeedbackIssueList
        NSArray *FeedbackIssueList = [dict objectForKey:@"FeedbackIssueList"];
        for (int i = 0; i < FeedbackIssueList.count; i++) {
            
            NSNumber *FeedbackId = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
            NSNumber *FeedbackIssueId = [NSNumber numberWithInt:[[[FeedbackIssueList objectAtIndex:i] valueForKey:@"FeedbackIssueId"] intValue]];
            NSString *IssueDes = [[FeedbackIssueList objectAtIndex:i] valueForKey:@"IssueDes"];
            
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_feedback_issue where feedback_issue_id = ?",FeedbackIssueId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_feedback_issue(feedback_id,feedback_issue_id,issue_des) values (?,?,?)",FeedbackId,FeedbackIssueId,IssueDes];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        //save FeedbackList
        NSArray *FeedbackList = [dict objectForKey:@"FeedbackList"];
        for (int i = 0; i < FeedbackList.count; i++) {
            
            NSNumber *AddressId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"AddressId"] intValue]];
            NSString *Description = [[FeedbackList objectAtIndex:i] valueForKey:@"Description"];
            NSNumber *FeedbackId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"FeedbackId"] intValue]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[FeedbackList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];

            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_feedback where feedback_id = ?",FeedbackId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_feedback(address_id,description,feedback_id,survey_id) values (?,?,?,?)",AddressId,Description,FeedbackId,SurveyId];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        
        
        //save Survey
        NSArray *SurveyList = [dict objectForKey:@"SurveyList"];
        for (int i = 0; i < SurveyList.count; i++) {
            
            NSNumber *AverageRating = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"AverageRating"] intValue]];
            NSNumber *ResidentAddressId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"AverageRating"] intValue]];
            NSString *ResidentAgeRange = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentAgeRange"];
            NSString *ResidentGender = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentGender"];
            NSString *ResidentName = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentName"];
            NSString *ResidentContact = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentContact"];
            NSString *Resident2ndContact  = [[SurveyList objectAtIndex:i] valueForKey:@"Resident2ndContact"];
            NSString *ResidentEmail = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentEmail"];
            NSString *ResidentRace = [[SurveyList objectAtIndex:i] valueForKey:@"ResidentRace"];
            NSNumber *SurveyAddressId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"SurveyAddressId"] intValue]];
            NSDate *SurveyDate = [myDatabase createNSDateWithWcfDateString:[[SurveyList objectAtIndex:i] valueForKey:@"SurveyDate"]];
            NSNumber *SurveyId = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"SurveyId"] intValue]];
            NSNumber *DataProtection = [NSNumber numberWithInt:[[[SurveyList objectAtIndex:i] valueForKey:@"DataProtection"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                FMResultSet *rsCheck = [db executeQuery:@"select * from su_survey where survey_id = ?",SurveyId];
                
                if([rsCheck next] == NO)
                {
                    BOOL insAdd = [db executeUpdate:@"insert into su_survey(average_rating,resident_address_id,resident_age_range,resident_gender,resident_name,resident_race,survey_address_id,survey_date,survey_id,resident_contact,resident_email,data_protection, other_contact) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",AverageRating,ResidentAddressId,ResidentAgeRange,ResidentGender,ResidentName,ResidentRace,SurveyAddressId,SurveyDate,SurveyId,ResidentContact,ResidentEmail,DataProtection, Resident2ndContact];
                    
                    if(!insAdd)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
        }
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadSurveyPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            
            //update last request date
            NSString *dateString = [dict valueForKey:@"LastRequestDate"];
            NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
            NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rs = [theDb executeQuery:@"select * from su_survey_last_req_date"];
                
                if(![rs next])
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into su_survey_last_req_date(date) values(?)",date];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
                else
                {
                    BOOL qUp = [theDb executeUpdate:@"update su_survey_last_req_date set date = ? ",date];
                    
                    if(!qUp)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];
            
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadSurveyPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        DDLogVerbose(@"Post params %@",[myDatabase toJsonString:params]);
        DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
        DDLogVerbose(@"%@%@",myDatabase.api_url,api_download_survey);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadSurveyPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - download new data from server
- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"Post params %@",params);
    
    __block Post *post = [[Post alloc] init];
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_posts] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"PostContainer"];
        
        DDLogVerbose(@"New Post %@",dict);

        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
            
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];

        //prepare to download the blocks!
        NSArray *dictArray = [dict objectForKey:@"PostList"];

        //local notif vars
        NSString *fromUser;
        NSString *msgFromUser;
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictPost = [dictArray objectAtIndex:i];
            
            NSNumber *ActionStatus = [NSNumber numberWithInt:[[dictPost valueForKey:@"ActionStatus"] intValue]];
            NSString *BlkId = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"BlkId"] intValue]];
            NSString *Level = [dictPost valueForKey:@"Level"];
            NSString *Location = [dictPost valueForKey:@"Location"];
            NSString *PostBy = [dictPost valueForKey:@"PostBy"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictPost valueForKey:@"PostId"] intValue]];
            NSString *PostTopic = [dictPost valueForKey:@"PostTopic"];
            NSString *PostType = [NSString stringWithFormat:@"%d",[[dictPost valueForKey:@"PostType"] intValue]];
            NSString *PostalCode = [dictPost valueForKey:@"PostalCode"];
            NSNumber *Severity = [NSNumber numberWithInt:[[dictPost valueForKey:@"Severity"] intValue]];
            NSDate *PostDate = [myDatabase createNSDateWithWcfDateString:[dictPost valueForKey:@"PostDate"]];
            NSNumber *contractType = [NSNumber numberWithInt:[[dictPost valueForKey:@"PostGroup"] intValue]];
            
            fromUser = PostBy;
            msgFromUser = PostTopic;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select post_id from post where post_id = ?",PostId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date, updated_on,seen,contract_type) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate,PostDate,[NSNumber numberWithBool:NO],contractType];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",PostBy,PostTopic]];
                    });
                }
            }];
            
            // we move this inside valid post insert
            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",PostBy,PostTopic]];
//            });
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [post updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
                
                post = nil;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
            }
            
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadPostForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = [self serializedStringDateJson:requestDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"GetImages %@",[myDatabase toJsonString:params]);
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_images] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"ImageContainer"];
        DDLogVerbose(@"new images %@",responseObject);
        [imagesArr addObject:dict];
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadPostImagesForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            [self SavePostImagesToDb];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                
            });
        }
    }];
}


- (void)SavePostImagesToDb
{
    imageDownloadComplete = NO;
    
    NSDictionary *topDict = (NSDictionary *)[imagesArr lastObject];
    NSDate *lastRequestDate = [myDatabase createNSDateWithWcfDateString:[topDict valueForKey:@"LastRequestDate"]];
    NSString *jsonDate = [self serializedStringDateJson:lastRequestDate];
    
    if (imagesArr.count > 0) {
        
        SDWebImageManager *sd_manager = [SDWebImageManager sharedManager];
        
        for (int xx = 0; xx < imagesArr.count; xx++) {
            NSDictionary *dict = (NSDictionary *) [imagesArr objectAtIndex:xx];
            
            NSArray *ImageList = [dict objectForKey:@"ImageList"];
            
            if(ImageList.count == 0) //no image to download, set true flag to watch download again
                imageDownloadComplete = YES;
            
            for (int j = 0; j < ImageList.count; j++) {
                
                NSDictionary *ImageListDict = [ImageList objectAtIndex:j];
                
                NSNumber *CommentId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"CommentId"] intValue]];
                NSNumber *ImageType = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"ImageType"] intValue]];
                NSNumber *PostId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"PostId"] intValue]];
                NSNumber *PostImageId = [NSNumber numberWithInt:[[ImageListDict valueForKey:@"PostImageId"] intValue]];
                
                DDLogVerbose(@"PostImageId %@",PostImageId);
                
                NSMutableString *ImagePath = [[NSMutableString alloc] initWithString:myDatabase.domain];
                NSString *imageFilename = [ImageListDict valueForKey:@"ImagePath"];
                
                if([CommentId intValue] > 1)
                {
                    [ImagePath appendString:[NSString stringWithFormat:@"ComressMImage/comment/%d/%@",[CommentId intValue],imageFilename]];
                }
                else if ([PostId intValue] > 1)
                {
                    [ImagePath appendString:[NSString stringWithFormat:@"ComressMImage/post/%d/%@",[PostId intValue],imageFilename]];
                }
                
                [sd_manager downloadImageWithURL:[NSURL URLWithString:ImagePath] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    
                    if(image == nil)
                        return;
                    
                    //create the image here
                    NSData *jpegImageData = UIImageJPEGRepresentation(image, 1);
                    
                    //save the image to app documents dir
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsPath = [paths objectAtIndex:0];
                    
                    NSString *filePath = [documentsPath stringByAppendingPathComponent:imageFilename]; //Add the file name
                    [jpegImageData writeToFile:filePath atomically:YES];
                    
                    NSFileManager *fManager = [[NSFileManager alloc] init];
                    if([fManager fileExistsAtPath:filePath] == NO)
                        return;
                    
                    //resize the saved image
                    [imgOpts resizeImageAtPath:filePath];
                    
                    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        
                        FMResultSet *rsPostImage = [db executeQuery:@"select post_image_id from post_image where post_image_id = ? and (post_image_id is not null or post_image_id > ?)",PostImageId,[NSNumber numberWithInt:0]];
                        DDLogVerbose(@"imageUrl %@",imageURL);
                        if([rsPostImage next] == NO) //does not exist, insert
                        {
                            BOOL qIns = [db executeUpdate:@"insert into post_image(comment_id, image_type, post_id, post_image_id, image_path) values(?,?,?,?,?)",CommentId,ImageType,PostId,PostImageId,imageFilename];
                            
                            if(!qIns)
                            {
                                *rollback = YES;
                                return;
                            }
                        }
                        
                        if(imagesArr.count-1 == xx) //last image
                        {
                            FMResultSet *rs = [db executeQuery:@"select * from post_image_last_request_date"];
                            
                            if(![rs next])
                            {
                                BOOL qIns = [db executeUpdate:@"insert into post_image_last_request_date(date) values(?)",lastRequestDate];
                                
                                if(!qIns)
                                {
                                    *rollback = YES;
                                    return;
                                }
                            }
                            else
                            {
                                BOOL qUp = [db executeUpdate:@"update post_image_last_request_date set date = ? ",lastRequestDate];
                                
                                if(!qUp)
                                {
                                    *rollback = YES;
                                    return;
                                }
                            }
                            
                            DDLogVerbose(@"image count %lu, current index %d",(unsigned long)ImageList.count,j);
                            
                            imageDownloadComplete = YES;
                            
                            [imagesArr removeAllObjects];
                            
                            //start download again
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                
                                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lastRequestDate];
                                
                            });
                        }
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
                        });
                    }];
                    
                    if(CommentId > 0)//the image was in a form of a comment, so we need to reload our chat view to reflect the image
                    {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadChatView" object:nil];
                        });
                    }
                }];
            } // for (int j = 0; j < ImageList.count; j++)
        } // for (int xx = 0; xx < imagesArr.count; xx++)
        if(imageDownloadComplete == YES) //0 ImageList
        {
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                    
                    [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } // if (imagesArr.count > 0)
    else
    {
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:lrd];
                
            });
        }
    }
}


- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"params %@",params);
    
    __block Comment *comment = [[Comment alloc] init];
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comments] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentContainer"];
        
        DDLogVerbose(@"new comments %@",dict);
        
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];

        NSArray *dictArray = [dict objectForKey:@"CommentList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictComment = [dictArray objectAtIndex:i];
            
            NSString *CommentBy = [dictComment valueForKey:@"CommentBy"];
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentId"] intValue]];
            NSString *CommentString = [dictComment valueForKey:@"CommentString"];
            NSNumber *CommentType =  [NSNumber numberWithInt:[[dictComment valueForKey:@"CommentType"] intValue]];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictComment valueForKey:@"PostId"] intValue]];
            NSDate *CommentDate = [myDatabase createNSDateWithWcfDateString:[dictComment valueForKey:@"CommentDate"]];

            __block BOOL newCommentSaved = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsComment = [theDb executeQuery:@"select comment_id from comment where comment_id = ?",CommentId];
                
                
                
                if([rsComment next] == NO) //does not exist, insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into comment (comment_by, comment_id, comment, comment_type, post_id, comment_on) values (?,?,?,?,?,?)",CommentBy,CommentId,CommentString,CommentType,PostId,CommentDate];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                    else
                        newCommentSaved = YES;
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        if([CommentType intValue] == 2)
                            [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : Photo Message",CommentBy]];
                        else
                            [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",CommentBy,CommentString]];
                    });
                }
            }];
            
            if(newCommentSaved == YES)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadChatView" object:nil];
            }
            //we move this inside valid insert
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                if([CommentType intValue] == 2)
//                    [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : Photo Message",CommentBy]];
//                else
//                    [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",CommentBy,CommentString]];
//            });
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [comment updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];

                comment = nil;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
            }
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadCommentsForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadCommentsForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate
{
    __block int currentPage = page;
    NSString *jsonDate = [self serializedStringDateJson:reqDate];
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"comment noti params %@",params);
    
    __block Comment_noti *comment_noti = [[Comment_noti alloc] init];
    
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_comment_noti] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(stop)return;
        
        NSDictionary *dict = [responseObject objectForKey:@"CommentNotiContainer"];
        DDLogVerbose(@"comment noti %@",dict);
        int totalPage = [[dict valueForKey:@"TotalPages"] intValue];
        NSDate *LastRequestDate = [myDatabase createNSDateWithWcfDateString:[dict valueForKey:@"LastRequestDate"]];
        
        NSArray *dictArray = [dict objectForKey:@"CommentNotiList"];
        
        for (int i = 0; i < dictArray.count; i++) {
            NSDictionary *dictNoti = [dictArray objectAtIndex:i];
            
            NSNumber *CommentId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"CommentId"] intValue]];
            NSString *UserId = [dictNoti valueForKey:@"UserId"];
            NSNumber *PostId = [NSNumber numberWithInt:[[dictNoti valueForKey:@"PostId"] intValue]];
            NSNumber *Status = [NSNumber numberWithInt:[[dictNoti valueForKey:@"Status"] intValue]];
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                theDb.traceExecution = YES;
                BOOL qIns = [theDb executeUpdate:@"insert into comment_noti(comment_id, user_id, post_id, status) values(?,?,?,?)",CommentId,UserId,PostId,Status];
                
                if(!qIns)
                {
                    *rollback = YES;
                    return;
                }

            }];
        }
        
        if(currentPage < totalPage)
        {
            currentPage++;
            [self startDownloadCommentNotiForPage:currentPage totalPage:totalPage requestDate:LastRequestDate];
        }
        else
        {
            if(dictArray.count > 0)
            {
                [comment_noti updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];

                comment_noti = nil;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
                });
            }
            if(downloadIsTriggeredBySelf)
            {
                //start download again
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    NSDate *lrd = [self deserializeJsonDateString:[dict valueForKey:@"LastRequestDate"]];
                    
                    [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:lrd];
                });
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(stop)return;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(downloadIsTriggeredBySelf)
        {
            //start download again
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSDate *lrd = [self deserializeJsonDateString:jsonDate];
                
                [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:lrd];
            });
        }
    }];
}


#pragma mark - helper methods


- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    NSTimeInterval unixTime = [[jsonDateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000; //WCF will send 13 digit-long value for the time interval since 1970 (millisecond precision) whereas iOS works with 10 digit-long values (second precision), hence the divide by 1000
    
    NSDate *date =  [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (NSString *)serializedStringDateJson: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
    
    NSString *jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [date timeIntervalSince1970],[formatter stringFromDate:date]]; //three zeroes at the end of the unix timestamp are added because thats the millisecond part (WCF supports the millisecond precision)
    
    
    return jsonDate;
}

- (void)notifyLocallyWithMessage:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}
@end
