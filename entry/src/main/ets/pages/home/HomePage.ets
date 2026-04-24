import { vibrator } from '@kit.SensorServiceKit';

@Component
struct HomePage {
  static readonly NAME: string = 'HomePage';

  @State isVibrating: boolean = false;
  private vibrateInterval: number = -1;

  // 开始持续振动
  startVibrate() {
    this.isVibrating = true;
    // 立即振动一次
    this.doVibrate();
    // 每100ms振动一次，实现持续振动效果
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

  aboutToDisappear() {
    // 页面销毁时停止振动
    this.stopVibrate();
  }

  build() {
    Column({ space: 20 }) {
      Text('极速耗电测试')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Text(this.isVibrating ? '正在持续振动...' : '点击开始持续振动')
        .fontSize(16)
        .fontColor(this.isVibrating ? '#FF4444' : '#666666')

      Button($r('app.string.vibrate_start'))
        .width(200)
        .height(50)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.primary_button'))
        .enabled(!this.isVibrating)
        .onClick(() => {
          this.startVibrate();
        })

      Button($r('app.string.vibrate_stop'))
        .width(200)
        .height(50)
        .fontSize(18)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.stop_button'))
        .enabled(this.isVibrating)
        .onClick(() => {
          this.stopVibrate();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}