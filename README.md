# UITextField_AutoSuggestion

[![CI Status](http://img.shields.io/travis/chika-kasymov/UITextField_AutoSuggestion.svg?style=flat)](https://travis-ci.org/Kassymov Shyngys/UITextField_AutoSuggestion)
[![Version](https://img.shields.io/cocoapods/v/UITextField_AutoSuggestion.svg?style=flat)](http://cocoapods.org/pods/UITextField_AutoSuggestion)
[![License](https://img.shields.io/cocoapods/l/UITextField_AutoSuggestion.svg?style=flat)](http://cocoapods.org/pods/UITextField_AutoSuggestion)
[![Platform](https://img.shields.io/cocoapods/p/UITextField_AutoSuggestion.svg?style=flat)](http://cocoapods.org/pods/UITextField_AutoSuggestion)

![Final auto suggestion feature](auto_suggestion.gif)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* **Xcode >= 7**
* **iOS >= 8.0**

## Installation

UITextField_AutoSuggestion is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "UITextField_AutoSuggestion"
```

## Usage

You can use library this way:

1. Conform to `UITextFieldAutoSuggestionDataSource`:

	``` objc
	@interface ViewController () <UITextFieldAutoSuggestionDataSource>
	```
2. Set data source to some `UITextField` and start observing changes

	``` objc
	// `fieldIdentifier` is optional
	self.textField.autoSuggestionDataSource = self;
	self.textField.fieldIdentifier = @"FIELD_ID";
	[self.textField observeTextFieldChanges];
	```

3. Implement required data source methods

	``` objc
	#pragma mark - UITextFieldAutoSuggestionDataSource
	
	- (UITableViewCell *)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {
	    static NSString *cellIdentifier = @"AutoSuggestionCell";
	    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	    
	    if (!cell) {
	        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	    }
	    
	    // configure cell
	    cell.textLabel.text = DATA[indexPath.row];
	    
	    return cell;
	}
	
	- (NSInteger)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section forText:(NSString *)text {
	    return DATA.count;
	}
	```

4. Implement optional data source methods if needed

	``` objc
	- (void)autoSuggestionField:(UITextField *)field textChanged:(NSString *)text {
		// can be useful in some scenarious, see example project
	    [self loadDataFromInternet];
	}
	
	- (CGFloat)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {
	    return 50;
	}
	
	- (void)autoSuggestionField:(UITextField *)field tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath forText:(NSString *)text {    	    
		// do something if suggestion row selected
		NSLog(@"%@", DATA[indexPath.row]);
	}
	```

## Author

Kassymov Shyngys, chika.kasymov@gmail.com

## License

UITextField_AutoSuggestion is available under the MIT license. See the LICENSE file for more info.
