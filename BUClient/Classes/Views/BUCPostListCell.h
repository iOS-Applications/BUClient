#import <UIKit/UIKit.h>


@interface BUCPostListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *dateline;
@property (weak, nonatomic) IBOutlet UIButton *author;
@property (weak, nonatomic) IBOutlet UILabel *statistic;
@property (weak, nonatomic) IBOutlet UIButton *forum;
@property (weak, nonatomic) IBOutlet UIView *separator;
@property (weak, nonatomic) IBOutlet UILabel *lastPostDate;
@property (weak, nonatomic) IBOutlet UIButton *lastPoster;


@end
