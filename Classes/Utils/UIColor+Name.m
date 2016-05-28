//
//  UIColor+Name.m
//
//

#import "NSObject+NSPerformSelector.h"
#import "UIColor+Name.h"
#import "Colours.h"

@implementation UIColor (Name)

+ (NSDictionary*) colourDict {
	static NSDictionary* colourData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		colourData = @{
            @"infoBlue": @1,
            @"success": @1,
            @"warning": @1,
            @"danger": @1,
            @"antiqueWhite": @1,
            @"oldLace": @1,
            @"ivory": @1,
            @"seashell": @1,
            @"ghostWhite": @1,
            @"snow": @1,
            @"linen": @1,
            @"black25Percent": @1,
            @"black50Percent": @1,
            @"black75Percent": @1,
            @"warmGray": @1,
            @"coolGray": @1,
            @"charcoal": @1,
            @"teal": @1,
            @"steelBlue": @1,
            @"robinEgg": @1,
            @"pastelBlue": @1,
            @"turquoise": @1,
            @"skyBlue": @1,
            @"indigo": @1,
            @"denim": @1,
            @"blueberry": @1,
            @"cornflower": @1,
            @"babyBlue": @1,
            @"midnightBlue": @1,
            @"fadedBlue": @1,
            @"iceberg": @1,
            @"wave": @1,
            @"emerald": @1,
            @"grass": @1,
            @"pastelGreen": @1,
            @"seafoam": @1,
            @"paleGreen": @1,
            @"cactusGreen": @1,
            @"chartreuse": @1,
            @"hollyGreen": @1,
            @"olive": @1,
            @"oliveDrab": @1,
            @"moneyGreen": @1,
            @"honeydew": @1,
            @"lime": @1,
            @"cardTable": @1,
            @"salmon": @1,
            @"brickRed": @1,
            @"easterPink": @1,
            @"grapefruit": @1,
            @"pink": @1,
            @"indianRed": @1,
            @"strawberry": @1,
            @"coral": @1,
            @"maroon": @1,
            @"watermelon": @1,
            @"tomato": @1,
            @"pinkLipstick": @1,
            @"paleRose": @1,
            @"crimson": @1,
            @"eggplant": @1,
            @"pastelPurple": @1,
            @"palePurple": @1,
            @"coolPurple": @1,
            @"violet": @1,
            @"plum": @1,
            @"lavender": @1,
            @"raspberry": @1,
            @"fuschia": @1,
            @"grape": @1,
            @"periwinkle": @1,
            @"orchid": @1,
            @"goldenrod": @1,
            @"yellowGreen": @1,
            @"banana": @1,
            @"mustard": @1,
            @"buttermilk": @1,
            @"gold": @1,
            @"cream": @1,
            @"lightCream": @1,
            @"wheat": @1,
            @"beige": @1,
            @"peach": @1,
            @"burntOrange": @1,
            @"pastelOrange": @1,
            @"cantaloupe": @1,
            @"carrot": @1,
            @"mandarin": @1,
            @"chiliPowder": @1,
            @"burntSienna": @1,
            @"chocolate": @1,
            @"coffee": @1,
            @"cinnamon": @1,
            @"almond": @1,
            @"eggshell": @1,
            @"sand": @1,
            @"mud": @1,
            @"sienna": @1,
            @"dust": @1,
		};
	});
	return colourData;
}
		
+ (UIColor*)colour:(NSString*)name {
	NSDictionary* colours = [UIColor colourDict];
	if (colours[name] != nil)
	{
		NSString* fn = [NSString stringWithFormat:@"%@Color", name];
		SEL s = NSSelectorFromString(fn);
		return [NSObject target:[UIColor class] performSelector:s];
	}
	return nil;
}

@end
