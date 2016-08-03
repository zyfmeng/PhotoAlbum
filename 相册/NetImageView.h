//
//  NetImageView.h
//
//  Created by Athena on 11-10-28.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    TImageType_FullFill,
    TImageType_CutFill,
    TImageType_AutoSize,
    TImageType_OriginalSize,
    TImageType_LeftAlign,
    TImageType_TopAlign
}TImageType;

@interface NetImageView : UIView {
    UIActivityIndicatorView *mActView;
    TImageType mImageType;
    BOOL mbLoading;
    long long miFileSize;
    long long miDownSize;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) SEL OnImageLoad;
@property (nonatomic, assign) SEL OnLoadProgress;
@property (nonatomic, assign) SEL OnLoadFinish;
@property (nonatomic, assign) long long miFileSize;
@property (nonatomic, assign) long long miDownSize;
@property (nonatomic, assign) BOOL mbActShow;
@property (nonatomic, assign) TImageType mImageType;
@property (nonatomic, assign) UIImageView *mImageView;

@property (nonatomic, strong) id userinfo;
@property (nonatomic, strong) NSString *mLocalPath;
@property (nonatomic, strong) UIImage *mDefaultImage;
@property (readonly) BOOL mbLoading;


- (void)getImageByStr:(NSString *)path;
- (void)cancel;
- (BOOL)showLocalImage;
- (void)showLocalImage:(NSString *)imagename;
- (void)showDefaultImage:(UIImage *)image;

+ (void)ClearLocalFile:(NSString *)urlstr;
+ (NSString *)getLocalPathOfUrl:(NSString *)path;
+ (NSString *)MD5String:(NSString *)str;

@end
