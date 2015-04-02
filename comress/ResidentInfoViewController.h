//
//  ResidentInfoViewController.h
//  comress
//
//  Created by Diffy Romano on 2/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ResidentInfoViewController : UIViewController

@property (nonatomic, strong) NSNumber *surveyId;
@property (nonatomic, strong) CLLocation *currentLocation;


@end
