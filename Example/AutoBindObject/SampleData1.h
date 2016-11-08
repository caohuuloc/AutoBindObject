//
//  SampleData1.h
//  AutoBindObject
//
//  Created by Cao Huu Loc on 11/8/16.
//  Copyright © 2016 Cao Huu Loc. All rights reserved.
//

#import <AutoBindObject/AutoBindObject.h>

@interface SampleData1 : AutoBindObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign) int age;

@end
