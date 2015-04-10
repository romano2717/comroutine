//
//  SurveyViewController.m
//  comress
//
//  Created by Diffy Romano on 1/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "SurveyViewController.h"
#import "UIView+Shake.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface SurveyViewController ()

@end

@implementation SurveyViewController

@synthesize ratingsImageArray,ratingsStringArray,ratingsImageSelectedArray,selectedRating,ratingsCollectionView,surveyQuestions,locale,segment;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myDatabase = [Database sharedMyDbManager];
    questions = [[Questions alloc] init];
    self.foundPlacesFinalArray = [[NSMutableArray alloc] init];
    
    locale = @"en";
    
    //init location manager
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = 100;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.delegate = self;
    
    [locationManager requestAlwaysAuthorization];
    [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
    
    UIImage *excellent = [UIImage imageNamed:@"excellent@2x.png"];
    UIImage *average = [UIImage imageNamed:@"aver@2x.png"];
    UIImage *poor = [UIImage imageNamed:@"poor@2x.png"];

    UIImage *excellent_sel = [UIImage imageNamed:@"excellent_sel@2x.png"];
    UIImage *average_sel = [UIImage imageNamed:@"aver_sel@2x.png"];
    UIImage *poor_sel = [UIImage imageNamed:@"poor_sel@2x.png"];

    ratingsImageArray = [NSArray arrayWithObjects:excellent,average,poor, nil];
    ratingsImageSelectedArray = [NSArray arrayWithObjects:excellent_sel,average_sel,poor_sel, nil];
    
    NSArray *en    = @[@"YES",@"NEUTRAL",@"NO"];
    NSArray *cn    = @[@"是的好",@"中性",@"别"];
    NSArray *my    = @[@"ya",@"berkecuali",@"tidak"];
    NSArray *ind = @[@"ஆம்",@"நடுநிலை",@"எந்த"];
    
    ratingsStringArray = [NSArray arrayWithObjects:@{@"en":en},@{@"cn":cn},@{@"my":my},@{@"ind":ind},nil];
    
    [self checkQuestionsCount];
}

- (void)saveSurvey
{
    //save this as new survey
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        db.traceExecution = YES;
        NSDate *now = [NSDate date];
        
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",[NSNumber numberWithLongLong:self.currentSurveyId]];
        if([rs next] == NO)
        {
            BOOL ins = [db executeUpdate:@"insert into su_survey(survey_date) values (?)",now];
            
            if(!ins)
            {
                *rollback = YES;
                return;
            }
            else
                self.currentSurveyId = [db lastInsertRowId];
        }
    }];
}


- (IBAction)toggleSegment:(id)sender
{
    int index = (int)segment.selectedSegmentIndex;
    
    if(index == 1)
    {
        FeedBackViewController *fvc = [self.storyboard instantiateViewControllerWithIdentifier:@"FeedBackViewController"];
        fvc.pushFromSurvey = YES;
        fvc.currentClientSurveyId = [NSNumber numberWithLongLong:self.currentSurveyId];
        fvc.pushFromSurveyAndModalFromFeedback = YES;
        [self.navigationController pushViewController:fvc animated:NO];
        [UIView commitAnimations];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;
    self.hidesBottomBarWhenPushed = YES;
    
    segment.selectedSegmentIndex = 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
    self.hidesBottomBarWhenPushed = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

#pragma mark - location manager
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    
    NSTimeInterval locationAge = -[loc.timestamp timeIntervalSinceNow];
    
    BOOL locationIsGood = YES;
    
    if (locationAge > 15.0)
    {
        locationIsGood = NO;
    }
    
    if (loc.horizontalAccuracy < 0)
    {
        locationIsGood = NO;
    }
    
    if(locationIsGood)
    {
        self.currentLocation = loc;
        self.currentLocationFound = YES;
        [locationManager stopUpdatingLocation];
        
        [self getNearbyBlocksWithinTheGrcForThisLocation:loc];
    }
}

- (void)getNearbyBlocksWithinTheGrcForThisLocation:(CLLocation *)location
{
    double current_lat = location.coordinate.latitude;
    double current_lng = location.coordinate.longitude;

//    double current_lat = 1.301435;
//    double current_lng = 103.797132;

    
    self.closeAreas = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *nearestBlocks = [db executeQuery:@"select * from blocks where latitude > 0 and longitude > 0"];
        
        while ([nearestBlocks next]) {
            
            NSDictionary *dict = [nearestBlocks resultDictionary];
            
            double lat = [nearestBlocks doubleForColumn:@"latitude"];
            double lng = [nearestBlocks doubleForColumn:@"longitude"];
            
            double distance = (acos(sin(current_lat * M_PI / 180) * sin(lat * M_PI / 180) + cos(current_lat * M_PI / 180) * cos(lat * M_PI / 180) * cos((current_lng - lng) * M_PI / 180)) * 180 / M_PI) * 60 * 1.1515 * 1.609344;
            
            double distanceInMeters = distance * 1000;
            
            if(distanceInMeters <= 500) //500 m
            {
                [self.closeAreas addObject:dict];
            }
        }
    }];
}



#pragma mark - check spo sked
- (void)checkQuestionsCount
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSDate *last_request_date = nil;
        
        FMResultSet *rs = [db executeQuery:@"select date from su_questions_last_req_date"];
        while ([rs next]) {
            last_request_date = [rs dateForColumn:@"date"];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Z"]; //for getting the timezone part of the date only.
        
        NSString *jsonDate = @"/Date(1388505600000+0800)/";
        
        if(last_request_date != nil)
        {
            jsonDate = [NSString stringWithFormat:@"/Date(%.0f000%@)/", [last_request_date timeIntervalSince1970],[formatter stringFromDate:last_request_date]];
        }
        
        NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:1], @"lastRequestTime" : jsonDate};
        DDLogVerbose(@"%@",[myDatabase toJsonString:params]);
        DDLogVerbose(@"%@",[myDatabase.userDictionary valueForKey:@"guid"]);
        [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSDictionary *dict = [responseObject objectForKey:@"QuestionContainer"];
            
            int totalRows = [[dict valueForKey:@"TotalRows"] intValue];
            __block BOOL needToDownloadBlocks = NO;
            
            [myDatabase.databaseQ inTransaction:^(FMDatabase *theDb, BOOL *rollback) {
                FMResultSet *rsBlockCount = [theDb executeQuery:@"select count(*) as total from su_questions"];
                
                while ([rsBlockCount next]) {
                    int total = [rsBlockCount intForColumn:@"total"];
                    
                    if(total < totalRows)
                    {
                        needToDownloadBlocks = YES;
                    }
                }
            }];
            
            if(needToDownloadBlocks)
                [self startDownloadQuestionsForPage:1 totalPage:0 requestDate:nil withUi:YES];
            else
            {
                [self prepareQuestions];
            }
            
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
            
            [self prepareQuestions];
        }];
        
    }];
}


- (void)startDownloadQuestionsForPage:(int)page totalPage:(int)totPage requestDate:(NSDate *)reqDate withUi:(BOOL)withUi
{
    __block int currentPage = page;
    __block NSDate *requestDate = reqDate;
    
    NSString *jsonDate = @"/Date(1388505600000+0800)/";
    
    if(currentPage > 1)
        jsonDate = [NSString stringWithFormat:@"%@",requestDate];
    
    
    NSDictionary *params = @{@"currentPage":[NSNumber numberWithInt:page], @"lastRequestTime" : jsonDate};
    DDLogVerbose(@"startDownloadSpoSkedForPage %@",[myDatabase toJsonString:params]);
    DDLogVerbose(@"session %@",[myDatabase.userDictionary valueForKey:@"guid"]);
    
    [myDatabase.AfManager POST:[NSString stringWithFormat:@"%@%@",myDatabase.api_url,api_download_fed_questions] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
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
            [self startDownloadQuestionsForPage:currentPage totalPage:totalPage requestDate:LastRequestDate withUi:withUi];
        }
        else
        {
            if(dictArray.count > 0)
                [questions updateLastRequestDateWithDate:[dict valueForKey:@"LastRequestDate"]];
            

            
            [self prepareQuestions];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogVerbose(@"%@ [%@-%@]",error.localizedDescription,THIS_FILE,THIS_METHOD);
        
        [self prepareQuestions];
    }];
}

- (void)prepareQuestions
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_questions order by id asc"];
        
        NSMutableArray *questionsArr = [[NSMutableArray alloc] init];
        
        while ([rs next]) {
            [questionsArr addObject:[rs resultDictionary]];
        }
        
        surveyQuestions = questionsArr;
        
        NSString *firstQuestion = [[surveyQuestions firstObject] valueForKey:locale];
        [self setQuestionTextViewWithQuestion:firstQuestion];
        
    }];
}

- (IBAction)setNewLocale:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    
    switch ((int)btn.tag) {
        case 2:
            locale = @"cn";
            break;
        
        case 3:
            locale = @"my";
            break;
        case 4:
            locale = @"ind";
            break;
        default:
            locale = @"en";
            break;
    }
    
    [self setQuestionTextViewWithQuestion:[[surveyQuestions objectAtIndex:self.currentQuestionIndex] valueForKey:locale]];
    [self.ratingsCollectionView reloadData];
}

- (void)setQuestionTextViewWithQuestion:(NSString *)question
{
    //set the first question
    if(surveyQuestions.count > 0)
    {
        self.questionCounter.text = [NSString stringWithFormat:@"%d of %lu",1,(unsigned long)surveyQuestions.count];
        self.questionTextView.text = question;
        
        //auto fit long questions
        while (((CGSize) [self.questionTextView sizeThatFits:self.questionTextView.frame.size]).height > self.questionTextView.frame.size.height) {
            self.questionTextView.font = [self.questionTextView.font fontWithSize:self.questionTextView.font.pointSize-1];
        }
        
        self.questionCounter.text = [NSString stringWithFormat:@"%d of %lu",self.currentQuestionIndex+1, (unsigned long)surveyQuestions.count];
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ratingsImageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.selected = YES;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    // Configure the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    UILabel *ratingLabel = (UILabel *)[cell viewWithTag:2];
    
    UIImage *img = (UIImage *)[ratingsImageArray objectAtIndex:indexPath.row];
    imageView.image = img;
    
    NSString *theLocale;
    for (int i = 0; i < ratingsStringArray.count; i++) {
        NSDictionary *dict = [ratingsStringArray objectAtIndex:i];
        NSString *key = [[dict allKeys] firstObject];
        
        if([key isEqualToString:locale])
            theLocale = [[dict valueForKey:key] objectAtIndex:indexPath.row];
    }
    ratingLabel.text = theLocale;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
//    if(selectedRating > 0) //reset the previously selected image
//    {
//        int index = 0;
//        for (UICollectionViewCell *cell in ratingsCollectionView.visibleCells) {
//            DDLogVerbose(@"index %d",index);
//            UIImageView *imgv = (UIImageView *)[cell viewWithTag:1];
//            
//            imgv.image = [ratingsImageArray objectAtIndex:index];
//            
//            index++;
//        }
//    }
    
    //set to selected image
    [imageView shake:5 withDelta:5 andSpeed:0.1 shakeDirection:ShakeDirectionVertical completionHandler:^{
//        imageView.image = (UIImage *)[ratingsImageSelectedArray objectAtIndex:indexPath.row];
//        
//        selectedRating = (int)ratingsImageArray.count - (int) indexPath.row;
        

        //go to next question
        if(self.currentQuestionIndex < surveyQuestions.count)
        {
            [self saveSurvey];
            
            //save this answer
            [self saveSurveyQuestionWithRating:[NSNumber numberWithInt:selectedRating]  forQuestionId:[[surveyQuestions objectAtIndex:self.currentQuestionIndex] valueForKey:@"id"]];
            
            if(self.currentQuestionIndex == surveyQuestions.count - 1)//last question
            {
                DDLogVerbose(@"last q");
                
                [locationManager stopUpdatingLocation];
                
                [self performSegueWithIdentifier:@"push_resident_info" sender:self];
            }
            else
            {
                self.currentQuestionIndex++;
                
                [self setQuestionTextViewWithQuestion:[[surveyQuestions objectAtIndex:self.currentQuestionIndex] valueForKey:locale]];
                
//                if(selectedRating > 0) //reset the previously selected image
//                {
//                    int index = 0;
//                    for (UICollectionViewCell *cell in ratingsCollectionView.visibleCells) {
//                        DDLogVerbose(@"index %d",index);
//                        UIImageView *imgv = (UIImageView *)[cell viewWithTag:1];
//                        
//                        imgv.image = [ratingsImageArray objectAtIndex:index];
//                        
//                        index++;
//                    }
//                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.ratingsCollectionView reloadData];
        });
    }];
}


 #pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_feedback"])
    {
        FeedBackViewController *fvc = [segue destinationViewController];
        fvc.pushFromSurveyAndModalFromFeedback = YES;
    }
    else
    {
        //we are moving away from this VC, stop the location service

        [locationManager stopUpdatingLocation];
        
        
        //get all the rating for this current survey
        __block int sum = 0;
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rsRatings = [db executeQuery:@"select sum(rating) as sumOfRatings from su_answers where client_survey_id = ?",[NSNumber numberWithLongLong:self.currentSurveyId]];
            
            while ([rsRatings next]) {
                sum = [rsRatings intForColumn:@"sumOfRatings"];
            }
        }];
        
        int aver = sum / surveyQuestions.count;
        
        //update the average rating of this survey
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL upAver = [db executeUpdate:@"update su_survey set average_rating = ? where client_survey_id = ?",[NSNumber numberWithInt:aver],[NSNumber numberWithLongLong:self.currentSurveyId]];
            
            if(!upAver)
            {
                *rollback = YES;
                return;
            }
        }];
        
        
        ResidentInfoViewController *resident = [segue destinationViewController];
        
        resident.surveyId = [NSNumber numberWithLongLong:self.currentSurveyId];
        resident.currentLocation = self.currentLocation;
        resident.placemark = self.placemark;
        resident.currentSurveyId = self.currentSurveyId;
        resident.foundPlacesArray = self.closeAreas;
        resident.averageRating = [NSNumber numberWithInt:aver];
    }
}


- (void)saveSurveyQuestionWithRating:(NSNumber *)rating forQuestionId:(NSNumber *)questionId
{
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        FMResultSet *rsCheck = [db executeQuery:@"select * from su_answers where client_survey_id = ? and question_id = ?",[NSNumber numberWithLongLong:self.currentSurveyId] , questionId];
        
        if([rsCheck next] == NO) //does not exist, insert as new
        {
            BOOL ins = [db executeUpdate:@"insert into su_answers (question_id,rating,client_survey_id) values (?,?,?)",questionId,rating,[NSNumber numberWithLongLong:self.currentSurveyId]];
            
            if(!ins)
            {
                *rollback = YES;
                return;
            }
        }
        else //already exist, update it
        {
            BOOL up = [db executeUpdate:@"update su_answers set rating = ? where question_id = ? and client_survey_id = ?",rating,questionId,[NSNumber numberWithLongLong:self.currentSurveyId]];
            if(!up)
            {
                *rollback = YES;
                return;
            }
        }
    }];
}

- (IBAction)previousQuestion:(id)sender
{
    if(self.currentQuestionIndex > 0)
    {
        self.currentQuestionIndex--;
        
        [self setQuestionTextViewWithQuestion:[[surveyQuestions objectAtIndex:self.currentQuestionIndex] valueForKey:locale]];
        
    }
}

- (IBAction)nextQuestion:(id)sender
{
    if(self.currentQuestionIndex < surveyQuestions.count - 1)
    {
        self.currentQuestionIndex++;
        
        [self setQuestionTextViewWithQuestion:[[surveyQuestions objectAtIndex:self.currentQuestionIndex] valueForKey:locale]];
    }
}

@end
