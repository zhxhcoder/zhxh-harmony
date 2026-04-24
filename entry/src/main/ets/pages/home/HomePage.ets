import { vibrator } from '@kit.SensorServiceKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { runningLock } from '@kit.BasicServicesKit';
import { componentSnapshot, window } from '@kit.ArkUI';

@Component
export default struct HomePage {
  static readonly NAME: string = 'HomePage';
  @State isVibrating: boolean = false;
  @State isRecording: boolean = false;
  @State keepScreenOn: boolean = false;
  @State isRecordingLooping: boolean = false;
  @State isCapturing: boolean = false;
  @State captureCount: number = 0;
  private vibrateInterval: number = -1;
  private recordingLoopInterval: number = -1;
  private captureSession: camera.CaptureSession | null = null;
  private screenLock: runningLock.RunningLock | null = null;

  private getAppContext(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  // 开始持续振动
  startVibrate() {
    this.isVibrating = true;
    this.doVibrate();
    this.vibrateInterval = setInterval(() => {
      this.doVibrate();
    }, 1000);
  }

  // 执行单次振动
  doVibrate() {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 3000
      }, {
        usage: 'alarm'
      }).then(() => {
        console.info('Vibration started');
      }).catch((err: Error) => {
        console.error('Failed to start vibration: ' + JSON.stringify(err));
      });
    } catch (error) {
      console.error('Vibration error: ' + JSON.stringify(error));
    }
  }

  // 停止振动
  stopVibrate() {
    this.isVibrating = false;
    if (this.vibrateInterval !== -1) {
      clearInterval(this.vibrateInterval);
      this.vibrateInterval = -1;
    }
    try {
      vibrator.stopVibration().then(() => {
        console.info('Vibration stopped');
      }).catch((err: Error) => {
        console.error('Failed to stop vibration: ' + JSON.stringify(err));
      });
    } catch (error) {
      console.error('Stop vibration error: ' + JSON.stringify(error));
    }

    // 释放屏幕常亮
    this.disableKeepScreenOn();
  }

  // 开启屏幕常亮
  async enableKeepScreenOn() {
    try {
      // 获取上下文
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (context) {
        const win = await window.getLastWindow(context);
        await win.setWindowKeepScreenOn(true);
        console.info('Screen keep on enabled via window');
        return;
      }
      // 备用方案使用runningLock
      console.warn('Context not available, using runningLock');
      if (!this.screenLock) {
        this.screenLock = await runningLock.create('screen', runningLock.RunningLockType.BACKGROUND);
      }
      this.screenLock.hold(0);
      console.info('Screen keep on enabled via runningLock');
    } catch (error) {
      console.error('Failed to enable keep screen on: ' + JSON.stringify(error));
      // 备用方案使用runningLock
      try {
        if (!this.screenLock) {
          this.screenLock = await runningLock.create('screen', runningLock.RunningLockType.BACKGROUND);
        }
        this.screenLock.hold(0);
        console.info('Screen keep on enabled via runningLock');
      } catch (err) {
        console.error('Failed to enable keep screen on via runningLock: ' + JSON.stringify(err));
      }
    }
  }

  // 关闭屏幕常亮
  async disableKeepScreenOn() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (context) {
        const win = await window.getLastWindow(context);
        await win.setWindowKeepScreenOn(false);
        console.info('Screen keep on disabled via window');
      }
    } catch (error) {
      console.error('Failed to disable keep screen on via window: ' + JSON.stringify(error));
    }
    // 同时释放 runningLock
    try {
      if (this.screenLock) {
        this.screenLock.unhold();
        this.screenLock = null;
      }
    } catch (err) {
      console.error('Failed to release screen lock: ' + JSON.stringify(err));
    }
  }

  // 开始录像
  async startRecording() {
    try {
      // 使用相机选择器打开相机并开始录像
      const pickerResult = await cameraPicker.pick(this.getAppContext(), [
        cameraPicker.PickerMediaType.PHOTO
      ], {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      });

      if (pickerResult) {
        this.isRecording = true;
        console.info('Camera recording started');
      }
    } catch (error) {
      console.error('Failed to start recording: ' + JSON.stringify(error));
    }
  }

  // 停止录像
  stopRecording() {
    this.isRecording = false;
    if (this.captureSession) {
      this.captureSession.release();
      this.captureSession = null;
    }
    console.info('Camera recording stopped');
  }

  // 循环录像：启动→停止→循环
  async startRecordingLoop() {
    if (this.isRecordingLooping) {
      return;
    }
    this.isRecordingLooping = true;

    const loopOnce = async () => {
      if (!this.isRecordingLooping) {
        return;
      }

      // 启动录像
      await this.startRecording();
      console.info('Recording loop: started');

      // 等待2秒
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 2000);
      });

      if (!this.isRecordingLooping) {
        return;
      }

      // 停止录像
      this.stopRecording();
      console.info('Recording loop: stopped');

      // 等待1秒
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 1000);
      });

      // 继续循环
      if (this.isRecordingLooping) {
        loopOnce();
      }
    };

    loopOnce();
  }

  // 停止循环录像
  stopRecordingLoop() {
    this.isRecordingLooping = false;
    this.stopRecording();
  }

  // 执行截屏
  async doCapture() {
    try {
      this.captureCount++;
      const currentCount = this.captureCount;
      console.info('Screenshot ' + currentCount + ' started');

      // 对整个页面截屏，使用当前页面的根组件ID
      const pixelMap = await componentSnapshot.get('root');

      console.info('Screenshot ' + currentCount + ' captured successfully');
    } catch (error) {
      console.error('Screenshot ' + this.captureCount + ' failed: ' + JSON.stringify(error));
    }
  }

  // 循环截屏：截屏→等待→截屏→循环
  async startCaptureLoop() {
    if (this.isCapturing) {
      return;
    }
    this.isCapturing = true;
    this.captureCount = 0;

    const loopOnce = async () => {
      if (!this.isCapturing) {
        return;
      }

      // 执行截屏
      await this.doCapture();

      // 等待3秒
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 3000);
      });

      // 继续循环
      if (this.isCapturing) {
        loopOnce();
      }
    };

    loopOnce();
  }

  // 停止循环截屏
  stopCaptureLoop() {
    this.isCapturing = false;
  }

  // 统一停止
  stopAll() {
    this.stopVibrate();
    this.stopRecording();
    this.stopRecordingLoop();
    this.stopCaptureLoop();
  }

  aboutToDisappear() {
    this.stopAll();
  }

  build() {
    Column({ space: 20 }) {
      // 屏幕常亮选项
      Row({ space: 10 }) {
        Checkbox()
          .select(this.keepScreenOn)
          .onChange((value: boolean) => {
            this.keepScreenOn = value;
            if (value) {
              this.enableKeepScreenOn();
            } else if (!value) {
              this.disableKeepScreenOn();
            }
          })
        Text($r('app.string.keep_screen_on'))
          .fontSize(14)
          .fontColor('#666666')
      }
      .margin({ top: 20, left: 20 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Row({ space: 30 }) {
          // 左侧振动功能
          Column({ space: 20 }) {
            Text('极速耗电测试')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 30 })

            Text(this.isVibrating ? '正在持续振动...' : '点击开始持续振动')
              .fontSize(16)
              .fontColor(this.isVibrating ? '#FF4444' : '#666666')

            Button($r('app.string.vibrate_start'))
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.primary_button'))
              .enabled(!this.isVibrating)
              .onClick(() => {
                this.startVibrate();
              })

            Button($r('app.string.btn_stop'))
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.stop_button'))
              .enabled(this.isVibrating || this.isRecording || this.isRecordingLooping || this.isCapturing)
              .onClick(() => {
                this.stopAll();
              })
          }
          .width(200)

          // 中间录像功能
          Column({ space: 20 }) {
            Text('扫描录像')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 30 })

            Text(this.isRecordingLooping ? '循环录像中...' : (this.isRecording ? '正在录像中...' : '点击开始循环录像'))
              .fontSize(16)
              .fontColor(this.isRecordingLooping ? '#FF6B00' : (this.isRecording ? '#FF4444' : '#666666'))

            Button(this.isRecordingLooping ? '停止循环' : $r('app.string.btn_scan_record'))
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor(this.isRecordingLooping ? $r('app.color.stop_button') : '#FF6B00')
              .enabled(!this.isRecording || this.isRecordingLooping)
              .onClick(() => {
                if (this.isRecordingLooping) {
                  this.stopRecordingLoop();
                } else {
                  this.startRecordingLoop();
                }
              })

            Button($r('app.string.btn_stop'))
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.stop_button'))
              .enabled(this.isRecording || this.isRecordingLooping || this.isVibrating || this.isCapturing)
              .onClick(() => {
                this.stopAll();
              })
          }
          .width(200)

          // 右侧截屏功能
          Column({ space: 20 }) {
            Text('无线截屏')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 30 })

            Text(this.isCapturing ? '第' + this.captureCount + '次截屏中...' : '点击开始循环截屏')
              .fontSize(16)
              .fontColor(this.isCapturing ? '#44AAFF' : '#666666')

            Button(this.isCapturing ? '停止循环' : '开始截屏')
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor(this.isCapturing ? $r('app.color.stop_button') : '#44AAFF')
              .enabled(!this.isCapturing)
              .onClick(() => {
                if (this.isCapturing) {
                  this.stopCaptureLoop();
                } else {
                  this.startCaptureLoop();
                }
              })

            Button($r('app.string.btn_stop'))
              .width(160)
              .height(50)
              .fontSize(18)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.stop_button'))
              .enabled(this.isCapturing || this.isRecording || this.isRecordingLooping || this.isVibrating)
              .onClick(() => {
                this.stopAll();
              })
          }
          .width(200)
        }
        .padding({ left: 20, right: 20 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .id('root')
  }
}