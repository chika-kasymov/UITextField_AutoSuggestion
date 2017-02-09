//
//  UITextField+AutoSuggestion.m
//  Pods
//
//  Created by Shyngys Kassymov on 29.01.17.
//
//

#import "UITextField+AutoSuggestion.h"
#import <objc/runtime.h>

#define DEFAULT_MAX_NUM_OF_ROWS 5
#define DEFAULT_ROW_HEIGHT 44.0f
#define INSET 20.0f

static char textFieldRectOnWindowKey;
static char keyboardFrameBeginRectKey;

@interface UITextField () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation UITextField (AutoSuggestion)

- (void)observeTextFieldChanges {
    self.layer.masksToBounds = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleAutoSuggestion:) name:UITextFieldTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleAutoSuggestion:) name:UITextFieldTextDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideAutoSuggestion) name:UITextFieldTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getKeyboardHeight:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)setLoading:(BOOL)loading {
    if (loading) {
        if (!self.tableAlphaView) {
            self.tableAlphaView = [[UIView alloc] initWithFrame:self.tableView.bounds];
            self.tableAlphaView.backgroundColor = [UIColor whiteColor];
            [self.tableView addSubview:self.tableAlphaView];
            
            self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
            self.spinner.center = self.tableAlphaView.center;
            self.spinner.color = [UIColor blackColor];
            [self.tableAlphaView addSubview:self.spinner];
            
            [self.spinner startAnimating];
        }
    } else {
        if (self.tableAlphaView) {
            [self.spinner stopAnimating];
            
            [self.spinner removeFromSuperview];
            self.spinner = nil;
            
            [self.tableAlphaView removeFromSuperview];
            self.tableAlphaView = nil;
        }
    }
}

#pragma mark - Helpers

- (void)toggleAutoSuggestion:(NSNotification *)notification {
    if (self.text.length > 0 || self.showImmediately) {
        [self showAutoSuggestion];
        
        if ([self.autoSuggestionDataSource respondsToSelector:@selector(autoSuggestionField:textChanged:)]) {
            [self.autoSuggestionDataSource autoSuggestionField:self textChanged:self.text];
        }
    } else {
        [self hideAutoSuggestion];
    }
}

- (void)showAutoSuggestion {
    if (!self.autoSuggestionIsShowing) {
        [self createSuggestionView];
        self.autoSuggestionIsShowing = YES;
    }
    
    [self reloadContents];
}

- (void)hideAutoSuggestion {
    if (self.autoSuggestionIsShowing) {
        
        [self.alphaView removeFromSuperview];
        self.alphaView = nil;
        
        [self.tableView removeFromSuperview];
        self.tableView = nil;
        
        [self.tableContainerView removeFromSuperview];
        self.tableContainerView = nil;
        
        self.autoSuggestionIsShowing = NO;
    }
}

- (void)createSuggestionView {
    UIWindow *appDelegateWindow = [UIApplication sharedApplication].keyWindow;
    self.textFieldRectOnWindow = [self convertRect:self.bounds toView:nil];
    
    if (!self.tableContainerView) {
        self.tableContainerView = [UIView new];
        self.tableContainerView.backgroundColor = [UIColor whiteColor];
    }
    
    if (!self.tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:self.textFieldRectOnWindow style:UITableViewStylePlain];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.tableFooterView = [UIView new];
    }
    
    if (!self.alphaView) {
        self.alphaView = [[UIView alloc] initWithFrame:appDelegateWindow.bounds];
        self.alphaView.userInteractionEnabled = true;
        self.alphaView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [appDelegateWindow addSubview:self.alphaView];
    }
    
    self.tableView.frame = self.textFieldRectOnWindow;
    [self.tableContainerView addSubview:self.tableView];
    self.tableContainerView.frame = self.textFieldRectOnWindow;
    [appDelegateWindow addSubview:self.tableContainerView];
}

- (void)reloadContents {
    [self updateHeight];
    [self updateCornerRadius];
    [self checkForEmptyState];
    
    [self.tableView reloadData];
}

- (void)checkForEmptyState {
    if ([self tableView:self.tableView numberOfRowsInSection:0] == 0) {
        UILabel *emptyTableLabel = [[UILabel alloc] initWithFrame:self.tableView.bounds];
        emptyTableLabel.textAlignment = NSTextAlignmentCenter;
        emptyTableLabel.font = [UIFont systemFontOfSize:16];
        emptyTableLabel.textColor = [UIColor grayColor];
        emptyTableLabel.text = @"No matches";
        self.tableView.backgroundView = emptyTableLabel;
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (void)updateHeight {
    NSInteger numberOfResults = [self tableView:self.tableView numberOfRowsInSection:0];
    NSInteger maxRowsToShow = self.maxNumberOfRows != 0 ? self.maxNumberOfRows : DEFAULT_MAX_NUM_OF_ROWS;
    CGFloat cellHeight = DEFAULT_ROW_HEIGHT;
    if ([self.tableView numberOfRowsInSection:0] > 0) {
        cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    CGFloat height = MIN(maxRowsToShow, numberOfResults) * cellHeight; // check if numberOfResults < maxRowsToShow
    height = MAX(height, cellHeight); // if 0 results, set height = `cellHeight`
    
    CGRect frame = self.textFieldRectOnWindow;
    
    if ([self showSuggestionViewBelow]) {
        CGFloat maxHeight = [UIScreen mainScreen].bounds.size.height - (frame.origin.y + frame.size.height) - INSET - self.keyboardFrameBeginRect.size.height; // max possible height
        height = MIN(height, maxHeight); // set height = `maxHeight` if it's smaller than current `height`
        
        frame.origin.y += frame.size.height;
    } else {
        CGFloat maxHeight = frame.origin.y - INSET;  // max possible height
        height = MIN(height, maxHeight); // set height = `maxHeight` if it's smaller than current `height`
        
        frame.origin.y -= height;
    }
    
    frame.size.height = height;
    self.tableView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.tableContainerView.frame = frame;
}

- (void)updateCornerRadius {
    // code snippet from SO answer (http://stackoverflow.com/a/13163693/1760199)
    UIRectCorner corners = (UIRectCornerBottomLeft | UIRectCornerBottomRight);
    if (![self showSuggestionViewBelow]) {
        corners = (UIRectCornerTopLeft | UIRectCornerTopRight);
    }
    
    UIBezierPath *maskPath = [UIBezierPath
                              bezierPathWithRoundedRect:self.tableContainerView.bounds
                              byRoundingCorners:corners
                              cornerRadii:CGSizeMake(6, 6)
                              ];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    
    self.tableContainerView.layer.mask = maskLayer;
}

- (void)getKeyboardHeight:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    self.keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
}

- (BOOL)showSuggestionViewBelow {
    CGRect frame = self.textFieldRectOnWindow;
    return frame.origin.y + frame.size.height/2.0 < ([UIScreen mainScreen].bounds.size.height - self.keyboardFrameBeginRect.size.height)/2.0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL implementsDatasource = self.autoSuggestionDataSource && [self.autoSuggestionDataSource respondsToSelector:@selector(autoSuggestionField:tableView:numberOfRowsInSection:forText:)];
    NSAssert(implementsDatasource, @"UITextField must implement data source before using auto suggestion.");
    
    return [self.autoSuggestionDataSource autoSuggestionField:self tableView:tableView numberOfRowsInSection:section forText:self.text];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL implementsDatasource = self.autoSuggestionDataSource && [self.autoSuggestionDataSource respondsToSelector:@selector(autoSuggestionField:tableView:cellForRowAtIndexPath:forText:)];
    NSAssert(implementsDatasource, @"UITextField must implement data source before using auto suggestion.");
                                                
    return [self.autoSuggestionDataSource autoSuggestionField:self tableView:tableView cellForRowAtIndexPath:indexPath forText:self.text];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.autoSuggestionDataSource && [self.autoSuggestionDataSource respondsToSelector:@selector(autoSuggestionField:tableView:heightForRowAtIndexPath:forText:)]) {
        [self.autoSuggestionDataSource autoSuggestionField:self tableView:tableView heightForRowAtIndexPath:indexPath forText:self.text];
    }
    
    return DEFAULT_ROW_HEIGHT;
}

#pragma clang diagnostic pop

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.autoSuggestionDataSource && [self.autoSuggestionDataSource respondsToSelector:@selector(autoSuggestionField:tableView:didSelectRowAtIndexPath:forText:)]) {
        [self.autoSuggestionDataSource autoSuggestionField:self tableView:tableView didSelectRowAtIndexPath:indexPath forText:self.text];
    }
    
    [self hideAutoSuggestion];
}

#pragma mark - Getters/Setters

- (id<UITextFieldAutoSuggestionDataSource>)autoSuggestionDataSource {
    return objc_getAssociatedObject(self, @selector(autoSuggestionDataSource));
}

- (void)setAutoSuggestionDataSource:(id<UITextFieldAutoSuggestionDataSource>)autoSuggestionDataSource {
    objc_setAssociatedObject(self, @selector(autoSuggestionDataSource), autoSuggestionDataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)autoSuggestionIsShowing {
    return [objc_getAssociatedObject(self, @selector(autoSuggestionIsShowing)) boolValue];
}

- (void)setAutoSuggestionIsShowing:(BOOL)autoSuggestionIsShowing {
    objc_setAssociatedObject(self, @selector(autoSuggestionIsShowing), @(autoSuggestionIsShowing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)tableContainerView {
    return objc_getAssociatedObject(self, @selector(tableContainerView));
}

- (void)setTableContainerView:(UIView *)tableContainerView {
    objc_setAssociatedObject(self, @selector(tableContainerView), tableContainerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITableView *)tableView {
    return objc_getAssociatedObject(self, @selector(tableView));
}

- (void)setTableView:(UITableView *)tableView {
    objc_setAssociatedObject(self, @selector(tableView), tableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)tableAlphaView {
    return objc_getAssociatedObject(self, @selector(tableAlphaView));
}

- (void)setTableAlphaView:(UIView *)tableAlphaView {
    objc_setAssociatedObject(self, @selector(tableAlphaView), tableAlphaView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIActivityIndicatorView *)spinner {
    return objc_getAssociatedObject(self, @selector(spinner));
}

- (void)setSpinner:(UIActivityIndicatorView *)spinner {
    objc_setAssociatedObject(self, @selector(spinner), spinner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)alphaView {
    return objc_getAssociatedObject(self, @selector(alphaView));
}

- (void)setAlphaView:(UIView *)alphaView {
    objc_setAssociatedObject(self, @selector(alphaView), alphaView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)textFieldRectOnWindow {
    NSValue *textFieldRectOnWindowValue = (NSValue *)objc_getAssociatedObject(self, &textFieldRectOnWindowKey);
    
    if (textFieldRectOnWindowValue != nil) {
        return [textFieldRectOnWindowValue CGRectValue];
    } else {
        return CGRectZero;
    }
}

- (void)setTextFieldRectOnWindow:(CGRect)textFieldRectOnWindow {
    NSValue *textFieldRectOnWindowValue = [NSValue valueWithCGRect:textFieldRectOnWindow];
    objc_setAssociatedObject(self, &textFieldRectOnWindowKey, textFieldRectOnWindowValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)keyboardFrameBeginRect {
    NSValue *keyboardFrameBeginRectValue = (NSValue *)objc_getAssociatedObject(self, &keyboardFrameBeginRectKey);
    
    if (keyboardFrameBeginRectValue != nil) {
        return [keyboardFrameBeginRectValue CGRectValue];
    } else {
        return CGRectZero;
    }
}

- (void)setKeyboardFrameBeginRect:(CGRect)keyboardFrameBeginRect {
    NSValue *keyboardFrameBeginRectValue = [NSValue valueWithCGRect:keyboardFrameBeginRect];
    objc_setAssociatedObject(self, &keyboardFrameBeginRectKey, keyboardFrameBeginRectValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fieldIdentifier {
    return objc_getAssociatedObject(self, @selector(fieldIdentifier));
}

- (void)setFieldIdentifier:(NSString *)fieldIdentifier {
    objc_setAssociatedObject(self, @selector(fieldIdentifier), fieldIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)maxNumberOfRows {
    return [objc_getAssociatedObject(self, @selector(maxNumberOfRows)) integerValue];
}

- (void)setMaxNumberOfRows:(NSInteger)maxNumberOfRows {
    objc_setAssociatedObject(self, @selector(maxNumberOfRows), @(maxNumberOfRows), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)showImmediately {
    return [objc_getAssociatedObject(self, @selector(showImmediately)) boolValue];
}

- (void)setShowImmediately:(BOOL)showImmediately {
    objc_setAssociatedObject(self, @selector(showImmediately), @(showImmediately), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
