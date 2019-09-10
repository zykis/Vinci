////
////  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
////
//
//NS_ASSUME_NONNULL_BEGIN
//
//extern const CGFloat kOWSMessageCellCornerRadius_Large;
//extern const CGFloat kOWSMessageCellCornerRadius_Small;
//
//typedef NS_OPTIONS(NSUInteger, OWSDirectionalRectCorner) {
//    OWSDirectionalRectCornerTopLeading = 1 << 0,
//    OWSDirectionalRectCornerTopTrailing = 1 << 1,
//    OWSDirectionalRectCornerBottomLeading = 1 << 2,
//    OWSDirectionalRectCornerBottomTrailing = 1 << 3,
//    OWSDirectionalRectCornerAllCorners = ~0UL
//};
//
//@class OWSBubbleView;
//
//@protocol OWSBubbleViewPartner <NSObject>
//
//- (void)updateLayers;
//
//- (void)setBubbleView:(nullable OWSBubbleView *)bubbleView;
//
//@end
//
//#pragma mark -
//
//@interface OWSBubbleView : UIView
//
//+ (UIBezierPath *)roundedBezierRectWithBubbleTop:(CGFloat)bubbleTop
//                                      bubbleLeft:(CGFloat)bubbleLeft
//                                    bubbleBottom:(CGFloat)bubbleBottom
//                                     bubbleRight:(CGFloat)bubbleRight
//                               sharpCornerRadius:(CGFloat)sharpCornerRadius
//                                wideCornerRadius:(CGFloat)wideCornerRadius
//                                    sharpCorners:(OWSDirectionalRectCorner)sharpCorners;
//
//@property (nonatomic, nullable) UIColor *bubbleColor;
//
//@property (nonatomic) OWSDirectionalRectCorner sharpCorners;
//
//- (UIBezierPath *)maskPath;
//
//#pragma mark - Coordination
//
//- (void)addPartnerView:(id<OWSBubbleViewPartner>)view;
//
//- (void)clearPartnerViews;
//
//- (void)updatePartnerViews;
//
//- (CGFloat)minWidth;
//
//- (CGFloat)minHeight;
//
//@end
//
//NS_ASSUME_NONNULL_END

//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kOWSMessageCellCornerRadius_Large;
extern const CGFloat kOWSMessageCellCornerRadius_Small;

typedef NS_OPTIONS(NSUInteger, OWSDirectionalRectCorner) {
    OWSDirectionalRectCornerTopLeading = 1 << 0,
    OWSDirectionalRectCornerTopTrailing = 1 << 1,
    OWSDirectionalRectCornerBottomLeading = 1 << 2,
    OWSDirectionalRectCornerBottomTrailing = 1 << 3,
    VCIDirectionalRectCornerBottomLeadingThorn = 1 << 4,
    VCIDirectionalRectCornerBottomTrailingThorn = 1 << 5,
    OWSDirectionalRectCornerAllCorners = ~0UL
};

@class OWSBubbleView;

@protocol OWSBubbleViewPartner <NSObject>

- (void)updateLayers;

- (void)setBubbleView:(nullable OWSBubbleView *)bubbleView;

@end

#pragma mark -

@interface OWSBubbleView : UIView

+ (UIBezierPath *)roundedBezierRectWithBubbleTop:(CGFloat)bubbleTop
                                      bubbleLeft:(CGFloat)bubbleLeft
                                    bubbleBottom:(CGFloat)bubbleBottom
                                     bubbleRight:(CGFloat)bubbleRight
                               sharpCornerRadius:(CGFloat)sharpCornerRadius
                                wideCornerRadius:(CGFloat)wideCornerRadius
                                    sharpCorners:(OWSDirectionalRectCorner)sharpCorners;

@property (nonatomic, nullable) UIColor *bubbleColor;

@property (nonatomic) OWSDirectionalRectCorner sharpCorners;

- (UIBezierPath *)maskPath;

#pragma mark - Coordination

- (void)addPartnerView:(id<OWSBubbleViewPartner>)view;

- (void)clearPartnerViews;

- (void)updatePartnerViews;

- (CGFloat)minWidth;

- (CGFloat)minHeight;

@end

NS_ASSUME_NONNULL_END
