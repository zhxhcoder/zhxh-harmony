@Component
struct MinePage {
  build() {
    Column() {
      Text('我的页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}