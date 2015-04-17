//
//  Synchronize.h
//  comress
//
//  Created by Diffy Romano on 9/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "InitializerViewController.h"
#import "ImageOptions.h"
#import "NSData+Base64.h"

@interface Synchronize : NSObject
{
    Database *myDatabase;
//    InitializerViewController *init;
    
    
    ImageOptions *imgOpts;
}

@property (nonatomic, strong) NSTimer *syncKickstartTimerOutgoing;
@property (nonatomic, strong) NSTimer *syncKickstartTimerIncoming;
@property (nonatomic) BOOL imageDownloadComplete;
@property (nonatomic, strong) NSMutableArray *imagesArr;
@property (nonatomic) BOOL downloadIsTriggeredBySelf;
@property (nonatomic) BOOL stop;

+ (id)sharedManager;

- (void)kickStartSync;


//upload

- (void)uploadPostFromSelf:(BOOL )thisSelf;

- (void)uploadCommentFromSelf:(BOOL )thisSelf;

- (void)uploadImageFromSelf:(BOOL )thisSelf;

- (void)uploadPostStatusChangeFromSelf:(BOOL )thisSelf;

- (void)uploadCommentNotiAlreadyReadFromSelf:(BOOL)thisSelf;

- (void)uploadInspectionResultFromSelf:(BOOL)thisSelf;

- (void)uploadSurveyFromSelf:(BOOL)thisSelf;

- (void)uploadResidentInfoEditForSurveyId:(NSNumber *)surveyId;

//download

- (void)startDownloadPostForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadPostImagesForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadCommentsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadCommentNotiForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;

- (void)startDownloadSurveyPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate;
@end
