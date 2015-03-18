//
//  RoutineListViewController.h
//  comress
//
//  Created by Diffy Romano on 11/3/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import <CoreLocation/CoreLocation.h>
#import "Database.h"
#import "MBProgressHUD.h"
#import "Schedule.h"
#import "RoutineTableViewCell.h"

@interface RoutineListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>

{
    Database *myDatabase;
    Schedule *schedule;
}

@property (nonatomic, strong) NSArray *scheduleArray;

@property (nonatomic, weak) IBOutlet UITableView *routineTableView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segment;
@end