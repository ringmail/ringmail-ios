//
//  ImageProcessor.cpp
//  InfojobOCR
//
//  Created by Paolo Tagliani on 06/06/12.
//  Copyright (c) 2012 26775. All rights reserved.
//

#include <iostream>
#include "ImageProcessor.h"

#import <opencv2/opencv.hpp>

/*cv::Mat ImageProcessor::processImage(cv::Mat source)
{
    cv::Mat rgb;
    // downsample and use it for processing
    pyrDown(source, rgb);
    cv::Mat small;
    cvtColor(rgb, small, CV_BGR2GRAY);
    // morphological gradient
    cv::Mat grad;
    cv::Mat morphKernel = getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
    morphologyEx(small, grad, cv::MORPH_GRADIENT, morphKernel);
    // binarize
    cv::Mat bw;
    threshold(grad, bw, 0.0, 255.0, cv::THRESH_BINARY | cv::THRESH_OTSU);
    
    std::vector<std::vector<cv::Point> > contours;
    
//    findContours(bw, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
//    drawContours(bw, contours, -1, cv::Scalar(255), CV_FILLED);
    
    // connect horizontally oriented regions
    cv::Mat connected;
    morphKernel = getStructuringElement(cv::MORPH_RECT, cv::Size(1, 9));
    morphologyEx(bw, connected, cv::MORPH_CLOSE, morphKernel);
    
    // find contours
    cv::Mat mask = cv::Mat::zeros(bw.size(), CV_8UC1);
    //std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    findContours(connected, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    cvtColor(bw, rgb, CV_GRAY2RGB);
    
    // filter contours
    
    cv::Point ftl = cv::Point(bw.size().height, bw.size().width);
    cv::Point fbr = cv::Point(0, 0);
    
    for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
    {
        cv::Rect rect = boundingRect(contours[idx]);
        
        ftl.x = MIN(ftl.x, rect.tl().x);
        ftl.y = MIN(ftl.y, rect.tl().y);
        fbr.x = MAX(fbr.x, rect.br().x);
        fbr.y = MAX(fbr.y, rect.br().y);
    }
    
    //cv::Rect outer = cv::Rect(ftl, fbr);
    
    //cv::Mat croppedRef(rgb, outer);
    //cv::Mat cropped;
    //croppedRef.copyTo(cropped);
    
    //cv::Mat inverse = cv::Scalar::all(255) - cropped;
    
    cv::Mat inverse = cv::Scalar::all(255) - bw;
    
    return inverse;
}
*/

/*cv::Mat ImageProcessor::processImage(cv::Mat source)
{
    cv::Mat rgb;
    // downsample and use it for processing
    pyrDown(source, rgb);
    cv::Mat small;
    cvtColor(rgb, small, CV_BGR2GRAY);
    cv::Mat thresh;
    threshold(small, thresh, 150, 255, cv::THRESH_BINARY_INV);
    cv::Mat morphKernel = getStructuringElement(cv::MORPH_CROSS, cv::Size(3, 3));
    cv::Mat dilated;
    dilate(thresh, dilated, morphKernel, cv::Point(-1,-1), 13, cv::BORDER_DEFAULT, cv::morphologyDefaultBorderValue());
    
    
    cv::Mat ctr;
    std::vector<cv::Vec4i> hierarchy;
    std::vector<std::vector<cv::Point> > contours;
    findContours(dilated, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cv::Point(0, 0));
    
    // filter contours
    
    cv::Point ftl = cv::Point(dilated.size().height, dilated.size().width);
    cv::Point fbr = cv::Point(0, 0);
    
    for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
    {
        cv::Rect rect = boundingRect(contours[idx]);
        
        ftl.x = MIN(ftl.x, rect.tl().x);
        ftl.y = MIN(ftl.y, rect.tl().y);
        fbr.x = MAX(fbr.x, rect.br().x);
        fbr.y = MAX(fbr.y, rect.br().y);
    }
    
    cv::Rect final(ftl, fbr);
    
    rectangle(rgb, final, cv::Scalar(0, 255, 0), 2);
    
    return rgb;
}*/

cv::Mat ImageProcessor::processImage(cv::Mat source)
{
    cv::Mat rgb;
    // downsample and use it for processing
    pyrDown(source, rgb);
    cv::Mat small;
    cvtColor(rgb, small, CV_BGR2GRAY);
    // morphological gradient
    cv::Mat grad;
    cv::Mat morphKernel = getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
    morphologyEx(small, grad, cv::MORPH_GRADIENT, morphKernel);
    // binarize
    cv::Mat bw;
    threshold(grad, bw, 0.0, 255.0, cv::THRESH_BINARY | cv::THRESH_OTSU);
    
    std::vector<std::vector<cv::Point> > contours;
    
    //    findContours(bw, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    //    drawContours(bw, contours, -1, cv::Scalar(255), CV_FILLED);
    
    // connect horizontally oriented regions
    cv::Mat connected;
    morphKernel = getStructuringElement(cv::MORPH_RECT, cv::Size(1, 9));
    morphologyEx(bw, connected, cv::MORPH_CLOSE, morphKernel);
    
    // find contours
    cv::Mat mask = cv::Mat::zeros(bw.size(), CV_8UC1);
    //std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    findContours(connected, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    //cvtColor(bw, rgb, CV_GRAY2RGB);
    
    // filter contours
    
    cv::Point ftl = cv::Point(bw.size().height, bw.size().width);
    cv::Point fbr = cv::Point(0, 0);
    
    for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
    {
        cv::Rect rect = boundingRect(contours[idx]);
        cv::Mat maskROI(mask, rect);
        maskROI = cv::Scalar(0, 0, 0);
        // fill the contour
        drawContours(mask, contours, idx, cv::Scalar(255, 255, 255), CV_FILLED);
        double r = (double)countNonZero(maskROI)/(rect.width*rect.height);
        fprintf(stderr, "Rect: %f (%d, %d)", r, rect.height, rect.width);
        if (r > .35 && (rect.height > 8 && rect.width > 8))
        {
            fprintf(stderr, " (+)");
            ftl.x = MIN(ftl.x, rect.tl().x);
            ftl.y = MIN(ftl.y, rect.tl().y);
            fbr.x = MAX(fbr.x, rect.br().x);
            fbr.y = MAX(fbr.y, rect.br().y);
        }
        fprintf(stderr, "\n");
    }
    
    //cv::Mat inverse = cv::Scalar::all(255) - bw;
    
    cv::Rect final(ftl, fbr);
    
    cv::Mat croppedRef(rgb, final);
    cv::Mat cropped;
    croppedRef.copyTo(cropped);
    
    return cropped;
}

