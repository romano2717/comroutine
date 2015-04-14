//
//  Survey.m
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Survey.h"

@implementation Survey

- (id)init {
    if (self = [super init]) {
        myDatabase = [Database sharedMyDbManager];
    }
    
    return self;
}

- (NSArray *)fetchSurvey
{
    NSMutableArray *surveyArr = [[NSMutableArray alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey order by survey_date desc"];
        
        while ([rs next]) {
            //check if this survey got atleast 1 answer, if not, don't add this survery
            FMResultSet *check = [db executeQuery:@"select * from su_answers where client_survey_id = ? or survey_id = ?",[NSNumber numberWithInt:[rs intForColumn:@"client_survey_id"]],[NSNumber numberWithInt:[rs intForColumn:@"survey_id"]]];
            
            if([check next] == YES)
            {
                NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                
                [row setObject:[rs resultDictionary] forKey:@"survey"];
                
                //get address details
                NSNumber *clientAddressId = [NSNumber numberWithInt:[rs intForColumn:@"client_survey_address_id"]];
                NSNumber *addressId = [NSNumber numberWithInt:[rs intForColumn:@"survey_address_id"]];
                FMResultSet *rsAdd;
                if([addressId intValue] > 0)
                    rsAdd = [db executeQuery:@"select * from su_address where client_address_id != ? and (client_address_id = ? or address_id = ?)",[NSNumber numberWithInt:0],clientAddressId,addressId];
                else
                    rsAdd = [db executeQuery:@"select * from su_address where client_address_id != ? and (client_address_id = ?)",[NSNumber numberWithInt:0],clientAddressId];
                
                BOOL thereIsAnAddress = NO;
                
                while ([rsAdd next]) {
                    thereIsAnAddress = YES;
                    [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                }
                
                //if(thereIsAnAddress) //no address means the resident decline the data policy terms, consider it an anonymous survey
                    [surveyArr addObject:row];
            }
        }
    }];
    
    return surveyArr;
}

- (NSArray *)surveyDetailForSegment:(NSInteger)segment forSurveyId:(NSNumber *)surveyId
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    if(segment == 0)
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_answers sa, su_questions sq where sa.client_survey_id = ? and sa.question_id = sq.id",surveyId];
            
            while ([rs next]) {
                [arr addObject:[rs resultDictionary]];
            }
        }];
        
        
    }
    
    else
    {
        [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *rs = [db executeQuery:@"select * from su_feedback where client_survey_id = ? order by client_feedback_id desc",surveyId];
            
            while ([rs next]) {
                NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
                NSMutableArray *postsArray = [[NSMutableArray alloc] init];
                
                [row setObject:[rs resultDictionary] forKey:@"feedback"];
                
                //get address details
                NSNumber *client_address_id = [NSNumber numberWithInt:[rs intForColumn:@"client_address_id"]];
                FMResultSet *rsAdd = [db executeQuery:@"select * from su_address where client_address_id = ?",client_address_id];
                
                while ([rsAdd next]) {
                    [row setObject:[rsAdd resultDictionary] forKey:@"address"];
                }
                
                
                //get post details
                NSNumber *client_feedback_id = [NSNumber numberWithInt:[rs intForColumn:@"client_feedback_id"]];
                FMResultSet *rsFeedBackIssue = [db executeQuery:@"select * from su_feedback_issue where client_feedback_id = ?",client_feedback_id];
                while ([rsFeedBackIssue next]) {
                    
                    NSNumber *postId = [NSNumber numberWithInt:[rsFeedBackIssue intForColumn:@"client_post_id"]];
                    FMResultSet *rspost = [db executeQuery:@"select * from post where client_post_id = ?",postId];
                    
                    while ([rspost next]) {
                        [postsArray addObject:[rspost resultDictionary]];
                    }
                    
                    [row setObject:postsArray forKey:@"post"];
                }
                
                //get contract types
                FMResultSet *rsContractTypes = [db executeQuery:@"select * from contract_type"];
                NSMutableArray *contractTypesArray = [[NSMutableArray alloc] init];
                while ([rsContractTypes next]) {
                    [contractTypesArray addObject:[rsContractTypes resultDictionary]];
                }
                [row setObject:contractTypesArray forKey:@"contractTypes"];
                
                //store!
                [arr addObject:row];
            }
        }];
    }
    
    return arr;
}

- (NSDictionary *)surveyForId:(NSNumber *)surveyId forAddressType:(NSString *)addressType
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        NSDictionary *surveyDict;
        NSDictionary *addressDict;

        int surveyAddressId = 0;
        int residentAddressId = 0;
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            surveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            residentAddressId = [rs intForColumn:@"client_resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        //get address
        if([addressType isEqualToString:@"survey"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:surveyAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        //get address
        if([addressType isEqualToString:@"resident"])
        {
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:residentAddressId]];
            
            while ([rsAddress next]) {
                addressDict = [rsAddress resultDictionary];
            }
        }
        
        if(addressDict != nil)
            [dict setObject:addressDict forKey:@"address"];
        
    }];
    
    return dict;
}


- (NSDictionary *)surveDetailForId:(NSNumber *)surveyId
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [myDatabase.databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from su_survey where client_survey_id = ?",surveyId];
        NSDictionary *surveyDict;
        NSDictionary *residentAddressDict;
        NSDictionary *surveyAddressDict;
        
        int surveyAddressId = 0;
        int residentAddressId = 0;
        while ([rs next]) {
            surveyDict = [rs resultDictionary];
            
            surveyAddressId = [rs intForColumn:@"client_survey_address_id"];
            residentAddressId = [rs intForColumn:@"client_resident_address_id"];
        }
        
        if(surveyDict != nil)
            [dict setObject:surveyDict forKey:@"survey"];
        
        
            FMResultSet *rsAddress = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:surveyAddressId]];
            
            while ([rsAddress next]) {
                surveyAddressDict = [rsAddress resultDictionary];
            }
        
            FMResultSet *rsAddress2 = [db executeQuery:@"select * from su_address where client_address_id = ?",[NSNumber numberWithInt:residentAddressId]];
            
            while ([rsAddress2 next]) {
                residentAddressDict = [rsAddress2 resultDictionary];
            }
        
        if(residentAddressDict != nil)
            [dict setObject:residentAddressDict forKey:@"residentAddress"];
        
        if(surveyAddressDict != nil)
            [dict setObject:surveyAddressDict forKey:@"surveyAddress"];
        
    }];
    
    return dict;
}

@end
