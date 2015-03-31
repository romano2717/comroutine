//
//  PostInfoViewController.m
//  comress
//
//  Created by Diffy Romano on 14/2/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "PostInfoViewController.h"

@interface PostInfoViewController ()

@end

@implementation PostInfoViewController

@synthesize postInfoDict,theCollectionView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    contract_type = [[Contract_type alloc] init];
    
    self.issueLabel.text = [[postInfoDict objectForKey:@"post"] valueForKey:@"post_topic"];
    
    self.issueByLabel.text = [NSString stringWithFormat:@"Issue by: %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"post_by"]];
    
    double timeStamp = [[[postInfoDict objectForKey:@"post"] valueForKey:@"post_date"] doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"dd-MMM-YYYY HH:mm:ss";
    NSString *dateString = [formatter stringFromDate:date];
    
    self.dateLabel.text = dateString;
    
    NSString *contract = [contract_type contractDescriptionForId:[NSNumber numberWithInt:[[[postInfoDict objectForKey:@"post"] valueForKey:@"contract_type"] intValue]]];
    self.contractTypeLabel.text = contract;
    
    self.locationLabel.text = [NSString stringWithFormat:@"%@ %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"postal_code"],[[postInfoDict objectForKey:@"post"] valueForKey:@"address"]];

    
    if([[[postInfoDict objectForKey:@"post"] valueForKey:@"severity"] intValue] == 2)
        self.severityLabel.text = @"Routine";
    else
    {
        self.severityLabel.text = @"Severe";
        self.severityLabel.textColor = [UIColor redColor];
        self.severityLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    }
    

    self.levelLabel.text = [NSString stringWithFormat:@"Level: %@",[[postInfoDict objectForKey:@"post"] valueForKey:@"level"]];
    
    NSArray *imagesDictArr = [postInfoDict objectForKey:@"images"];
    
    self.imagesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < imagesDictArr.count; i++) {
        NSDictionary *imagesDict = [imagesDictArr objectAtIndex:i];
        
        if([imagesDict valueForKey:@"client_post_id"] != [NSNull null] || [imagesDict valueForKey:@"post_id"] != [NSNull null]) //only allow post images
        {
            NSString *imagePath = [imagesDict valueForKey:@"image_path"];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths objectAtIndex:0];
            NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            
            [self.imagesArray addObject:image];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [theCollectionView flashScrollIndicators];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"push_view_image"])
    {
        NSIndexPath *indexPath = (NSIndexPath *)sender;
        NSInteger index = indexPath.row;
        
        ImagePreviewViewController *imagPrev = [segue destinationViewController];
        
        imagPrev.image = (UIImage *)[self.imagesArray objectAtIndex:index];;
        
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.selected = YES;
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    
    // Configure the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    imageView.image = (UIImage *)[self.imagesArray objectAtIndex:indexPath.row];
    
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
    
    cell.contentView.backgroundColor = [UIColor blueColor];
    
    [self performSegueWithIdentifier:@"push_view_image" sender:indexPath];
}


@end
