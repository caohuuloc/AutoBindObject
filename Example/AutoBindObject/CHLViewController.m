//
//  CHLViewController.m
//  AutoBindObject
//
//  Created by Cao Huu Loc on 11/08/2016.
//  Copyright (c) 2016 Cao Huu Loc. All rights reserved.
//

#import "CHLViewController.h"
#import "SampleData1.h"

@interface CHLViewController ()

@end

@implementation CHLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    SampleData1 *obj = [[SampleData1 alloc] init];
    obj.name = @"Cao Huu Loc";
    obj.address = @"Tran Hung Dao";
    obj.age = 35;
    NSDictionary *dic = [obj toDictionary];
    NSLog(@"%@", dic);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
