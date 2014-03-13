//
//  TSQCalendarMonthHeaderCell.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "TSQCalendarMonthHeaderCell.h"


static const CGFloat TSQCalendarMonthHeaderCellMonthsHeight = 20.f;


@interface TSQCalendarMonthHeaderCell ()

@property (nonatomic, strong) NSDateFormatter *monthDateFormatter;

@end


@implementation TSQCalendarMonthHeaderCell

- (id)initWithCalendar:(NSCalendar *)calendar reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithCalendar:calendar reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    // Fix long press on buttons in cell
    for (id obj in self.subviews)
    {
        if ([NSStringFromClass([obj class]) isEqualToString:@"UITableViewCellScrollView"])
        {
            UIScrollView *scroll = (UIScrollView *) obj;
            scroll.delaysContentTouches = NO;
            break;
        }
    }
    
    [self createHeaderLabels];

    return self;
}


+ (CGFloat)cellHeight;
{
    return 65.0f;
}

- (NSDateFormatter *)monthDateFormatter;
{
    if (!_monthDateFormatter) {
        _monthDateFormatter = [NSDateFormatter new];
        _monthDateFormatter.calendar = self.calendar;
        
        NSString *dateComponents = @"yyyyLLLL";
        _monthDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
    }
    return _monthDateFormatter;
}

- (void)createNavigationButtons{
    self.nextMonth = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 9, 5, 5)];
    self.previousMonth = [[UIButton alloc] initWithFrame:CGRectMake(2, 9, 5, 5)];
    [self.nextMonth setTitle:@">" forState:UIControlStateNormal];
    [self.previousMonth setTitle:@"<" forState:UIControlStateNormal];
    [self.nextMonth setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.previousMonth setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.nextMonth setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.previousMonth setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    [self.previousMonth sizeToFit];
    [self.nextMonth sizeToFit];
    
    [self.nextMonth addTarget:self action:@selector(nextMonthButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.previousMonth addTarget:self action:@selector(previousMonthButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.nextMonth];
    [self addSubview:self.previousMonth];
}

- (void)nextMonthButtonPressed:(id) sender{
    [self.delegate nextMonthPressedForCell:self];
}

- (void)previousMonthButtonPressed:(id) sender{
    [self.delegate previousMonthPressedForCell:self];
}

- (void)createHeaderLabels;
{
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;
    NSMutableArray *headerLabels = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    
    NSDateFormatter *dayFormatter = [NSDateFormatter new];
    dayFormatter.calendar = self.calendar;
    dayFormatter.dateFormat = @"cccccc";
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        [headerLabels addObject:@""];
    }
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSInteger ordinality = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSWeekCalendarUnit forDate:referenceDate];
        UILabel *label = [[UILabel alloc] initWithFrame:self.frame];
        label.textAlignment = UITextAlignmentCenter;
        label.text = [dayFormatter stringFromDate:referenceDate];
        label.font = [UIFont boldSystemFontOfSize:12.f];
        label.backgroundColor = self.backgroundColor;
        label.textColor = self.textColor;
        [label sizeToFit];
        headerLabels[ordinality - 1] = label;
        [self.contentView addSubview:label];
        
        referenceDate = [self.calendar dateByAddingComponents:offset toDate:referenceDate options:0];
    }
    
    self.headerLabels = headerLabels;
    self.textLabel.textAlignment = UITextAlignmentCenter;
    self.textLabel.textColor = self.textColor;
    }

- (void)layoutSubviews;
{
    [super layoutSubviews];

    CGRect bounds = self.contentView.bounds;
    bounds.size.height -= TSQCalendarMonthHeaderCellMonthsHeight;
    bounds.size.width -= 100.0f;
    self.textLabel.frame = CGRectOffset(bounds, 50.0f, 5.0f);
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect;
{
    UILabel *label = self.headerLabels[index];
    CGRect labelFrame = rect;
    labelFrame.size.height = TSQCalendarMonthHeaderCellMonthsHeight;
    labelFrame.origin.y = self.bounds.size.height - TSQCalendarMonthHeaderCellMonthsHeight;
    label.frame = labelFrame;
}

- (void)setFirstOfMonth:(NSDate *)firstOfMonth;
{
    [super setFirstOfMonth:firstOfMonth];
    self.textLabel.text = [self.monthDateFormatter stringFromDate:firstOfMonth];
    self.accessibilityLabel = self.textLabel.text;
    [self createNavigationButtons];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor;
{
    [super setBackgroundColor:backgroundColor];
    for (UILabel *label in self.headerLabels) {
        label.backgroundColor = backgroundColor;
    }
}

@end
