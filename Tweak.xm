#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SBMediaController : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isRingerMuted;
@end

static UIWindow *glhWindow = nil;
static UIView *glhPill = nil;
static dispatch_block_t glhHideBlock = nil;

static BOOL GLHIsSilent(void) {
    Class cls = NSClassFromString(@"SBMediaController");
    if (cls && [cls respondsToSelector:@selector(sharedInstance)]) {
        id media = [cls sharedInstance];
        if (media && [media respondsToSelector:@selector(isRingerMuted)]) {
            return ((BOOL (*)(id, SEL))objc_msgSend)(media, @selector(isRingerMuted));
        }
    }
    return NO;
}

static NSString *GLHIconPath(BOOL silent) {
    NSString *name = silent ? @"bell_silent_red.png" : @"bell_normal_gray.png";
    NSString *p1 = [@"/Library/Application Support/SilentPillHUD" stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:p1]) return p1;
    NSString *p2 = [@"/Library/MobileSubstrate/DynamicLibraries/SilentPillHUD.bundle" stringByAppendingPathComponent:name];
    return p2;
}

static void GLHEnsureWindow(void) {
    if (glhWindow) return;
    CGRect screen = [UIScreen mainScreen].bounds;
    glhWindow = [[UIWindow alloc] initWithFrame:screen];
    glhWindow.windowLevel = UIWindowLevelStatusBar + 1000;
    glhWindow.backgroundColor = [UIColor clearColor];
    glhWindow.userInteractionEnabled = NO;
    glhWindow.hidden = YES;
}

static void GLHShowSilentPill(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL silent = GLHIsSilent();
        GLHEnsureWindow();

        [glhPill removeFromSuperview];
        glhPill = nil;

        CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
        CGFloat pillW = MIN(screenW - 32.0, 360.0);
        CGFloat pillH = 94.0;
        CGFloat pillX = (screenW - pillW) / 2.0;
        CGFloat pillY = 12.0;

        UIView *pill = [[UIView alloc] initWithFrame:CGRectMake(pillX, pillY, pillW, pillH)];
        pill.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.84];
        pill.layer.cornerRadius = pillH / 2.0;
        pill.layer.masksToBounds = YES;
        pill.layer.borderWidth = 1.0;
        pill.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10].CGColor;
        pill.alpha = 0.0;
        pill.transform = CGAffineTransformMakeScale(0.94, 0.94);

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = pill.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurView.alpha = 0.45;
        [pill addSubview:blurView];

        UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(31.0, 24.0, 46.0, 46.0)];
        icon.image = [UIImage imageWithContentsOfFile:GLHIconPath(silent)];
        icon.contentMode = UIViewContentModeScaleAspectFit;
        [pill addSubview:icon];

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(108.0, 25.0, 1.0, 44.0)];
        line.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
        [pill addSubview:line];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(140.0, 22.0, pillW - 160.0, 32.0)];
        title.text = @"Silent Mode";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightSemibold];
        title.adjustsFontSizeToFitWidth = YES;
        title.minimumScaleFactor = 0.75;
        [pill addSubview:title];

        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(140.0, 53.0, pillW - 160.0, 28.0)];
        status.text = silent ? @"On" : @"Off";
        status.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
        status.textAlignment = NSTextAlignmentLeft;
        status.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightMedium];
        [pill addSubview:status];

        [glhWindow addSubview:pill];
        glhPill = pill;
        glhWindow.hidden = NO;

        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            pill.alpha = 1.0;
            pill.transform = CGAffineTransformIdentity;
        } completion:nil];

        if (glhHideBlock) dispatch_block_cancel(glhHideBlock);
        glhHideBlock = dispatch_block_create(0, ^{
            [UIView animateWithDuration:0.20 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                pill.alpha = 0.0;
                pill.transform = CGAffineTransformMakeScale(0.96, 0.96);
            } completion:^(BOOL finished) {
                if (glhPill == pill) {
                    [glhPill removeFromSuperview];
                    glhPill = nil;
                    glhWindow.hidden = YES;
                }
            }];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), glhHideBlock);
    });
}

%hook SBHUDController
- (void)presentHUDView:(id)view autoDismissWithDelay:(double)delay {
    if ([view isKindOfClass:NSClassFromString(@"SBRingerHUDView")]) {
        GLHShowSilentPill();
        return;
    }
    %orig;
}
%end
