//
//  ImageProcessingImplementation.m
//  InfojobOCR
//
//  Created by Paolo Tagliani on 10/05/12.
//  Copyright (c) 2012 26775. All rights reserved.
//

#import "ImageProcessingImplementation.h"
#import "ImageProcessor.h"
#import "UIImage+OpenCV.h"
#import <opencv2/opencv.hpp>

@implementation ImageProcessingImplementation

/*- (NSString*) pathToLangugeFIle{
    
    // Set up the tessdata path. This is included in the application bundle
    // but is copied to the Documents directory on the first run.
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:dataPath]) {
        // get the path to the app bundle (with the tessdata dir)
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
        if (tessdataPath) {
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    
    return dataPath;
}*/

- (UIImage*) processImage:(UIImage*)src
{
    ImageProcessor processor;
    UIImage *processed = [UIImage imageWithCVMat:processor.processImage([src CVMat])];
    return processed;
}


/*- (NSString*) OCRImage:(UIImage*)src{
    
    // init the tesseract engine.
    tesseract::TessBaseAPI *tesseract = new tesseract::TessBaseAPI();
    
    tesseract->Init([[self pathToLangugeFIle] cStringUsingEncoding:NSUTF8StringEncoding], "eng");
    
    //Pass the UIIMage to cvmat and pass the sequence of pixel to tesseract

    cv::Mat toOCR=[src CVGrayscaleMat];
    
    NSLog(@"%d", toOCR.channels());
    
    tesseract->SetImage((uchar*)toOCR.data, toOCR.size().width, toOCR.size().height
                        , toOCR.channels(), toOCR.step1());
    
    tesseract->Recognize(NULL);
    
    char* utf8Text = tesseract->GetUTF8Text();
    
    return [NSString stringWithUTF8String:utf8Text];
    
}*/

@end
