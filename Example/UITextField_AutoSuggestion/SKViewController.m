//
//  SKViewController.m
//  UITextField_AutoSuggestion
//
//  Created by Kassymov Shyngys on 01/29/2017.
//  Copyright (c) 2017 Kassymov Shyngys. All rights reserved.
//

#import "SKViewController.h"
#import <UITextField_AutoSuggestion/UITextField+AutoSuggestion.h>

@interface SKViewController () <UITextFieldAutoSuggestionDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField1;
@property (weak, nonatomic) IBOutlet UITextField *textField2;

@property (nonatomic, strong) NSMutableArray *weeks;

@end

#define MONTHS @[@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"]
#define WEEKS @[@"Monday", @"Tuesday", @"Wednesday", @"Thirsday", @"Friday", @"Saturday", @"Sunday"]

#define MONTH_ID @"month_id"
#define WEEK_ID @"week_id"

@implementation SKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.weeks = @[].mutableCopy;
    
    self.textField1.delegate = self;
    self.textField1.autoSuggestionDataSource = self;
    self.textField1.fieldIdentifier = MONTH_ID;
    self.textField1.showImmediately = true;
    [self.textField1 observeTextFieldChanges];

    self.textField2.delegate = self;
    self.textField2.autoSuggestionDataSource = self;
    self.textField2.fieldIdentifier = WEEK_ID;
    self.textField2.minCharsToShow = 3;
    [self.textField2 observeTextFieldChanges];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Methods

- (void)loadWeekDays {
    // cancel previous requests
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadWeekDaysInBackground) object:self];
    [self.textField2 setLoading:false];
    
    // clear previous results
    [self.weeks removeAllObjects];
    [self.textField2 reloadContents];
    
    // start loading
    [self.textField2 setLoading:true];
    [self performSelector:@selector(loadWeekDaysInBackground) withObject:self afterDelay:2.0f];
}

- (void)loadWeekDaysInBackground {
    // finish loading
    [self.textField2 setLoading:false];
    
    [self.weeks addObjectsFromArray:WEEKS];
    [self.textField2 reloadContents];
}

#pragma mark - UITextFieldAutoSuggestionDataSource

- (UITableViewCell *)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {
    if ([field.fieldIdentifier isEqualToString:MONTH_ID]) {
        static NSString *cellIdentifier = @"MonthAutoSuggestionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        NSArray *months = MONTHS;
        
        if (text.length > 0) {
            NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
            months = [MONTHS filteredArrayUsingPredicate:filterPredictate];
        }
        
        cell.textLabel.text = months[indexPath.row];
        
        return cell;
    }
    
    static NSString *cellIdentifier = @"WeekAutoSuggestionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
    NSArray *weeks = [self.weeks filteredArrayUsingPredicate:filterPredictate];
    
    cell.textLabel.text = weeks[indexPath.row];
    
    return cell;
}

- (NSInteger)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section forText:(NSString *)text {
    if ([field.fieldIdentifier isEqualToString:MONTH_ID]) {
        if (text.length == 0) {
            return MONTHS.count;
        }
        
        NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
        NSInteger count = [MONTHS filteredArrayUsingPredicate:filterPredictate].count;
        return count;
    }
    
    NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
    NSInteger count = [self.weeks filteredArrayUsingPredicate:filterPredictate].count;
    return count;
}

- (void)autoSuggestionField:(UITextField *)field textChanged:(NSString *)text {
    [self loadWeekDays];
}

- (CGFloat)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {
    return 50;
}

- (void)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {    
    NSLog(@"Selected suggestion at index row - %ld", (long)indexPath.row);
    
    if ([field.fieldIdentifier isEqualToString:MONTH_ID]) {
        NSArray *months = MONTHS;
        
        if (text.length > 0) {
            NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
            months = [MONTHS filteredArrayUsingPredicate:filterPredictate];
        }
        
        self.textField1.text = months[indexPath.row];
    } else {
        NSPredicate *filterPredictate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
        NSArray *weeks = [self.weeks filteredArrayUsingPredicate:filterPredictate];
        
        self.textField2.text = weeks[indexPath.row];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return true;
}

@end
