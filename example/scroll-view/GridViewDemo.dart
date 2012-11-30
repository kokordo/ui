//Sample Code: ScrollView

import 'package:rikulo/view.dart';
import 'package:rikulo/html.dart';
import 'package:rikulo/util.dart';
import 'package:rikulo/event.dart';

void main() {
  final View mainView = new View()..addToDocument();
  final int barSize = 50, barInnerSize = 40;
  bool compact = browser.size.width < 500 || browser.size.height < 500; // responsive
  final View container = new View();
  final String occupation = compact ? "100%" : "80%";
  container.profile.text = 
      "location: center center; width: $occupation; height: $occupation";
  mainView.addChild(container);
  
  final ScrollView view = new ScrollView();
  view.profile.text = "location: bottom right";
  view.classes.add("list-view");
  
  view.on.preLayout.add((LayoutEvent event) {
    final cs = new DomAgent(container.node).innerSize;
    view.width = cs.width - barSize;
    view.height = cs.height - barSize;
  });
  
  final ScrollView hbar = new ScrollView(direction: Dir.HORIZONTAL);
  hbar.profile.anchorView = view;
  hbar.profile.text = "location: north center; width: 100%; height: ${barSize}px";
  hbar.classes.add("list-view list-view-hbar");
  
  final ScrollView vbar = new ScrollView(direction: Dir.VERTICAL);
  vbar.profile.anchorView = view;
  vbar.profile.text = "location: west center; width: ${barSize}px; height: 100%";
  vbar.classes.add("list-view list-view-vbar");
  
  // link ScrollView
  view.on.scrollStart.add((ScrollEvent event) {
    hbar.scroller.stop();
    vbar.scroller.stop();
  });
  view.on.scrollMove.add((ScrollEvent event) {
    hbar.scroller.scrollPosition = vbar.scroller.scrollPosition = event.state.position;
  });
  
  hbar.on.scrollStart.add((ScrollEvent event) {
    view.scroller.stop();
    vbar.scroller.stop();
  });
  hbar.on.scrollMove.add((ScrollEvent event) {
    view.scroller.scrollPosition = 
        new Offset(event.state.position.x, view.scroller.scrollPosition.y);
  });
  
  vbar.on.scrollStart.add((ScrollEvent event) {
    view.scroller.stop();
    hbar.scroller.stop();
  });
  vbar.on.scrollMove.add((ScrollEvent event) {
    view.scroller.scrollPosition = 
        new Offset(view.scroller.scrollPosition.x, event.state.position.y);
  });
  
  // fill content
  final int cellSize = 100, rowCount = 30, columnCount = 30;;
  
  for (int x = 0; x < columnCount; x++) {
    for (int y = 0; y < rowCount; y++) {
      TextView child = new TextView("(${y+1}, ${x+1})");
      child.classes.add("list-item");
      child.style.lineHeight = Css.px(cellSize - 2);
      child.width = child.height = cellSize;
      child.left = x * cellSize;
      child.top = y * cellSize;
      view.addChild(child);
    }
  }
  
  for (int x = 0; x < columnCount; x++) {
    TextView child = new TextView("Column ${x+1}");
    child.classes.add("list-item");
    child.style.lineHeight = Css.px(barInnerSize);
    child.width = cellSize;
    child.height = barInnerSize;
    child.top = 0;
    child.left = x * cellSize;
    hbar.addChild(child);
  }
  
  for (int y = 0; y < rowCount; y++) {
    TextView child = new TextView("R-${y+1}");
    child.classes.add("list-item");
    child.style.lineHeight = Css.px(cellSize - 2);
    child.height = cellSize;
    child.width = barInnerSize;
    child.left = 0;
    child.top = y * cellSize;
    vbar.addChild(child);
  }
  
  final Size contentSize = view.contentSize;
  hbar.contentSize = new Size(contentSize.width, barSize);
  vbar.contentSize = new Size(barSize, contentSize.height);
  
  container.addChild(view);
  container.addChild(hbar);
  container.addChild(vbar);
}
