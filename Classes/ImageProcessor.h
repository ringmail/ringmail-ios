//
//  ImageProcessor.h
//  InfojobOCR
//
//  Created by Paolo Tagliani on 06/06/12.
//  Copyright (c) 2012 26775. All rights reserved.
//

#ifndef InfojobOCR_ImageProcessor_h
#define InfojobOCR_ImageProcessor_h

#import <opencv2/opencv.hpp>

class ImageProcessor {
    
    typedef struct{
        int contador;
        double media;
    }cuadrante;

    
public:
    cv::Mat processImage(cv::Mat source);
};

#endif
