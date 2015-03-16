//
//  IssuesViewController.h
//  comress
//
//  Created by Diffy Romano on 3/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "IssuesTableViewCell.h"
#import "IssuesChatViewController.h"
#import "Comment.h"
#import "Users.h"
#import "Database.h"

@interface IssuesViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,IssuesChatViewControllerDelegate>
{
    Post *post;
    IssuesTableViewCell *issuesCell;
    Comment *comment;
    Users *user;
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UITableView *issuesTable;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;
@property (nonatomic, weak) IBOutlet UIButton *bulbButton;
@end
