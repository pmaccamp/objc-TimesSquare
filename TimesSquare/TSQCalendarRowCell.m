//
//  TSQCalendarRowCell.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarRowCell.h"
#import "TSQCalendarView.h"


@interface TSQCalendarRowCell ()

@property (nonatomic, strong) NSArray *dayButtons;
@property (nonatomic, strong) NSMutableArray *dates;
@property (nonatomic, strong) UIButton *todayButton;

@property (nonatomic, assign) NSInteger indexOfTodayButton;
@property (nonatomic, assign) NSInteger indexOfSelectedButton;

@property (nonatomic, strong) NSDateFormatter *dayFormatter;
@property (nonatomic, strong) NSDateFormatter *accessibilityFormatter;

@property (nonatomic, strong) NSDateComponents *todayDateComponents;
@property (nonatomic) NSInteger monthOfBeginningDate;

@end


@implementation TSQCalendarRowCell

- (id)initWithCalendar:(NSCalendar *)calendar reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithCalendar:calendar reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)configureButton:(UIButton *)button;
{
    button.titleLabel.font = [UIFont systemFontOfSize:15.f];
    button.titleLabel.shadowOffset = self.shadowOffset;
    button.adjustsImageWhenDisabled = NO;
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = nil;
    button.titleLabel.backgroundColor = nil;
}

- (void)createDayButtons;
{
    NSMutableArray *dayButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    self.dates = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        UIButton *button = [[UIButton alloc] initWithFrame:self.contentView.bounds];
        [button addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [dayButtons addObject:button];
        [self.contentView addSubview:button];
        [self configureButton:button];
        [button setTitleColor:[self.textColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
    }
    self.dayButtons = dayButtons;
}

- (void)createTodayButton;
{
    self.todayButton = [[UIButton alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.todayButton];
    [self configureButton:self.todayButton];
    [self.todayButton addTarget:self action:@selector(todayButtonPressed:) forControlEvents:UIControlEventTouchDown];
    
    [self.todayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.todayButton setBackgroundImage:[self todayBackgroundImage] forState:UIControlStateNormal];
    [self.todayButton setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.75f] forState:UIControlStateNormal];
    
    self.todayButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)configureButtonForDateComponents:(NSDateComponents *)thisDateComponents button:(UIButton *)button{
    BOOL inMonth = thisDateComponents.month == [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self.calendarView.firstDate].month;
    
    if([self.calendarView isMealPlanDate:thisDateComponents]){
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:19]];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else{
        // Reset any buttons that were changed
        [self configureButton:button];
    }
    
    //Check if button is not in this month
    if(!inMonth){
        UIColor *backgroundPattern = [UIColor colorWithPatternImage:[self notThisMonthBackgroundImage]];
        button.backgroundColor = backgroundPattern;
        button.titleLabel.backgroundColor = backgroundPattern;
    }
}

- (void)setBeginningDate:(NSDate *)date;
{
    _beginningDate = date;
    
    if (!self.dayButtons) {
        [self createDayButtons];
        [self createTodayButton];
    }
    
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;
    
    self.todayButton.hidden = YES;
    self.indexOfTodayButton = -1;
    self.indexOfSelectedButton = -1;
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSString *title = [self.dayFormatter stringFromDate:date];
        NSString *accessibilityLabel = [self.accessibilityFormatter stringFromDate:date];
        [self.dayButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.dayButtons[index] setAccessibilityLabel:accessibilityLabel];
        
        NSDateComponents *thisDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];
        [self.dates setObject:thisDateComponents atIndexedSubscript:index];
        
        [self configureButtonForDateComponents:thisDateComponents button:self.dayButtons[index]];
        UIButton *button = self.dayButtons[index];
        
        if ([self.todayDateComponents isEqual:thisDateComponents]) {
            button.hidden = YES;
            
            self.todayButton.hidden = NO;
            [self.todayButton setTitle:title forState:UIControlStateNormal];
            [self.todayButton setAccessibilityLabel:accessibilityLabel];
            self.indexOfTodayButton = index;
            [self configureButtonForDateComponents:thisDateComponents button:self.todayButton];
        } else {
            button.enabled = ![self.calendarView.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] || [self.calendarView.delegate calendarView:self.calendarView shouldSelectDate:date];
            button.hidden = NO;
        }
        date = [self.calendar dateByAddingComponents:offset toDate:date options:0];
    }
}

- (void)setBottomRow:(BOOL)bottomRow;
{
    UIImageView *backgroundImageView = (UIImageView *)self.backgroundView;
    if ([backgroundImageView isKindOfClass:[UIImageView class]] && _bottomRow == bottomRow) {
        return;
    }
    
    _bottomRow = bottomRow;
    
    self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    
    [self setNeedsLayout];
}

- (IBAction)dateButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = [self.dayButtons indexOfObject:sender];
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    self.calendarView.selectedDate = selectedDate;
}

- (IBAction)todayButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = self.indexOfTodayButton;
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    self.calendarView.selectedDate = selectedDate;
}

- (void)layoutSubviews;
{
    if (!self.backgroundView) {
        [self setBottomRow:NO];
    }
    
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect;
{
    UIButton *dayButton = self.dayButtons[index];
    
    if(self.calendarView.selectedDate){
        NSDateComponents *selectedDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self.calendarView.selectedDate];
        NSDateComponents *currentDayComponents = self.dates[index];

        if([currentDayComponents isEqual:selectedDateComponents]){
            [[dayButton layer] setBorderWidth:2.0f];
            [[dayButton layer] setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
        } else{
            [[dayButton layer] setBorderWidth:0.0f];
        }
        if ([self.todayDateComponents isEqual:currentDayComponents]) {
            if([self.todayDateComponents isEqual:selectedDateComponents]){
                [[self.todayButton layer] setBorderWidth:2.0f];
                [[self.todayButton layer] setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
            } else{
                [[self.todayButton layer] setBorderWidth:0.0f];
            }
        }

    }
    
    dayButton.frame = rect;
    
    if (self.indexOfTodayButton == (NSInteger)index) {
        self.todayButton.frame = rect;
    }
}

- (NSDateFormatter *)dayFormatter;
{
    if (!_dayFormatter) {
        _dayFormatter = [NSDateFormatter new];
        _dayFormatter.calendar = self.calendar;
        _dayFormatter.dateFormat = @"d";
    }
    return _dayFormatter;
}

- (NSDateFormatter *)accessibilityFormatter;
{
    if (!_accessibilityFormatter) {
        _accessibilityFormatter = [NSDateFormatter new];
        _accessibilityFormatter.calendar = self.calendar;
        _accessibilityFormatter.dateStyle = NSDateFormatterLongStyle;
    }
    return _accessibilityFormatter;
}

- (NSInteger)monthOfBeginningDate;
{
    if (!_monthOfBeginningDate) {
        _monthOfBeginningDate = [self.calendar components:NSMonthCalendarUnit fromDate:self.firstOfMonth].month;
    }
    return _monthOfBeginningDate;
}

- (void)setFirstOfMonth:(NSDate *)firstOfMonth;
{
    [super setFirstOfMonth:firstOfMonth];
    self.monthOfBeginningDate = 0;
}

- (NSDateComponents *)todayDateComponents;
{
    if (!_todayDateComponents) {
        self.todayDateComponents = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
    }
    return _todayDateComponents;
}

@end
