//
//  checker.h
//  checkSumCheck
//
//  Created by Dmitrii I on 3/17/16.
//  Copyright © 2016 Dmitrii Prihodco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Checker : NSObject

+(BOOL)compareExecutableChecksums;
+(BOOL)provisionExists;
+(void)sendData;
@end
