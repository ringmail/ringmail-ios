#import "FavoriteModelController.h"

#import <UIKit/UIColor.h>

#import "Card.h"
#import "CardsPage.h"
#import "LinphoneManager.h"

@implementation FavoriteModelController

- (NSArray *)readMainList
{
    NSArray* list = [[[LinphoneManager instance] chatManager] dbGetMainList:nil favorites:YES];
    return [self buildCards:list];
}

@end
