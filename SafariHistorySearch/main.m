//
//  main.m
//  SafariHistorySearch
//
//  Created by Ahmet Karalar on 17/07/16.
//  Copyright © 2016 Ahmet Karalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@import SafariHistorySearchFramework;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
//        NSLog(@"Args: %@", arguments);
        [Search start:arguments];
    }
    return 0;
}
