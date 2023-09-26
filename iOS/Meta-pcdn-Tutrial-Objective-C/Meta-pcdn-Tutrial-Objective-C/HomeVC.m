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
@interface HomeVC ()<LMJDropdownMenuDataSource,LMJDropdownMenuDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *urlSelectArea;
@property(nonatomic,strong)NSArray * dataSource;
@property(nonatomic,strong)LMJDropdownMenu * dropdownMenu;
@property(nonatomic,strong)NSString * selectedURL;
@property(nonatomic,assign)PlayerType type;
@property(nonatomic,strong)UITextField * urlInputField;
@property(nonatomic,strong)UITextField * vidInputField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *playBtnTopConstraint;
@end

@implementation HomeVC

- (NSArray *)dataSource {
    if(_dataSource == nil) {
        _dataSource = @[
            @"rtmp://221.13.203.66:31935/live/test_1080p_3m_baseline_25fps_150min",
            @"rtmp://221.13.203.66:31935/live/test_360p_1m_baseline_25fps_150min"
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
    self.selectedURL = self.dataSource.firstObject;
    self.dropdownMenu = [[LMJDropdownMenu alloc] initWithFrame:CGRectZero];
    [self.urlSelectArea addSubview:self.dropdownMenu];
    self.dropdownMenu.delegate = self;
    self.dropdownMenu.dataSource = self;
    self.dropdownMenu.layer.borderColor  = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1].CGColor;
    self.dropdownMenu.layer.borderWidth  = 1;
    self.dropdownMenu.layer.cornerRadius = 3;
    self.dropdownMenu.title           =  self.dataSource.firstObject;
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
    
    self.urlInputField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.urlSelectArea addSubview:self.urlInputField];

    self.urlInputField.text = self.dataSource.firstObject;
    self.urlInputField.delegate = self;
    self.urlInputField.layer.borderColor  = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1].CGColor;
    self.urlInputField.layer.borderWidth  = 1;
    self.urlInputField.layer.cornerRadius = 3;
    self.urlInputField.backgroundColor =  self.dropdownMenu.titleBgColor;
    self.urlInputField.textColor = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1];
    self.urlInputField.font = [UIFont boldSystemFontOfSize:15];
    
    [self.urlInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(30);
        make.right.mas_equalTo(-60);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(40);
    }];
#if 0
    self.playBtnTopConstraint.constant = 70;
    UILabel * vidLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    vidLabel.text = @"vid:";
    [self.view addSubview:vidLabel];
    
    self.vidInputField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.vidInputField.text = self.selectedURL;
    self.vidInputField.delegate = self;
    self.vidInputField.layer.borderColor  = [UIColor colorWithRed:64.0/255 green:151.0/255 blue:255.0/255 alpha:1].CGColor;
    self.vidInputField.layer.borderWidth  = 1;
    self.vidInputField.layer.cornerRadius = 3;
    [self.view addSubview:self.vidInputField];
    [vidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(30);
        make.top.equalTo(self.dropdownMenu.mas_bottom).offset(20);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(40);
    }];
    
    [self.vidInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(vidLabel.mas_right).offset(10);
        make.top.equalTo(self.dropdownMenu.mas_bottom).offset(20);
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
        make.top.equalTo(self.vidInputField.mas_bottom).offset(20);
        make.height.mas_equalTo(40);
    }];
    [aliPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(ijkPlayer.mas_right).offset(10);
        make.top.equalTo(self.vidInputField.mas_bottom).offset(20);
        make.height.mas_equalTo(40);
    }];
#else
    self.type = PlayerTypeALI;
#endif
}
- (IBAction)enterRoom:(id)sender {
    if(self.selectedURL.length <= 0 ) {
        [SVProgressHUD showInfoWithStatus:@"请选择播放视频源"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    if(![self.selectedURL hasPrefix:@"rtmp://"]) {
        [SVProgressHUD showInfoWithStatus:@"输入的地址不合法，请检查后再输入！！！"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }
    PCDNClientVC * clientVC = [[PCDNClientVC alloc] init];
    clientVC.playerURL = self.selectedURL;
    clientVC.type = self.type;
    clientVC.vid = self.selectedURL;
    if(self.vidInputField) {
      clientVC.vid = self.vidInputField.text;
    }
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
    self.urlInputField.text = self.selectedURL;
}

#pragma mark- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.urlInputField == textField) {
      self.selectedURL = textField.text;
    }
    [self.view endEditing:YES];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if(self.urlInputField == textField) {
        self.selectedURL = textField.text;
    }
    return  YES;
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
