//
//  CreateIssueViewController.h
//  comress
//
//  Created by Diffy Romano on 6/4/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppWideImports.h"
#import "Database.h"
#import "MPGTextField.h"

@interface CreateIssueViewController : UIViewController
{
    Database *myDatabase;
}

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@property (nonatomic, weak) IBOutlet MPGTextField *postalCodeTextField;
@property (nonatomic, weak) IBOutlet UILabel *postalCodeLabel;
@property (nonatomic, weak) IBOutlet UIButton *postalCodesNearYouButton;
@property (nonatomic, weak) IBOutlet MPGTextField *addressTextField;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UITextField *levelTextField;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UIButton *severityBtn;
@property (nonatomic, weak) IBOutlet UIButton *contractTypeBtn;
@property (nonatomic, weak) IBOutlet UIButton *addPhotosButton;
@property (nonatomic, strong) NSNumber *blockId;



@property (nonatomic, strong) NSNumber *surveyId;

@property (nonatomic, strong) NSDictionary *surveyDetail;
@property (nonatomic, strong) NSString *postalCode;

@end
