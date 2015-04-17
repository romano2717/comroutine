//
//  Survey.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface Survey : NSObject
{
    Database *myDatabase;
}


- (NSArray *)fetchSurvey;

- (NSArray *)surveyDetailForSegment:(NSInteger)segment forSurveyId:(NSNumber *)surveyId forClientSurveyId:(NSNumber *)clientSurveyId;

- (NSDictionary *)surveyForId:(NSNumber *)surveyId forAddressType:(NSString *)addressType;

- (NSDictionary *)surveDetailForId:(NSNumber *)surveyId;

@end
