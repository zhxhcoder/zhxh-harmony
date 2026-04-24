import { vibrator } from '@kit.SensorServiceKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { runningLock } from '@kit.BasicServicesKit';

@Component
export default struct HomePage {
  static readonly NAME: string = 'HomePage';

  @State isVibrating: boolean = false;
  @State isRecording: boolean = false;
  @State keepScreenOn: boolean = false;
  @State isRecordingLooping: boolean = false;
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

    // 如果勾选了屏幕常亮
    if (this.keepScreenOn) {
      this.enableKeepScreenOn();
    }
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
      if (!this.screenLock) {
        this.screenLock = await runningLock.create('screen', runningLock.RunningLockType.BACKGROUND);
      }
      this.screenLock.hold(0); // 0 表示永久锁定
      console.info('Screen keep on enabled');
    } catch (error) {
      console.error('Failed to enable keep screen on: ' + JSON.stringify(error));
    }
  }

  // 关闭屏幕常亮
  disableKeepScreenOn() {
    try {
      if (this.screenLock) {
        this.screenLock.unhold();
        this.screenLock = null;
        console.info('Screen keep on disabled');
      }
    } catch (error) {
      console.error('Failed to disable keep screen on: ' + JSON.stringify(error));
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

  // 统一停止
  stopAll() {
    this.stopVibrate();
    this.stopRecording();
    this.stopRecordingLoop();
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
            // 如果已经在振动中，切换选项时立即生效
            if (this.isVibrating && value) {
              this.enableKeepScreenOn();
            } else if (this.isVibrating && !value) {
              this.disableKeepScreenOn();
            }
          })
        Text($r('app.string.keep_screen_on'))
          .fontSize(14)
          .fontColor('#666666')
      }
      .margin({ top: 20, left: 20 })
      .alignItems(VerticalAlign.Center)

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
            .enabled(this.isVibrating || this.isRecording || this.isRecordingLooping)
            .onClick(() => {
              this.stopAll();
            })
        }
        .width('50%')

        // 右侧录像功能
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
            .enabled(this.isRecording || this.isRecordingLooping || this.isVibrating)
            .onClick(() => {
              this.stopAll();
            })
        }
        .width('50%')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}