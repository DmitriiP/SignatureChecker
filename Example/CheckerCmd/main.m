//
//  main.m
//  CheckerCmd
//
//  Created by Dmitrii I on 3/29/16.
//  Copyright © 2016 Dmitrii Prihodco. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <SignatureChecker/Checker.h>
#import "Checker.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        [Checker isSignedByApple];
        NSLog(@"Hello, World!");
    }
    return 0;
}
