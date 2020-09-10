



import UIKit
//引入GameController
import GameController
import CoreHaptics


	

class ViewController: UIViewController {
    
    @IBOutlet weak var logTextView: UITextView!
    

	
	//定义时间格式字符串
    var dateFormatter = DateFormatter()
	

    
	//控制器偏移最大值
    private let maximumControllerCount: Int = 1
	
	//设置GCC控制器
    private(set) var controllers = Set<GCController>()
	
    private var panRecognizer: UIPanGestureRecognizer!
    weak var delegate: InputManagerDelegate?
    
	
	//定义手柄测试小红点的大小及位置
	//方向键
	let overlayLeft =  Draw(frame: CGRect(origin: CGPoint(x: 80, y: 185), size: CGSize(width: 18, height: 18)))
    let overlayRight = Draw(frame: CGRect(origin: CGPoint(x: 110, y: 185), size: CGSize(width: 18, height: 18)))
    let overlayUp =    Draw(frame: CGRect(origin: CGPoint(x: 95, y: 170), size: CGSize(width: 18, height: 18)))
    let overlayDown =  Draw(frame: CGRect(origin: CGPoint(x: 95, y: 200), size: CGSize(width: 18, height: 18)))
    //功能键
    let overlayA = Draw(frame: CGRect(origin: CGPoint(x: 260, y: 205), size: CGSize(width: 18, height: 18)))
    let overlayB = Draw(frame: CGRect(origin: CGPoint(x: 278, y: 187), size: CGSize(width: 18, height: 18)))
    let overlayX = Draw(frame: CGRect(origin: CGPoint(x: 242, y: 187), size: CGSize(width: 18, height: 18)))
    let overlayY = Draw(frame: CGRect(origin: CGPoint(x: 260, y: 165), size: CGSize(width: 18, height: 18)))
    
	//设置/菜单键
    let overlayOptions = Draw(frame: CGRect(origin: CGPoint(x: 127, y: 165), size: CGSize(width: 12, height: 12)))
    let overlayMenu =    Draw(frame: CGRect(origin: CGPoint(x: 237, y: 165), size: CGSize(width: 12, height: 12)))
    
	
	//肩键
    let overlayLeftShoulder = Draw(frame: CGRect(origin: CGPoint(x: 97, y: 135), size: CGSize(width: 20, height: 20)))
    let overlayRightShoulder = Draw(frame: CGRect(origin: CGPoint(x: 257, y: 135), size: CGSize(width: 20, height: 20)))
	
    //摇杆
    let overlayLeftThumb =  Draw(frame: CGRect(origin: CGPoint(x: 130, y: 220), size: CGSize(width: 25, height: 25)))
    let overlayRightThumb = Draw(frame: CGRect(origin: CGPoint(x: 215, y: 220), size: CGSize(width: 25, height: 25)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		//定义时间显示格式小时：：分钟：：秒：：毫秒
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"
        clearLog()
        
///核心部分///
		
		//配置方法
		//确认手柄的连接状态
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didConnectController),
                                               name: NSNotification.Name.GCControllerDidConnect,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didDisconnectController),
                                               name: NSNotification.Name.GCControllerDidDisconnect,
                                               object: nil)
        
		//搜无线控制器
		//当且仅当搜索到无线控制器时，才会执行下面的代码
        GCController.startWirelessControllerDiscovery {}
		
		
		
    }
    
    func clearLog() {
        logTextView.text = ""
    }
    
    func writeToLog(newLine: String) {
        logTextView.text = newLine + "\n" + logTextView.text
    }

	//判断连接状态
	//当搜索到手柄连接时，发送连接成功的log
    @objc func didConnectController(_ notification: Notification) {
        writeToLog(newLine: "Connect to GameController")
        
        guard controllers.count < maximumControllerCount else { return }
        let controller = notification.object as! GCController
        //添加控制器
        controllers.insert(controller)
        
		
		//当控制器连接时执行委托
        delegate?.inputManager(self, didConnect: controller)
        
		
		//配置按键
		//监听委托，格式为：按钮，按钮值（按下/偏移值），bool（判断是否按下））
        controller.extendedGamepad?.dpad.left.pressedChangedHandler =      { (button, value, pressed) in self.buttonChangedHandler("←", pressed, self.overlayLeft) }
        controller.extendedGamepad?.dpad.right.pressedChangedHandler =     { (button, value, pressed) in self.buttonChangedHandler("→", pressed, self.overlayRight) }
        controller.extendedGamepad?.dpad.up.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("↑", pressed, self.overlayUp) }
        controller.extendedGamepad?.dpad.down.pressedChangedHandler =      { (button, value, pressed) in self.buttonChangedHandler("↓", pressed, self.overlayDown) }
        
        //A=X
        controller.extendedGamepad?.buttonA.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("⨯", pressed, self.overlayA) }
        //B=●
        controller.extendedGamepad?.buttonB.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("●", pressed, self.overlayB) }
        //X=■
        controller.extendedGamepad?.buttonX.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("■", pressed, self.overlayX) }
        //Y=▲
        controller.extendedGamepad?.buttonY.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("▲", pressed, self.overlayY) }
        
		
		
		//Option=SHARE
        controller.extendedGamepad?.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in self.buttonChangedHandler("SHARE", pressed, self.overlayOptions) }
        //Menu=OPTIONS
        controller.extendedGamepad?.buttonMenu.pressedChangedHandler =     { (button, value, pressed) in self.buttonChangedHandler("OPTIONS", pressed, self.overlayMenu) }
        
        controller.extendedGamepad?.leftShoulder.pressedChangedHandler =   { (button, value, pressed) in self.buttonChangedHandler("L1", pressed, self.overlayLeftShoulder) }
        controller.extendedGamepad?.rightShoulder.pressedChangedHandler =  { (button, value, pressed) in self.buttonChangedHandler("R1", pressed, self.overlayRightShoulder) }
        
        controller.extendedGamepad?.leftTrigger.pressedChangedHandler =    { (button, value, pressed) in self.buttonChangedHandler("L2", pressed, self.overlayLeftShoulder) }
        controller.extendedGamepad?.leftTrigger.valueChangedHandler =      { (button, value, pressed) in self.triggerChangedHandler("L2", value, pressed) }
        controller.extendedGamepad?.rightTrigger.pressedChangedHandler =   { (button, value, pressed) in self.buttonChangedHandler("R2", pressed, self.overlayRightShoulder) }
        controller.extendedGamepad?.rightTrigger.valueChangedHandler =     { (button, value, pressed) in self.triggerChangedHandler("R2", value, pressed) }
        
        controller.extendedGamepad?.leftThumbstick.valueChangedHandler =   { (button, xvalue, yvalue) in self.thumbstickChangedHandler("THUMB-LEFT", xvalue, yvalue) }
        controller.extendedGamepad?.rightThumbstick.valueChangedHandler =  { (button, xvalue, yvalue) in self.thumbstickChangedHandler("THUMB-RIGHT", xvalue, yvalue) }
        
        controller.extendedGamepad?.leftThumbstickButton?.pressedChangedHandler =  { (button, value, pressed) in self.buttonChangedHandler("THUMB-LEFT", pressed, self.overlayLeftThumb) }
        controller.extendedGamepad?.rightThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in self.buttonChangedHandler("THUMB-RIGHT", pressed, self.overlayRightThumb) }
		
		
	
	//	controller.extendedGamepad?.dpad.valueChangedHandler =  { (button, value, pressed) in //self.triggerChangedHandler("d-pad", value, self.overlayUp) }
		
		
    }


	
	//当控制器断开连接时，发送断开连接的log
    @objc func didDisconnectController(_ notification: Notification) {
        writeToLog(newLine: "Disconnect to Controller")
        
		//移除控制器
        let controller = notification.object as! GCController
        controllers.remove(controller)
        
        delegate?.inputManager(self, didDisconnect: controller)
    }

///核心部分///
	
	
	
//业务部分
	
    //获取系统时间戳
    func getTimestamp() -> String {
        return dateFormatter.string(from: Date())
    }
    
	//按键句柄，将按键信息打印在控制台，同时在UI绘制出来
    func buttonChangedHandler(_ button: String, _ pressed: Bool, _ overlay: UIView) {
        if pressed {
            self.writeToLog(newLine: getTimestamp() + " - " + button + " " + "Pressed")
            self.view.addSubview(overlay)
        } else {
            self.writeToLog(newLine: getTimestamp() + " - " + button + " " + "Released")
            overlay.removeFromSuperview()
        }
    }
    
	//触摸板偏移句柄，将触摸板信息打印在控制台，同时在UI绘制出来
    func triggerChangedHandler(_ button: String, _ value: Float, _ pressed: Bool) {
        if pressed {
            let analogValue = String(format: "%.2f", value)
            self.writeToLog(newLine: getTimestamp() + " - " + button + " " + analogValue)
        }
    }
    
	//摇杆偏移值句柄，将摇杆偏移信息打印在控制台，同时在UI绘制出来
    func thumbstickChangedHandler(_ button: String, _ xvalue: Float, _ yvalue: Float) {
        let analogValueX = String(format: "%.2f", xvalue)
        let analogValueY = String(format: "%.2f", yvalue)
        self.writeToLog(newLine: getTimestamp() + " - " + button + " " + analogValueX + " / " + analogValueY)
    }
    
}


//执行连接/断开连接的委托事件
protocol InputManagerDelegate: class {
    func inputManager(_ manager: ViewController, didConnect controller: GCController)
    func inputManager(_ manager: ViewController, didDisconnect controller: GCController)
}


//画板部分
class Draw: UIView {
    
	//测试小红点的底色
    override init(frame: CGRect) {
		super.init(frame: frame)
		UIColor(white: 1, alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	//画一个测试小红点
    override func draw(_ rect: CGRect) {
        // Rectangle
        // let h = rect.height
        // let w = rect.width
        // let drect = CGRect(x: (w * 0.25),y: (h * 0.25),width: (w * 0.5),height: (h * 0.5))
        // let bpath:UIBezierPath = UIBezierPath(rect: drect)
        
        // 画圆点
        let bpath = UIBezierPath(arcCenter: CGPoint(x: rect.height/2, y: rect.width/2),
                                 radius: CGFloat(rect.height/2),
                                 startAngle: CGFloat(0),
                                 endAngle: CGFloat(Double.pi * 2),
                                 clockwise: true)
		// 红色
        let color: UIColor = UIColor.red
        color.set()
        
        // bpath.stroke()
        bpath.fill()
    }

}


引用库:  
在info.plist中添加：
Privacy - Bluetooth Peripheral Usage Description

一、执行配置／连接方法
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self configureGameControllers];
}
.

二、配置方法
//配置 GameController
- (void)configureGameControllers {
    NSLog(@"configure GameController");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidConnect:) name:GCControllerDidConnectNotification object:nil];
.
.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameControllerDidDisconnect:) name:GCControllerDidDisconnectNotification object:nil];
.
.
    [GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
        // we don't use any code here since when new controllers are found we will get notifications
    }];
}
.

三、判断连接状态，成功则连接 GameController
//判断连接状态
- (void)gameControllerDidConnect:(NSNotification *)notification {
    [self configureConnectedGameControllers];
    NSLog(@"connect GameController Device success");
}

- (void)gameControllerDidDisconnect:(NSNotification *)notification {
    NSLog(@"fail to connect GameController Device");
}
.
.
//连接 GameControllers
- (void)configureConnectedGameControllers {
    for (GCController *controller in [GCController controllers]) {
        [self setupController:controller];
    }
}
.

四、配置按键
//配置按键
- (void)setupController:(GCController *)controller
{
    NSLog(@"setupController");

    /** 对X,Y,A,B键位进行注册
     **/
    GCControllerButtonValueChangedHandler Y_ButtonHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"Y_button (value : %f), (pressed : %d)", value, pressed);
    };

    GCControllerButtonValueChangedHandler X_ButtonHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
NSLog(@"X_button (value : %f), (pressed : %d)", value, pressed);
    };

    GCControllerButtonValueChangedHandler A_ButtonHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"A_button (value : %f), (pressed : %d)", value, pressed);
    };

    GCControllerButtonValueChangedHandler B_ButtonHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"B_button (value : %f), (pressed : %d)", value, pressed);
    };

    if (controller.gamepad) {
        controller.gamepad.buttonA.valueChangedHandler = A_ButtonHandler;
        controller.gamepad.buttonB.valueChangedHandler = B_ButtonHandler;
        controller.gamepad.buttonX.valueChangedHandler = X_ButtonHandler;
        controller.gamepad.buttonY.valueChangedHandler = Y_ButtonHandler;
    }

    if (controller.extendedGamepad) {
        controller.extendedGamepad.buttonA.valueChangedHandler = A_ButtonHandler;
        controller.extendedGamepad.buttonB.valueChangedHandler = B_ButtonHandler;
        controller.extendedGamepad.buttonX.valueChangedHandler = X_ButtonHandler;
        controller.extendedGamepad.buttonY.valueChangedHandler = Y_ButtonHandler;
}

    /** 对肩部的键位进行注册
     **/
    GCControllerButtonValueChangedHandler L_ShoulderHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"L_shoulder (value : %f), (pressed : %d)", value, pressed);
    };

    GCControllerButtonValueChangedHandler R_ShoulderHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"R_shoulder (value : %f), (pressed : %d)", value, pressed);
    };
.
    if (controller.gamepad) {
        controller.gamepad.leftShoulder.valueChangedHandler = L_ShoulderHandler;
        controller.gamepad.rightShoulder.valueChangedHandler = R_ShoulderHandler;
}

    if (controller.extendedGamepad) {
        controller.extendedGamepad.leftShoulder.valueChangedHandler = L_ShoulderHandler;
        controller.extendedGamepad.rightShoulder.valueChangedHandler = R_ShoulderHandler;
}

    /** 对扳机进行注册
     **/
    GCControllerButtonValueChangedHandler L_LeftTrigger = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"L_TriggerHandler (value : %f), (pressed : %d)", value, pressed);
    };
    GCControllerButtonValueChangedHandler R_LeftTrigger = ^(GCControllerButtonInput *button, float value, BOOL pressed) {
        NSLog(@"R_TriggerHandler (value : %f), (pressed : %d)", value, pressed);
    };
    if (controller.extendedGamepad) {
        controller.extendedGamepad.leftTrigger.valueChangedHandler = L_LeftTrigger;
        controller.extendedGamepad.rightTrigger.valueChangedHandler = R_LeftTrigger;

    }
.
    /** 对左右滑杆、方向按键进行注册
     **/
    //滑杆
    GCControllerDirectionPadValueChangedHandler L_ThumbHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue) {
        NSLog(@"L_thumbHandler (x : %f), (y : %f)", xValue, yValue);
    };

    GCControllerDirectionPadValueChangedHandler R_ThumbHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue) {
        NSLog(@"R_thumbHandler (x : %f), (y : %f)", xValue, yValue);
    };
    //方向按键
    GCControllerDirectionPadValueChangedHandler dpadChangedHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue){
        NSLog(@"dpad (x : %f), (y : %f)", xValue, yValue);
    };
.
if (controller.extendedGamepad) {

        controller.extendedGamepad.leftThumbstick.valueChangedHandler = L_ThumbHandler;

        controller.extendedGamepad.rightThumbstick.valueChangedHandler = R_ThumbHandler;
    }
    if (controller.gamepad.dpad) {
        controller.gamepad.dpad.valueChangedHandler = dpadChangedHandler;
    }
}
