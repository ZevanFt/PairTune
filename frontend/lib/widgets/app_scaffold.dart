import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// 统一的页面脚手架组件
/// 自动处理渐变背景，统一页面结构
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.showGradient = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool showGradient;

  @override
  Widget build(BuildContext context) {
    final content = showGradient
        ? Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.pageBgTop,
                  AppTheme.pageBgMid,
                  AppTheme.pageBgBottom,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: body,
          )
        : body;

    return Scaffold(
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor ?? (showGradient ? Colors.transparent : null),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// 带滚动视图的页面脚手架
/// 自动处理下拉刷新
class AppScrollScaffold extends StatelessWidget {
  const AppScrollScaffold({
    super.key,
    required this.children,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.onRefresh,
    this.showGradient = true,
  });

  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;
  final bool showGradient;

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      padding: padding,
      children: children,
    );

    final body = onRefresh != null
        ? RefreshIndicator(
            onRefresh: onRefresh!,
            child: listView,
          )
        : listView;

    return AppScaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      showGradient: showGradient,
    );
  }
}

/// 表单页面脚手架
/// 统一表单页面结构，自动处理FAB位置
class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.formKey,
    required this.children,
    this.appBar,
    this.onSave,
    this.saveLabel = '保存',
    this.savingLabel = '保存中...',
    this.isSaving = false,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 96),
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onSave;
  final String saveLabel;
  final String savingLabel;
  final bool isSaving;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: appBar,
      body: Form(
        key: formKey,
        child: ListView(
          padding: padding,
          children: children,
        ),
      ),
      floatingActionButton: onSave != null
          ? FloatingActionButton.extended(
              onPressed: isSaving ? null : onSave,
              icon: const Icon(Icons.check_rounded),
              label: Text(isSaving ? savingLabel : saveLabel),
            )
          : null,
    );
  }
}
