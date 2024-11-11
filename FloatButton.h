#import <UIKit/UIKit.h>

typedef void (^FloatButtonAction)(void);

@interface FloatButton : UIButton

@property (nonatomic, copy) FloatButtonAction action;

- (instancetype)initWithFrame:(CGRect)frame icon:(UIImage *)icon action:(FloatButtonAction)action;

@end

@implementation FloatButton {
    CGPoint initialTouchPoint;
}

- (instancetype)initWithFrame:(CGRect)frame icon:(UIImage *)icon action:(FloatButtonAction)action {
    self = [super initWithFrame:frame];
    if (self) {
        self.action = action;
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = frame.size.width / 2;
        self.clipsToBounds = YES;
        
        [self setImage:icon forState:UIControlStateNormal];
        self.adjustsImageWhenHighlighted = NO;
        [self addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)buttonTapped {
    if (self.action) {
        self.action();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        initialTouchPoint = [gesture locationInView:self.superview];
        self.center = CGPointMake(initialTouchPoint.x, initialTouchPoint.y);
    }
}

@end
