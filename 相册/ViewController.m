//
//  ViewController.m
//  相册
//
//  Created by md on 16/8/3.
//  Copyright © 2016年 HKQ. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIActionSheetDelegate>
{
    PhotoSelectManager *mPhotoSelect;
    NetImageView *headIamgeView;

}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    headIamgeView = [[NetImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    headIamgeView.userInteractionEnabled = YES;
    headIamgeView.layer.cornerRadius = 50;
    headIamgeView.layer.masksToBounds = YES;
    headIamgeView.backgroundColor = [UIColor redColor];
    [self.view addSubview:headIamgeView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headTapGesture:)];
    [headIamgeView addGestureRecognizer:tap];
    
    mPhotoSelect = [[PhotoSelectManager alloc] init];
    mPhotoSelect.delegate = self;
    mPhotoSelect.mbEdit = YES;
    mPhotoSelect.mRootCtrl = self;
    mPhotoSelect.OnPhotoSelect = @selector(onPhotoSelect:);
    
}
- (void)headTapGesture:(UITapGestureRecognizer *)tap
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拍照" otherButtonTitles:@"从相册选择", nil];
    [actionSheet showInView:self.view];

}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [mPhotoSelect TakePhoto:YES];
    }else if (buttonIndex == 1){
        [mPhotoSelect TakePhoto:NO];
    }
}

- (void)onPhotoSelect:(PhotoSelectManager *)sender
{
    self.mLocalPath = sender.mLocalPath;
    [headIamgeView getImageByStr:sender.mLocalPath];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
