//
//  Synchronize.m
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Synchronize.h"

@implementation Synchronize

@synthesize syncKickstartTimerOutgoing,syncKickstartTimerIncoming,imagesArr,imageDownloadComplete,downloadIsTriggeredBySelf;

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
    //outgoing
    [self uploadPostFromSelf:YES];
    syncKickstartTimerOutgoing = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(uploadPost) userInfo:nil repeats:YES];

//    [self startDownload];
//    downloadIsTriggeredBySelf = YES;
//    syncKickstartTimerIncoming = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(startDownload) userInfo:nil repeats:YES];
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
        [syncKickstartTimerIncoming invalidate]; //init is done, no need for timer. post, comment and image will recurse automatically.
    
    //incoming
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        __block NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];


        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

            //download post
            FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
            
            if([rs next])
            {
                jsonDate = (NSDate *)[rs dateForColumn:@"date"];
                
            }
            [self startDownloadPostForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            //download post image
            FMResultSet *rs2 = [db executeQuery:@"select date from post_image_last_request_date"];
            
            if([rs2 next])
            {
                jsonDate = (NSDate *)[rs2 dateForColumn:@"date"];
                
            }
            [self startDownloadPostImagesForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            //download comments
            FMResultSet *rs3 = [db executeQuery:@"select date from comment_last_request_date"];
            
            if([rs3 next])
            {
                jsonDate = (NSDate *)[rs3 dateForColumn:@"date"];
            }
            [self startDownloadCommentsForPage:1 totalPage:0 requestDate:jsonDate];
            
            
            //download comment noti
            FMResultSet *rs4 = [db executeQuery:@"select date from comment_noti_last_request_date"];
            
            if([rs4 next])
            {
                jsonDate = (NSDate *)[rs4 dateForColumn:@"date"];
            }
            [self startDownloadCommentNotiForPage:1 totalPage:0 requestDate:jsonDate];
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
                                   @"IsUpdated":[NSNumber numberWithBool:NO]
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
                }];
            }
            
            if(thisSelf)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self uploadImageFromSelf:YES];
                });
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadCommentFromSelf:YES];
            });
            return;
        }
    }
    imagesArray_temp = nil;
    
    //send images
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_send_images] parameters:imagesDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadCommentFromSelf:YES];
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        imagesInDb = nil;
        
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        if(thisSelf)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(sync_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadCommentFromSelf:YES];
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
            
            fromUser = PostBy;
            msgFromUser = PostTopic;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                
                FMResultSet *rsPost = [theDb executeQuery:@"select post_id from post where post_id = ?",PostId];
                if([rsPost next] == NO) //does not exist. insert
                {
                    BOOL qIns = [theDb executeUpdate:@"insert into post (status, block_id, level, address, post_by, post_id, post_topic, post_type, postal_code, severity, post_date, updated_on,seen) values (?,?,?,?,?,?,?,?,?,?,?,?,?)",ActionStatus, BlkId, Level, Location, PostBy, PostId, PostTopic, PostType, PostalCode, Severity, PostDate,PostDate,[NSNumber numberWithBool:NO]];
                    
                    if(!qIns)
                    {
                        *rollback = YES;
                        return;
                    }
                }
            }];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",PostBy,PostTopic]];
            });
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
                }
            }];
            
            if(newCommentSaved == YES)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadChatView" object:nil];
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if([CommentType intValue] == 2)
                    [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : Photo Message",CommentBy]];
                else
                    [self notifyLocallyWithMessage:[NSString stringWithFormat:@"%@ : %@",CommentBy,CommentString]];
            });
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
