//
//  HomeVC.m
//  Meta-PCDN-Player-iOS
//
//  Created by yoyo on 2023/1/13.
//

#import "HomeVC.h"
#import "Masonry.h"
#import "LMJDropdownMenu.h"
#import <MetaPCDNKit/MetaPCDNKit.h>
#import "PCDNClientVC.h"
#import "SVProgressHUD.h"
#import "YsyRadio.h"
#import "YsyRadioGroup.h"
@interface HomeVC ()<LMJDropdownMenuDataSource,LMJDropdownMenuDelegate>
@property (weak, nonatomic) IBOutlet UIView *urlSelectArea;
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,strong)LMJDropdownMenu * dropdownMenu;
@property(nonatomic,strong)NSString * selectedURL;
@property(nonatomic,assign)PlayerType type;
@end

@implementation HomeVC

- (NSArray *)dataSource {
    if(_dataSource == nil) {
        _dataSource = @[
            @"rtmp://221.13.203.66:31937/live/IMG_30fps_bf1_1M_baseline_360p"
        ];
    }
    return _dataSource;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.type = PlayerTypeIJK;
    
    self.dropdownMenu = [[LMJDropdownMenu alloc] initWithFrame:CGRectZero];
    [self.urlSelectArea addSubview:self.dropdownMenu];
    self.dropdownMenu.delegate = self;
    self.dropdownMenu.dataSource = self;
    self.dropdownMenu.layer.borderColor  = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1].CGColor;
    self.dropdownMenu.layer.borderWidth  = 1;
    self.dropdownMenu.layer.cornerRadius = 3;
    self.dropdownMenu.title           =  @"选择视频地址";
    self.dropdownMenu.titleBgColor    = [UIColor whiteColor];
    self.dropdownMenu.titleFont       = [UIFont boldSystemFontOfSize:15];
    self.dropdownMenu.titleColor      = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1];
    self.dropdownMenu.titleAlignment  = NSTextAlignmentLeft;
    self.dropdownMenu.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 40);
    self.dropdownMenu.rotateIcon            = [UIImage imageNamed:@"arrowIcon1"];
    self.dropdownMenu.rotateIconSize        = CGSizeMake(15, 15);
    self.dropdownMenu.rotateIconMarginRight = 15;
    self.dropdownMenu.optionsListLimitHeight = 80;
    
    [self.dropdownMenu mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(30);
        make.right.mas_equalTo(-30);
        make.height.mas_equalTo(40);
    }];
    
    YsyRadio * ijkPlayer = [YsyRadio creatRadioWithName:@"ijkPlayer" val:@"1" selected:YES];
    YsyRadio * aliPlayer = [YsyRadio creatRadioWithName:@"阿里播放器" val:@"2" selected:NO];
    [YsyRadioGroup onView:self.view select:^(YsyRadio *radio) {
        if ([radio.val isEqualToString:@"1"]) {
            self.type = PlayerTypeIJK;
        } else if ([radio.val isEqualToString:@"2"]) {
            self.type = PlayerTypeALI;
        }
        
    } radios:ijkPlayer,aliPlayer,nil];
    
    ijkPlayer.titleLabel.font = [UIFont systemFontOfSize:14];
    aliPlayer.titleLabel.font = [UIFont systemFontOfSize:14];
    
    [ijkPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.dropdownMenu.mas_left).offset(0);
        make.top.equalTo(self.dropdownMenu.mas_bottom).offset(20);
        make.height.mas_equalTo(40);
    }];
    [aliPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(ijkPlayer.mas_right).offset(10);
        make.top.equalTo(self.dropdownMenu.mas_bottom).offset(20);
        make.height.mas_equalTo(40);
    }];
}
- (IBAction)enterRoom:(id)sender {
    if(self.selectedURL.length <= 0 ) {
        [SVProgressHUD showInfoWithStatus:@"请选择播放视频源"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    PCDNClientVC * clientVC = [[PCDNClientVC alloc] init];
    clientVC.playerURL = self.selectedURL;
    clientVC.type = self.type;
    [self.navigationController pushViewController:clientVC animated:YES];
}

- (NSUInteger)numberOfOptionsInDropdownMenu:(LMJDropdownMenu *)menu {
    return  self.dataSource.count;
}
- (CGFloat)dropdownMenu:(LMJDropdownMenu *)menu heightForOptionAtIndex:(NSUInteger)index {
    return 44;
}
- (NSString *)dropdownMenu:(LMJDropdownMenu *)menu titleForOptionAtIndex:(NSUInteger)index {
    return self.dataSource[index];
}
- (void)dropdownMenu:(LMJDropdownMenu *)menu didSelectOptionAtIndex:(NSUInteger)index optionTitle:(NSString *)title {
    self.selectedURL  = self.dataSource[index];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
