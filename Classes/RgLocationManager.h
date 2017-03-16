//
//  RgLocationManager.h
//  ringmail
//
//  Created by Mark Baxter on 3/1/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RgLocationManager : NSObject <CLLocationManagerDelegate>

+ (RgLocationManager *)sharedInstance;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *currentLocation;

- (void)requestWhenInUseAuthorization;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
