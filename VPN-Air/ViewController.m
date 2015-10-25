#import "ConfigVPN.h"
#import "ViewController.h"
#import "VPNAccount.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *switchBtn;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ConfigVPN shareManager] connected:^(BOOL connected) {
        self.switchBtn.on = connected;
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)switchAction:(UISwitch *)sender
{
    if (sender.isOn)
    {
        [[ConfigVPN shareManager] connectVPN];
    }else
    {
        [[ConfigVPN shareManager] disconnectVPN];
    }
    
}

- (IBAction)userNameTextField:(UITextField *)sender
{
    [VPNAccount shareManager].vpnUserName = sender.text;
}
- (IBAction)userPasswordTextField:(UITextField *)sender
{
    [VPNAccount shareManager].vpnUserPassword = sender.text;

}
- (IBAction)sharePskTextField:(UITextField *)sender
{
    [VPNAccount shareManager].sharePsk = sender.text;

}
- (IBAction)serverAddressTextField:(UITextField *)sender
{
    [VPNAccount shareManager].severAddress = sender.text;

}


@end
