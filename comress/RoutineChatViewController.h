//
//  RoutineChatViewController.h
//  comress
//
//  Created by Diffy Romano on 19/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "JSQMessagesViewController.h"
#import "JSQMessage.h"
#import "MessageDataRoutine.h"
#import "CheckListViewController.h"
#import "NavigationBarTitleWithSubtitleView.h"
#import "CheckListViewController.h"
#import "FPPopoverKeyboardResponsiveController.h"
#import "Post.h"
#import "Schedule.h"
#import "Database.h"

@class RoutineChatViewController;

@protocol IssuesChatViewControllerDelegate <NSObject>

- (void)didDismissJSQMessageComposerViewController:(RoutineChatViewController *)vc;

@end

@interface RoutineChatViewController : JSQMessagesViewController
{
    FPPopoverKeyboardResponsiveController *popover;
    Post *post;
    Schedule *schedule;
    Database *myDatabase;
}

@property (nonatomic, strong) NSString *blockNo;
@property (nonatomic, strong) NSNumber *blockId;

@end
