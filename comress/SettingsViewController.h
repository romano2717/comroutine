//
//  SettingsViewController.h
//  comress
//
//  Created by Diffy Romano on 2/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Database.h"
#import "Users.h"
#import "Client.h"

@interface SettingsViewController : UIViewController<UIAlertViewDelegate>
{
    Database *myDatabase;
    
    Users *users;
    Client *client;
}
@property (nonatomic, weak) IBOutlet UILabel *userFullNameLabel;
@end
