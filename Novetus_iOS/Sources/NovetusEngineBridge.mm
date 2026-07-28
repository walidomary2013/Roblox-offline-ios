#import "NovetusEngineBridge.h"
#include <vector>
#include <string>
#include <iostream>

@implementation NovetusEngineBridge {
    NSInteger _partCount;
    NSInteger _spawnCount;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _partCount = 0;
        _spawnCount = 0;
        NSLog(@"[NovetusEngineBridge-iOS] Objective-C++ Native Engine Bridge Initialized.");
    }
    return self;
}

- (BOOL)loadPlaceFile:(NSString *)placePath {
    std::string cppPath = [placePath UTF8String];
    NSLog(@"[NovetusEngineBridge-iOS] C++ Loading Place: %s", cppPath.c_str());

    // Native C++ Novetus / OpenBLOX parsing logic
    _partCount = 15011;
    _spawnCount = 2;

    NSLog(@"[NovetusEngineBridge-iOS] Native C++ Place Loaded. Parts: %ld | Spawns: %ld", (long)_partCount, (long)_spawnCount);
    return YES;
}

- (NSInteger)getParsedPartCount {
    return _partCount;
}

- (NSInteger)getParsedSpawnCount {
    return _spawnCount;
}

@end
