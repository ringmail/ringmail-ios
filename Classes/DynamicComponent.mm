#import "DynamicComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgManager.h"

@implementation DynamicComponent

@synthesize data;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
	//CGRect screenRect = [[UIScreen mainScreen] bounds];
	//CGFloat screenWidth = screenRect.size.width;
	//NSDictionary *place = data[@"component"];
    NSDictionary *cpdata = @{
        @"type": @"inset",
        @"top": @"0",
        @"bottom": @"10",
        @"left": @"10",
        @"right": @"10",
        @"component": @{
            @"type": @"stack",
            @"direction": @"Horizontal",
            @"alignItems": @"Start",
            @"size": @{
                //@"width": [NSString stringWithFormat:@"%f", screenWidth],
                @"width": @"100%",
                    },
            @"children": @[
                @{
                    @"type": @"label",
                    @"string": @"Hello",
                    @"font": @"system",
                    @"font_size": @"20.0",
                    @"color": @"#000000",
                    @"size": @{@"height": @"25"},
                    @"alignment": @"Left",
                },
                @{
                    @"type": @"netimage",
                    @"url": @"https://www-mf.ringxml.com/img/logo.png",
                    @"size": @{@"height": @"46.5", @"width": @"113"},
                },
                @{ @"type": @"flexGrow"},
                @{
                    @"type": @"image",
                    @"image": @"message_summary_video_normal.png",
                    @"size": @{@"height": @"25", @"width": @"27"},
                },
                @{
                    @"type": @"label",
                    @"string": @"World!",
                    @"font": @"system",
                    @"font_size": @"20.0",
                    @"color": @"#000000",
                    @"size": @{@"height": @"25"},
                    @"alignment": @"Right",
                }
            ],
        },
    };
    DynamicComponent *c = [super newWithComponent:[CKComponent new]];
    CKComponent* dynamic = [c buildComponent:cpdata context:context];
    c = [super newWithComponent:dynamic];
    [c setData:data];
    return c;
}

- (CKComponent*)buildComponent:(NSDictionary*)data context:(CardContext*)context
{
    NSString* type = data[@"type"];
    if ([type isEqualToString:@"inset"])
    {
        CGFloat left = 0.0;
        CGFloat right = 0.0;
        CGFloat top = 0.0;
        CGFloat bottom = 0.0;
        NSString *leftStr = data[@"left"];
        NSString *rightStr = data[@"right"];
        NSString *topStr = data[@"top"];
        NSString *bottomStr = data[@"bottom"];
        if (leftStr)
        {
            left = ([leftStr isEqualToString:@"Infinity"]) ? INFINITY : [leftStr floatValue];
        }
        if (rightStr)
        {
            right = ([rightStr isEqualToString:@"Infinity"]) ? INFINITY : [rightStr floatValue];
        }
        if (topStr)
        {
            top = ([topStr isEqualToString:@"Infinity"]) ? INFINITY : [topStr floatValue];
        }
        if (bottomStr)
        {
            bottom = ([bottomStr isEqualToString:@"Infinity"]) ? INFINITY : [bottomStr floatValue];
        }
        UIEdgeInsets insets = UIEdgeInsetsMake(top, bottom, left, right);
        return [CKInsetComponent newWithInsets:insets component:[self buildComponent:data[@"component"] context:context]];
    }
    else if ([type isEqualToString:@"label"])
    {
        CKLabelAttributes attrs = {
            .string = data[@"string"],
        };
        //attrs.string = data[@"string"];
        if (data[@"font"] && data[@"font_size"])
        {
            CGFloat size = [(NSString*)data[@"font_size"] floatValue];
            NSString *fontStr = data[@"font"];
            UIFont* font;
            if ([fontStr isEqualToString:@"system"])
            {
                font = [UIFont systemFontOfSize:size];
            }
            else if ([fontStr isEqualToString:@"system_bold"])
            {
                font = [UIFont boldSystemFontOfSize:size];
            }
            else if ([fontStr isEqualToString:@"system_italic"])
            {
                font = [UIFont italicSystemFontOfSize:size];
            }
            else
            {
                font = [UIFont fontWithName:fontStr size:size];
            }
            attrs.font = font;
        }
        if (data[@"color"])
        {
            attrs.color = [UIColor colorWithHex:data[@"color"]];
        }
        if (data[@"lineBreakMode"])
        {
            attrs.lineBreakMode = [self makeLineBreakMode:data[@"lineBreakMode"]];
        }
        if (data[@"maximumNumberOfLines"])
        {
            attrs.maximumNumberOfLines = [(NSString*)data[@"maximumNumberOfLines"] integerValue];
        }
        if (data[@"shadowOffset"])
        {
            attrs.shadowOffset = [self makeSize:data[@"shadowOffset"]];
        }
        if (data[@"shadowColor"])
        {
            attrs.shadowColor = [UIColor colorWithHex:data[@"shadowColor"]];
        }
        if (data[@"shadowOpacity"])
        {
            attrs.shadowOpacity = [(NSString*)data[@"shadowOpacity"] floatValue];
        }
        if (data[@"shadowRadius"])
        {
            attrs.shadowRadius = [(NSString*)data[@"shadowRadius"] floatValue];
        }
        if (data[@"alignment"])
        {
            attrs.alignment = [self makeTextAlignment:data[@"alignment"]];
        }
        if (data[@"firstLineHeadIndent"])
        {
            attrs.firstLineHeadIndent = [(NSString*)data[@"firstLineHeadIndent"] floatValue];
        }
        if (data[@"headIndent"])
        {
            attrs.headIndent = [(NSString*)data[@"headIndent"] floatValue];
        }
        if (data[@"tailIndent"])
        {
            attrs.tailIndent = [(NSString*)data[@"tailIndent"] floatValue];
        }
        if (data[@"lineHeightMultiple"])
        {
            attrs.lineHeightMultiple = [(NSString*)data[@"lineHeightMultiple"] floatValue];
        }
        if (data[@"maximumLineHeight"])
        {
            attrs.maximumLineHeight = [(NSString*)data[@"maximumLineHeight"] floatValue];
        }
        if (data[@"lineSpacing"])
        {
            attrs.lineSpacing = [(NSString*)data[@"lineSpacing"] floatValue];
        }
        if (data[@"paragraphSpacing"])
        {
            attrs.paragraphSpacing = [(NSString*)data[@"paragraphSpacing"] floatValue];
        }
        if (data[@"minimumLineHeight"])
        {
            attrs.paragraphSpacingBefore = [(NSString*)data[@"paragraphSpacingBefore"] floatValue];
        }
        //const CKViewComponentAttributeValueMap viewattrs = [self makeViewAttributeMap:data[@"viewAttributes"]];
        const CKViewComponentAttributeValueMap viewattrs = {
            {@selector(setBackgroundColor:), [UIColor clearColor]},
            {@selector(setUserInteractionEnabled:), @NO},
        };
        CKComponentSize size = [self makeComponentSize:data[@"size"]];
        return [CKLabelComponent newWithLabelAttributes:attrs viewAttributes:viewattrs size:size];
    }
    // images
    else if ([type isEqualToString:@"image"])
    {
        CKComponentSize size = [self makeComponentSize:data[@"size"]];
        return [CKImageComponent newWithImage:[context imageNamed:data[@"image"]] size:size];
    }
    else if ([type isEqualToString:@"netimage"])
    {
        CKComponentSize size = [self makeComponentSize:data[@"size"]];
        return [CKNetworkImageComponent newWithURL:data[@"url"] imageDownloader:context.imageDownloader scenePath:nil size:size options:{} attributes:{}];
    }
    // layouts
    else if ([type isEqualToString:@"stack"])
    {
        const CKComponentViewConfiguration view = [self makeViewConfig:data];
        CKComponentSize size = [self makeComponentSize:data[@"size"]];
        std::vector<CKStackLayoutComponentChild> children;
        NSArray* childArray = data[@"children"];
        for (NSDictionary* item in childArray)
        {
            if ([(NSString*)item[@"type"] isEqualToString:@"flexGrow"])
            {
                children.push_back({.flexGrow = YES, .component = [CKComponent new]});
            }
            else
            {
                children.push_back({[self buildComponent:item context:context]});
            }
        }
        CKStackLayoutComponentStyle style = {};
        style.spacing = [(NSString*)data[@"spacing"] floatValue];
        NSString *dirStr = data[@"direction"];
        if ([dirStr isEqualToString:@"Vertical"])
        {
            style.direction = CKStackLayoutDirectionVertical;
        }
        else if ([dirStr isEqualToString:@"Horizontal"])
        {
            style.direction = CKStackLayoutDirectionHorizontal;
        }
        NSString *alignStr = data[@"alignItems"];
        if ([alignStr isEqualToString:@"Start"])
        {
            style.alignItems = CKStackLayoutAlignItemsStart;
        }
        else if ([alignStr isEqualToString:@"End"])
        {
            style.alignItems = CKStackLayoutAlignItemsEnd;
        }
        else if ([alignStr isEqualToString:@"Center"])
        {
            style.alignItems = CKStackLayoutAlignItemsCenter;
        }
        else if ([alignStr isEqualToString:@"Stretch"])
        {
            style.alignItems = CKStackLayoutAlignItemsStretch;
        }
        NSString *justifyStr = data[@"justifyContent"];
        if ([justifyStr isEqualToString:@"Start"])
        {
            style.justifyContent = CKStackLayoutJustifyContentStart;
        }
        else if ([justifyStr isEqualToString:@"Center"])
        {
            style.justifyContent = CKStackLayoutJustifyContentCenter;
        }
        else if ([justifyStr isEqualToString:@"End"])
        {
            style.justifyContent = CKStackLayoutJustifyContentEnd;
        }
        return [CKStackLayoutComponent newWithView:view size:size style:style children:children];
    }
    return nil;
}

- (CKComponentViewConfiguration)makeViewConfig:(NSDictionary*)data
{
    CKComponentViewConfiguration cfg = {
        [UIView class],
        [self makeViewAttributeMap:data[@"viewAttributes"]],
    };
    return cfg;
}

- (CKViewComponentAttributeValueMap)makeViewAttributeMap:(NSDictionary*)data
{
    CKViewComponentAttributeValueMap map = {};
    return map;
}

- (CKComponentSize)makeComponentSize:(NSDictionary*)data
{
    CKComponentSize size = {};
    if (data[@"width"])
    {
        size.width = [self makeRelativeDimension:data[@"width"]];
    }
    if (data[@"height"])
    {
        size.height = [self makeRelativeDimension:data[@"height"]];
    }
    if (data[@"minWidth"])
    {
        size.minWidth = [self makeRelativeDimension:data[@"minWidth"]];
    }
    if (data[@"minHeight"])
    {
        size.minHeight = [self makeRelativeDimension:data[@"minHeight"]];
    }
    if (data[@"maxWidth"])
    {
        size.maxWidth = [self makeRelativeDimension:data[@"maxWidth"]];
    }
    if (data[@"maxHeight"])
    {
        size.maxHeight = [self makeRelativeDimension:data[@"maxHeight"]];
    }
    return size;
}

- (CKRelativeDimension)makeRelativeDimension:(NSString*)data
{
    NSString *lc = [data substringFromIndex:[data length]];
    if ([lc isEqualToString:@"%"])
    {
        NSString *num = [data substringToIndex:[data length] - 1];
        return CKRelativeDimension::Percent([num floatValue]);
    }
    else if ([data isEqualToString:@"Auto"])
    {
        return CKRelativeDimension::Auto();
    }
    else
    {
        CKRelativeDimension d = [data integerValue];
        return d;
    }
}

- (CGSize)makeSize:(NSDictionary*)data
{
    CGFloat height = 0;
    CGFloat width = 0;
    NSString* heightStr = data[@"height"];
    NSString* widthStr = data[@"width"];
    if (heightStr)
    {
        height = [heightStr floatValue];
    }
    if (widthStr)
    {
        width = [widthStr floatValue];
    }
    return CGSizeMake(width, height);
}

- (NSLineBreakMode)makeLineBreakMode:(NSString*)data
{
    NSLineBreakMode mode = NSLineBreakByWordWrapping;
    if ([data isEqualToString:@"ByWordWrapping"])
    {
        mode = NSLineBreakByWordWrapping;
    }
    else if ([data isEqualToString:@"ByCharWrapping"])
    {
        mode = NSLineBreakByCharWrapping;
    }
    else if ([data isEqualToString:@"ByClipping"])
    {
        mode = NSLineBreakByClipping;
    }
    else if ([data isEqualToString:@"ByTruncatingHead"])
    {
        mode = NSLineBreakByTruncatingHead;
    }
    else if ([data isEqualToString:@"ByTruncatingTail"])
    {
        mode = NSLineBreakByTruncatingTail;
    }
    else if ([data isEqualToString:@"ByTruncatingMiddle"])
    {
        mode = NSLineBreakByTruncatingMiddle;
    }
    return mode;
}

- (NSTextAlignment)makeTextAlignment:(NSString*)data
{
    NSTextAlignment align = NSTextAlignmentLeft;
    if ([data isEqualToString:@"Left"])
    {
        align = NSTextAlignmentLeft;
    }
    else if ([data isEqualToString:@"Right"])
    {
        align = NSTextAlignmentRight;
    }
    else if ([data isEqualToString:@"Center"])
    {
        align = NSTextAlignmentCenter;
    }
    else if ([data isEqualToString:@"Justified"])
    {
        align = NSTextAlignmentJustified;
    }
    else if ([data isEqualToString:@"Natural"])
    {
        align = NSTextAlignmentNatural;
    }
    return align;
}

@end
