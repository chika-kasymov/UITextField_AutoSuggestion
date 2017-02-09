//
//  UITextField+AutoSuggestion.h
//  Pods
//
//  Created by Shyngys Kassymov on 29.01.17.
//
//

#import <UIKit/UIKit.h>

@protocol UITextFieldAutoSuggestionDataSource <NSObject>

- (UITableViewCell *)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text;
- (NSInteger)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section forText:(NSString *)text;

@optional
- (void)autoSuggestionField:(UITextField *)field textChanged:(NSString *)text;
- (CGFloat)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text;
- (void)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text;

@end

@interface UITextField (AutoSuggestion)

@property (weak, nonatomic) id<UITextFieldAutoSuggestionDataSource> autoSuggestionDataSource;
@property (nonatomic, strong) UIView *tableContainerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableAlphaView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *alphaView;
@property (nonatomic) BOOL autoSuggestionIsShowing;
@property (nonatomic) CGRect textFieldRectOnWindow;
@property (nonatomic) CGRect keyboardFrameBeginRect;
@property (nonatomic, strong) NSString *fieldIdentifier;
@property (nonatomic) NSInteger maxNumberOfRows;
@property (nonatomic) BOOL showImmediately;

- (void)observeTextFieldChanges;
- (void)setLoading:(BOOL)loading;

- (void)reloadContents;

@end
