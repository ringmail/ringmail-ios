//
//  RgLocationManager.m
//  ringmail
//
//  Created by Mark Baxter on 3/1/17.
//
//

#import "RgLocationManager.h"

@implementation RgLocationManager

- (id)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

+ (RgLocationManager *)sharedInstance
{
    static RgLocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    CLLocation* location = [locations lastObject];

    self.currentLocation = location;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
//    NSLog(@"Location service failed with error %@", error);
}


- (void)requestWhenInUseAuthorization
{
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)startUpdatingLocation
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}


@end
