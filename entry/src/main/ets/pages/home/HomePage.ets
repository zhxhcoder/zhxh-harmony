import { vibrator } from '@kit.SensorServiceKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';

@Component
export default struct HomePage {
  static readonly NAME: string = 'HomePage';

  @State isVibrating: boolean = false;
  @State isRecording: boolean = false;
  private vibrateInterval: number = -1;
  private captureSession: camera.CaptureSession | null = null;

  private getAppContext(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  // 开始持续振动
  startVibrate() {
    this.isVibrating = true;
    this.doVibrate();
    this.vibrateInterval = setInterval(() => {
      this.doVibrate();
    }, 100);
  }

  // 执行单次振动
  doVibrate() {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 50
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

  // 统一停止
  stopAll() {
    this.stopVibrate();
    this.stopRecording();
  }

  aboutToDisappear() {
    this.stopAll();
  }

  build() {
    Row({ space: 30 }) {
      // 左侧振动功能
      Column({ space: 20 }) {
        Text('极速耗电测试')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 50 })

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
          .enabled(this.isVibrating || this.isRecording)
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
          .margin({ top: 50 })

        Text(this.isRecording ? '正在录像中...' : '点击开始扫描录像')
          .fontSize(16)
          .fontColor(this.isRecording ? '#FF4444' : '#666666')

        Button($r('app.string.btn_scan_record'))
          .width(160)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor('#FF6B00')
          .enabled(!this.isRecording)
          .onClick(() => {
            this.startRecording();
          })

        Button($r('app.string.btn_stop'))
          .width(160)
          .height(50)
          .fontSize(18)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.stop_button'))
          .enabled(this.isRecording || this.isVibrating)
          .onClick(() => {
            this.stopAll();
          })
      }
      .width('50%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}