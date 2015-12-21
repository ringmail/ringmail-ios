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
    // connect horizontally oriented regions
    cv::Mat connected;
    morphKernel = getStructuringElement(cv::MORPH_RECT, cv::Size(1, 9));
    morphologyEx(bw, connected, cv::MORPH_CLOSE, morphKernel);
    
    // dilate
    morphKernel = getStructuringElement(cv::MORPH_CROSS, cv::Size(2,2));
    cv::Mat dilated;
    dilate(connected, dilated, morphKernel, cv::Point(-1,-1), 20);
    
    // find contours
    cv::Mat mask = cv::Mat::zeros(bw.size(), CV_8UC1);
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    findContours(dilated, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    //findContours(connected, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    cvtColor(dilated, rgb, CV_GRAY2RGB);
    
    // filter contours
    for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
    {
        cv::Rect rect = boundingRect(contours[idx]);
        cv::Mat maskROI(mask, rect);
        maskROI = cv::Scalar(0, 0, 0);
        // fill the contour
        drawContours(mask, contours, idx, cv::Scalar(255, 255, 255), CV_FILLED);
        // ratio of non-zero pixels in the filled region
        //double r = (double)countNonZero(maskROI)/(rect.width*rect.height);
        
        /* assume at least 45% of the area is filled if it contains text */
        /* these two conditions alone are not very robust. better to use something
         like the number of significant peaks in a horizontal projection as a third condition */
        /* constraints on region size */
        //if (r > .45 && (rect.height > 8 && rect.width > 8))
        //{
            rectangle(rgb, rect, cv::Scalar(0, 255, 0), 2);
        //}
    }
    return rgb;
}
