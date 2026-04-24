@Component
export default struct DiscoverPage {
  build() {
    Column() {
      Text('发现页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}