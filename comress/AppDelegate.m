//
//  AppDelegate.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize bgTask;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //-- Set Notification

    // iOS 8 Notifications
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    
    [application registerForRemoteNotifications];
    
    
    if(allowLogging)
        [[AFNetworkActivityLogger sharedLogger] startLogging];
    
    myDatabase = [Database sharedMyDbManager];
    
    //logging mechanism;
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize  = 256000 * 1;  // 256 KB
    fileLogger.rollingFrequency =   60 * 60 * 120;  // 120 hour rolling or 5 days. unit in seconds
    fileLogger.logFileManager.maximumNumberOfLogFiles = 2;
    
    [DDLog addLogger:fileLogger];
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    //migrate database
    //[myDatabase migrateDatabase];

    sync = [Synchronize  sharedManager];
    [sync kickStartSync];
    
    [application setKeepAliveTimeout:ping_interval handler:^{
        [self createBackgroundTaskWithSync:YES];
    }];
    
    
    //watcher used in didbecomeactive and reload list
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadNewItems) name:@"downloadNewItems" object:nil];
    
    //start reachability watchers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //Change the host name here to change the server you want to monitor.
//    NSString *remoteHostName = [myDatabase.clientDictionary valueForKey:@"api_url"];
//
//    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
//    [self.hostReachability startNotifier];
//    [self updateInterfaceWithReachability:self.hostReachability];
//    
//    self.internetReachability = [Reachability reachabilityForInternetConnection];
//    [self.internetReachability startNotifier];
//    [self updateInterfaceWithReachability:self.internetReachability];
//    
//    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
//    [self.wifiReachability startNotifier];
//    [self updateInterfaceWithReachability:self.wifiReachability];
    
    return YES;
}


/*!
 * Called by Reachability whenever status changes.
 */
//- (void) reachabilityChanged:(NSNotification *)note
//{
//    Reachability* curReach = [note object];
//    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
//    [self updateInterfaceWithReachability:curReach];
//}
//
//
//- (void)updateInterfaceWithReachability:(Reachability *)reachability
//{
//    if (reachability == self.hostReachability)
//    {
//        [self configureConnectionWithReachability:reachability];
//    }
//    
//    if (reachability == self.internetReachability)
//    {
//        [self configureConnectionWithReachability:reachability];
//    }
//    
//    if (reachability == self.wifiReachability)
//    {
//        [self configureConnectionWithReachability:reachability];
//    }
//}
//
//
//- (void)configureConnectionWithReachability:(Reachability *)reachability
//{
//    NetworkStatus netStatus = [reachability currentReachabilityStatus];
//    
//    switch (netStatus)
//    {
//        case NotReachable:        {
//            //[sync stopSynchronize];
//            //break;
//        }
//            
//        case ReachableViaWWAN:        {
//            //[sync kickStartSync];
//            //break;
//        }
//        case ReachableViaWiFi:        {
//            //[sync kickStartSync];
//            //break;
//        }
//    }
//}

- (void)createBackgroundTaskWithSync:(BOOL)withSync
{
    UIApplication *theApplication = [UIApplication sharedApplication];
    
    if(theApplication.applicationState == UIApplicationStateBackground)
    {
        [theApplication endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        
        if(bgTask == UIBackgroundTaskInvalid)
        {
            bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                DDLogVerbose(@"end bg task");
                [theApplication endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }];
        }
        
        if(withSync)
        {
            [sync kickStartSync];
        }
    }
}

- (NSDate *)deserializeJsonDateString: (NSString *)jsonDateString
{
    NSInteger startPosition = [jsonDateString rangeOfString:@"("].location + 1; //start of the date value
    //NSInteger startPosition = [jsonDateString rangeOfString:@"("].location ;
    
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

- (void)pingServer
{
    DDLogVerbose(@"Ping server...");
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [self createBackgroundTaskWithSync:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    //we don't need background task while app is active
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
    
    [self downloadNewItems];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];

    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select device_token from device_token"];
        BOOL q;
        
        if([rs next])
        {

            q = [db executeUpdate:@"update device_token set device_token = ?",token];
            
            if(!q)
            {
                *rollback = YES;
                DDLogVerbose(@"error saving device token");
            }
        }
        else
        {

            BOOL q2 = [db executeUpdate:@"insert into device_token (device_token) values (?)",token];
            if(!q2)
            {
                *rollback = YES;
            }
        }
        
        NSNumber *deviceId = [myDatabase.userDictionary valueForKey:@"device_id"] ? [myDatabase.userDictionary valueForKey:@"device_id"] : 0;
        
        if([deviceId intValue] != 0) //the use is currently logged in
        {
            NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@&deviceToken=%@",deviceId,[myDatabase.deviceTokenDictionary valueForKey:@"device_token"]];
            
            [myDatabase.AfManager GET:[NSString stringWithFormat:@"%@%@%@",myDatabase.api_url,api_update_device_token,urlParams] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                DDLogVerbose(@"update device token %@",responseObject);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            }];
        }
    }];
    
    [myDatabase createDeviceToken];
}

- (void)downloadNewItems
{
    if(myDatabase.initializingComplete == 0)
        return;
    
    __block NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //download comments
        FMResultSet *rs3 = [db executeQuery:@"select date from comment_last_request_date"];
        
        if([rs3 next])
        {
            jsonDate = (NSDate *)[rs3 dateForColumn:@"date"];
        }
        [sync startDownloadCommentsForPage:1 totalPage:0 requestDate:jsonDate];
        
        
        //download comment noti
        FMResultSet *rs4 = [db executeQuery:@"select date from comment_noti_last_request_date"];
        
        if([rs4 next])
        {
            jsonDate = (NSDate *)[rs4 dateForColumn:@"date"];
        }
        [sync startDownloadCommentNotiForPage:1 totalPage:0 requestDate:jsonDate];
    }];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //download post image
        FMResultSet *rs2 = [db executeQuery:@"select date from post_image_last_request_date"];
        
        if([rs2 next])
        {
            jsonDate = (NSDate *)[rs2 dateForColumn:@"date"];
            
        }
        [sync startDownloadPostImagesForPage:1 totalPage:0 requestDate:jsonDate];
    }];
    
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
        
        if([rs next])
        {
            jsonDate = (NSDate *)[rs dateForColumn:@"date"];
            
        }
        [sync startDownloadPostForPage:1 totalPage:0 requestDate:jsonDate];
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
//    POST= "11";
//    COMMENT= "12";
//    IMAGE = "13";
    
    int silentRemoteNotifValue = [[userInfo valueForKeyPath:@"aps.content-available"] intValue];
    
    __block NSDate *jsonDate = [self deserializeJsonDateString:@"/Date(1388505600000+0800)/"];
    
    DDLogVerbose(@"silentRemoteNotifValue %d",silentRemoteNotifValue);
    
    switch (silentRemoteNotifValue) {
        case 12:
        {
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                //download comments
                FMResultSet *rs3 = [db executeQuery:@"select date from comment_last_request_date"];
                
                if([rs3 next])
                {
                    jsonDate = (NSDate *)[rs3 dateForColumn:@"date"];
                }
                [sync startDownloadCommentsForPage:1 totalPage:0 requestDate:jsonDate];
                
                
                //download comment noti
                FMResultSet *rs4 = [db executeQuery:@"select date from comment_noti_last_request_date"];
                
                if([rs4 next])
                {
                    jsonDate = (NSDate *)[rs4 dateForColumn:@"date"];
                }
                [sync startDownloadCommentNotiForPage:1 totalPage:0 requestDate:jsonDate];
            }];
            
            

            break;
        }
        
        case 13:
        {
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                //download post image
                FMResultSet *rs2 = [db executeQuery:@"select date from post_image_last_request_date"];
                
                if([rs2 next])
                {
                    jsonDate = (NSDate *)[rs2 dateForColumn:@"date"];
                    
                }
                [sync startDownloadPostImagesForPage:1 totalPage:0 requestDate:jsonDate];
            }];
            
            
            break;
        }
        
            
        default:
        {
            [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *rs = [db executeQuery:@"select date from post_last_request_date"];
                
                if([rs next])
                {
                    jsonDate = (NSDate *)[rs dateForColumn:@"date"];
                    
                }
                [sync startDownloadPostForPage:1 totalPage:0 requestDate:jsonDate];
            }];
            
            break;
        }
        
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
