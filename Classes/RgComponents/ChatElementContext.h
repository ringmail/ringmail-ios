#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ChatElementContext : NSObject

- (instancetype)initWithImages:(NSDictionary *)addImages;

- (UIImage *)imageNamed:(NSString *)imageName;

@end
