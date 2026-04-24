import HomePage from './home/HomePage';
import DiscoverPage from './discover/DiscoverPage';
import MinePage from './mine/MinePage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;

  // Tab 页面内容
  @Builder
  TabContentBuilder(index: number) {
    if (index === 0) {
      HomePage()
    } else if (index === 1) {
      DiscoverPage()
    } else {
      MinePage()
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.TabContentBuilder(0)
      }
      .tabBar(this.TabBarBuilder(0, '首页', $r('app.media.ic_home')))

      TabContent() {
        this.TabContentBuilder(1)
      }
      .tabBar(this.TabBarBuilder(1, '发现', $r('app.media.ic_discover')))

      TabContent() {
        this.TabContentBuilder(2)
      }
      .tabBar(this.TabBarBuilder(2, '我的', $r('app.media.ic_mine')))
    }
    .width('100%')
    .height('100%')
    .barWidth('100%')
    .barHeight(56)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }

  @Builder
  TabBarBuilder(index: number, title: string, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? $r('app.color.tab_selected') : $r('app.color.tab_normal'))
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? $r('app.color.tab_selected') : $r('app.color.tab_normal'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }
}