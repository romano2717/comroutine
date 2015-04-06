//
//  SurveyListingViewController.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "Survey.h"
#import "SurveyTableViewCell.h"
#import "SurveyDetailViewController.h"

@interface SurveyListingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    Database *myDatabase;
    Survey *survey;
}
@property (nonatomic, weak) IBOutlet UITableView *surveyTableView;

@property (nonatomic, strong) NSArray *surveyArray;

@end
