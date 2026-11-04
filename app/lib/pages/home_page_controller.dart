import 'package:flutter/material.dart';
import 'package:zhichuan_app/pages/home_page.dart';
import 'package:refena_flutter/refena_flutter.dart';

class HomePageVm {
  final PageController controller;
  final HomeTab currentTab;
  final void Function(HomeTab) changeTab;

  HomePageVm({
    required this.controller,
    required this.currentTab,
    required this.changeTab,
  });
}

final homePageControllerProvider = ReduxProvider<HomePageController, HomePageVm>(
  (ref) => HomePageController(),
);

class HomePageController extends ReduxNotifier<HomePageVm> {
  @override
  HomePageVm init() {
    return HomePageVm(
      controller: PageController(),
      currentTab: HomeTab.receive,
      changeTab: (tab) => redux.dispatch(ChangeTabAction(tab)),
    );
  }
}

class ChangeTabAction extends ReduxAction<HomePageController, HomePageVm> {
  final HomeTab tab;

  ChangeTabAction(this.tab);

  @override
  HomePageVm reduce() {
    // 3D质感的页面切换：快速滑入带轻微回弹，而非生硬跳转
    state.controller.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    return HomePageVm(
      controller: state.controller,
      currentTab: tab,
      changeTab: state.changeTab,
    );
  }
}
