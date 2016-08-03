//
//  NetImageView.m
//
//  Created by Athena on 11-10-28.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "NetImageView.h"
#import <CommonCrypto/CommonDigest.h>

#define SafePerformSelector(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

@interface NetImageView () {
    
}

@property (nonatomic, strong) NSURLConnection *mConnection;
@property (nonatomic, strong) NSMutableData *mWebData;

@end

@implementation NetImageView

@synthesize mbLoading, mLocalPath, mImageView, mImageType, miFileSize, miDownSize, delegate, OnImageLoad, OnLoadProgress, OnLoadFinish;

#pragma mark - Share Method

+ (NSString *)MD5String:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSString *)getLocalPathOfUrl:(NSString *)path {
    if (!path || ![path isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSRange headrange = [path rangeOfString:@"http:" options:NSCaseInsensitiveSearch];
    if (headrange.length == 0) {
        return path;
    }
    NSRange range = [path rangeOfString:@"." options:NSBackwardsSearch];
    NSString *extname = [path substringFromIndex:range.location+range.length];
    if (extname.length >= 4) {
        extname = @"jpg";
    }
    NSString *name = [NetImageView MD5String:path];
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *localpath = [docDir stringByAppendingPathComponent:name];
    return [localpath stringByAppendingFormat:@".%@", extname];
}

+ (void)ClearLocalFile:(NSString *)urlstr {
    NSString *filepath = [NetImageView getLocalPathOfUrl:urlstr];
    if (filepath && filepath.length>0) {
        NSLog(@"ClearLocalFile:%@, %@", urlstr, filepath);
        [[NSFileManager defaultManager] removeItemAtPath:filepath error:nil];
    }
}

- (UIImage *)getSubImage: (UIImage *)image :(CGRect)rect {
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    CGImageRelease(subImageRef);
    return smallImage;
}

- (UIImage *)ScaleImageToSize:(UIImage *)image :(CGSize)size {
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

#pragma mark - Public Method

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.mDefaultImage = [UIImage imageNamed:@"default_logo"];
        
        miDownSize = 0;
        mImageType = TImageType_FullFill;
        mbLoading = NO;
        self.mWebData = [[NSMutableData alloc] init];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:imageView];
        mImageView = imageView;
        
        mActView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        mActView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        mActView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        mActView.hidden = YES;
        [self addSubview:mActView];
    }
    return self;
}

- (void)setMbActShow:(BOOL)bShow {
    mActView.hidden = !bShow;
}

- (BOOL)mbActShow {
    return !mActView.hidden;
}

- (CGRect)getLocalFrame:(UIImage *)image :(TImageType)type {
    CGRect rect = self.bounds;
    int iWidth = self.frame.size.width;
    CGSize imageSize = image.size;
    int iHeight = self.frame.size.width*imageSize.height/imageSize.width;
    if (iHeight > self.frame.size.height) {
        iHeight = self.frame.size.height;
        iWidth = self.frame.size.height*imageSize.width/imageSize.height;
    }
    
    if (type == TImageType_AutoSize) {
        int iLeft = (self.frame.size.width-iWidth)/2;
        int iTop = (self.frame.size.height-iHeight)/2;
        rect = CGRectMake(iLeft, iTop, iWidth, iHeight);
    }
    else if (type == TImageType_OriginalSize) {
        iWidth = image.size.width;
        iHeight = image.size.height;
        int iLeft = (self.frame.size.width-iWidth)/2;
        int iTop = (self.frame.size.height-iHeight)/2;
        rect = CGRectMake(iLeft, iTop, iWidth, iHeight);
    }
    else if (type == TImageType_LeftAlign) {
        int iTop = (self.frame.size.height-iHeight)/2;
        rect = CGRectMake(0, iTop, iWidth, iHeight);
    }
    else if (type == TImageType_TopAlign) {
        int iLeft = (self.frame.size.width-iWidth)/2;
        rect = CGRectMake(iLeft, 0, iWidth, iHeight);
    }
    return rect;
}

- (CGRect)getLocalFrame:(UIImage *)image {
    return [self getLocalFrame:image :mImageType];
}

- (UIImage *)getLocalImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    if (mImageType == TImageType_CutFill) {
        int iWidth = image.size.width;
        int iHeight = iWidth*self.frame.size.height/self.frame.size.width;
        if (iHeight>image.size.height) {
            iHeight = image.size.height;
            iWidth = iHeight*self.frame.size.width/self.frame.size.height;
        }
        int iLeft = (image.size.width-iWidth)/2;
        int iTop = (image.size.height-iHeight)/2;
        
        CGRect rect = CGRectMake(iLeft, iTop, iWidth, iHeight);
        image = [self getSubImage:image :rect];
        if (iWidth>self.frame.size.width*2) {
            iWidth = self.frame.size.width*2;
            iHeight = self.frame.size.height*2;
            image = [self ScaleImageToSize:image :CGSizeMake(iWidth, iHeight)];
        }
    }
    return image;
}

- (BOOL)IsLocalPathExist {
    if (self.mLocalPath && [[NSFileManager defaultManager] fileExistsAtPath:self.mLocalPath]) {
        return YES;
    }
    return NO;
}

- (BOOL)showLocalImage {
    if ([self IsLocalPathExist]) {
#ifdef IMAGE_GIF
        UIImage *image = [UIImage imageWithContentsOfFile:self.mLocalPath playGif:YES];
#else
        UIImage *image = [UIImage imageWithContentsOfFile:self.mLocalPath];
#endif
        if (image) {
            mImageView.image = [self getLocalImage:image];
            mImageView.frame = [self getLocalFrame:image];
            if (delegate && OnImageLoad) {
                SafePerformSelector([delegate performSelector:OnImageLoad withObject:self]);
            }
            return YES;
        }
    }
    [self showDefaultImage];
    return NO;
}

- (void)showDefaultImage {
    @autoreleasepool {
        mImageView.image = [self getLocalImage:self.mDefaultImage];
        if (!self.mDefaultImage) {
            mImageView.frame = self.bounds;
        }
        else {
            mImageView.frame = [self getLocalFrame:self.mDefaultImage];
        }
    }
}

- (void)showLocalImage:(NSString *)imagename {
    self.mLocalPath = imagename;
    [self showLocalImage];
}

- (void)showDefaultImage:(UIImage *)image {
    self.mDefaultImage = image;
    [self showLocalImage];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (mImageView.image) {
        mImageView.frame = [self getLocalFrame:mImageView.image];
    }
}

#pragma mark - NSURLConnection

- (void)getImageByStr:(NSString *)path {
    [self cancel];
    self.mLocalPath = [NetImageView getLocalPathOfUrl:path];
    if (!path || path.length == 0 || [self IsLocalPathExist]) {
        [self showLocalImage];
        return;
    }
    [mActView startAnimating];
    mbLoading = YES;
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    self.mConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    NSLog(@"GetImageByStr:%@", path);
    
    //如果连接已经建好，则初始化data
    if (!self.mConnection) {
        [mActView stopAnimating];
        mbLoading = NO;
        NSLog(@"theConnection is NULL");
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    miFileSize = 0;
    miDownSize = 0;
    if(httpResponse && [httpResponse respondsToSelector:@selector(allHeaderFields)]){
        NSDictionary *HeaderFields = [httpResponse allHeaderFields];
        miFileSize = [[HeaderFields objectForKey:@"Content-Length"] longLongValue];
        //NSLog(@"iTotalSize:%lld, %@", miFileSize, HeaderFields);
    }
    if (self.mWebData) {
        [self.mWebData setLength: 0];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.mWebData) {
        [self.mWebData appendData:data];
    }
    miDownSize = self.mWebData.length;
    if (delegate && OnLoadProgress) {
        SafePerformSelector([delegate performSelector:OnLoadProgress withObject:self]);
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.mConnection = nil;
    [mActView stopAnimating];
    mbLoading = NO;
    if (delegate && OnLoadFinish) {
        SafePerformSelector([delegate performSelector:OnLoadFinish withObject:self]);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.mConnection = nil;
    [mActView stopAnimating];
    mbLoading = NO;
    if (delegate && OnLoadFinish) {
        SafePerformSelector([delegate performSelector:OnLoadFinish withObject:self]);
    }
    if (!self.mWebData || self.mWebData.length == 0) {
        return;
    }
    [self.mWebData writeToFile:self.mLocalPath atomically:YES];
    [self.mWebData setLength: 0];
    
    [self showLocalImage];
}

- (void)cancel {
    @autoreleasepool {
        self.mLocalPath = nil;
        if (self.mConnection) {
            [self.mConnection cancel];
            self.mConnection = nil;
        }
        if (self.mWebData) {
            [self.mWebData setLength: 0];
        }
        [self showDefaultImage];
        [mActView stopAnimating];
        mbLoading = NO;
    }
}

- (void)dealloc {
    self.mLocalPath = nil;
    if (self.mConnection) {
        [self.mConnection cancel];
        self.mConnection = nil;
    }
    if (self.mWebData) {
        self.mWebData = nil;
    }
    self.mDefaultImage = nil;
}

@end
