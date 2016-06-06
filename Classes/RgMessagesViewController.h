#import <JSQSystemSoundPlayer/JSQSystemSoundPlayer.h>

#import "JSQMessages.h"
#import "RgChatModelData.h"
#import "RgManager.h"
#import "ImagePickerViewController.h"

@interface RgMessagesViewController : JSQMessagesViewController <ImagePickerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) RgChatModelData *chatData;
@property (strong, nonatomic) NSString *chatRoom;
@property (strong, nonatomic) ImagePickerViewController* popoverController;
@property (strong, nonatomic) NSMutableDictionary* imageCache;
@property (strong, nonatomic) NSDictionary* questionData;
@property (strong, nonatomic) NSIndexPath* questionIndexpath;

- (void)receiveMessage:(NSString*)uuid;
- (void)sentMessage;
- (void)updateMessages:(NSString*)uuid;

@end
