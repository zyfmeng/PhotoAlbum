//
//  PhotoSelectManager.m
//  TestPinBang
//
//  Created by Hepburn Alex on 13-5-30.
//  Copyright (c) 2013年 Hepburn Alex. All rights reserved.
//

#import "PhotoSelectManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>


//iPhone
#define IsRetina    CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size)
#define IsiPhone5   CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size)
#define IsiPhone6   CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size)
#define IsiPhone6Plus   CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size)
//iPad
#define IsiPadUI    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IsiPad      CGSizeEqualToSize(CGSizeMake(768, 1024), [[UIScreen mainScreen] currentMode].size)

#define SafePerformSelector(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)



#ifndef SAFE_RELEASE

#if __has_feature(objc_arc)
#define SAFE_RELEASE(x)
#else
#define SAFE_RELEASE(x) ([(x) release])
#endif

#endif

#ifndef SAFE_SUPER_DEALLOC

#if __has_feature(objc_arc)
#define SAFE_SUPER_DEALLOC()
#else
#define SAFE_SUPER_DEALLOC() ([super dealloc])
#endif

#endif

#ifndef SAFE_AUTORELEASE

#if __has_feature(objc_arc)
#define SAFE_AUTORELEASE(x) x
#else
#define SAFE_AUTORELEASE(x) ([(x) autorelease])
#endif

#endif


@implementation PhotoSelectManager

@synthesize mRootCtrl, mDefaultName, delegate, OnPhotoSelect, OnImageSelect, OnDataSelect, mLocalPath, miWidth, miHeight, mbEdit,popoverController;

- (id)init {
    self = [super init];
    if (self) {
        mbEdit = YES;
        miWidth = 400;
        miHeight = 550;
        _mQuality = 0.95;
        self.mDefaultName = @"fabuhuati.jpg";
    }
    return self;
}

- (void)dealloc {
    self.mRootCtrl = nil;
    self.mDefaultName = nil;
    SAFE_SUPER_DEALLOC();
}

- (BOOL)TakePhoto:(BOOL)bCamera {
    if (!mRootCtrl) {
        return NO;
    }
    if (!bCamera && [UIImagePickerController isSourceTypeAvailable:
                     UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"找不到相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
        SAFE_RELEASE(alertView);
        return NO;
    }
    if (bCamera && [UIImagePickerController isSourceTypeAvailable:
                    UIImagePickerControllerSourceTypeCamera] == NO) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"找不到摄像头" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
        SAFE_RELEASE(alertView);
        return NO;
    }
    UIImagePickerController *imageCtrl = [[UIImagePickerController alloc] init];
    if (bCamera) {
		imageCtrl.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        imageCtrl.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imageCtrl.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    imageCtrl.allowsEditing = mbEdit;
    imageCtrl.delegate = self;
    
    
    if (IsiPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imageCtrl];
         self.popoverController = popover;
        [self.popoverController presentPopoverFromRect:CGRectMake(200, 700, 60, 200) inView:mRootCtrl.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
    else{
        [mRootCtrl presentViewController:imageCtrl animated:YES completion:nil];
    }
    
    return YES;
}

//图片缩放
- (UIImage *)scaleToSize:(UIImage *)image :(CGSize)newsize {
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(newsize);
    
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, newsize.width, newsize.height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

- (NSString *)mLocalPath {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [docDir stringByAppendingPathComponent:self.mDefaultName];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo: (NSDictionary *) info {
    // 图片类型
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage]) {
        UIImage* image = nil;
        if (mbEdit) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        }
        else {
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        [self getImageData:info];
        if (delegate && OnImageSelect) {
            SafePerformSelector([delegate performSelector:OnImageSelect withObject:image]);
        }
        else {
            if (miWidth > 0 && miHeight > 0) {
                int iWidth = image.size.width;
                int iHeight = image.size.height;
                if (iWidth>miWidth) {
                    iWidth = miWidth;
                    iHeight = image.size.height*iWidth/image.size.width;
                    if (iHeight>miHeight && miHeight>0) {
                        iHeight = miHeight;
                        iWidth = image.size.width*iHeight/image.size.height;
                    }
                }
                image = [self scaleToSize:image :CGSizeMake(iWidth, iHeight)];
                NSLog(@"%f, %f", image.size.width, image.size.height);
            }
            NSString *imagename = self.mLocalPath;
            NSData *data = UIImageJPEGRepresentation(image, _mQuality);
            [data writeToFile:imagename atomically:YES];
            if (delegate && OnPhotoSelect) {
                SafePerformSelector([delegate performSelector:OnPhotoSelect withObject:self]);
            }
        }
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (IsiPad) {
        [popoverController dismissPopoverAnimated:YES];
    }

}

- (void)getImageData:(NSDictionary *)info {
    if (!delegate || !OnDataSelect) {
        return;
    }
    NSURL *imageRefURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    ALAssetsLibrary* assetLibrary = [[ALAssetsLibrary alloc] init];
    void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *) = ^(ALAsset *asset) {
        
        if (asset != nil) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *imageBuffer = (Byte*)malloc((size_t)rep.size);
            NSUInteger bufferSize = [rep getBytes:imageBuffer fromOffset:0.0 length:(size_t)rep.size error:nil];
            NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
            if (delegate && OnDataSelect) {
                SafePerformSelector([delegate performSelector:OnDataSelect withObject:imageData]);
            }
        }
        else {
        }
    };
    
    [assetLibrary assetForURL:imageRefURL
                  resultBlock:ALAssetsLibraryAssetForURLResultBlock
                 failureBlock:^(NSError *error){
                 }];
    SAFE_RELEASE(assetLibrary);
}

@end
