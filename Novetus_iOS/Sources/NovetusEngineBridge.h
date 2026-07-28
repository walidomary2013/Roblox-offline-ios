#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C++ Bridge connecting Novetus C++ Engine with Apple Metal & Swift
@interface NovetusEngineBridge : NSObject

- (BOOL)loadPlaceFile:(NSString *)placePath;
- (NSInteger)getParsedPartCount;
- (NSInteger)getParsedSpawnCount;

@end

NS_ASSUME_NONNULL_END
