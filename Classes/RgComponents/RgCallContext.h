#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RgCallContext : NSObject

- (instancetype)initWithImages:(NSDictionary *)addImages;
- (instancetype)initWithImageNames:(NSSet *)imageNames;

- (UIImage *)imageNamed:(NSString *)imageName;

@end
