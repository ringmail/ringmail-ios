#import "JSQMessages.h"
#import "RgChatModelData.h"
#import "RgManager.h"
#import "ImagePickerViewController.h"

@interface RgMessagesViewController : JSQMessagesViewController <ImagePickerDelegate>

@property (strong, nonatomic) RgChatModelData *chatData;
@property (strong, nonatomic) NSString *chatRoom;
@property (strong, nonatomic) ImagePickerViewController* popoverController;
@property (strong, nonatomic) NSMutableDictionary* imageCache;

- (void)receiveMessage;
- (void)sentMessage;
- (void)updateMessages;

@end
