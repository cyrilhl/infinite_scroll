import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class InfiniteScrollList extends StatefulWidget {
  final List<Widget> children;
  final Function(int page)? onLoadingStart;
  final bool everythingLoaded;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool reverse;
  final bool? primary;
  final double? itemExtent;
  final Widget? prototypeItem;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final Widget? loadingWidget;

  final bool isRefreshing;

  const InfiniteScrollList({
    Key? key,
    required this.children,
    this.onLoadingStart,
    this.everythingLoaded = false,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.reverse = false,
    this.primary,
    this.itemExtent,
    this.prototypeItem,
    this.cacheExtent,
    this.semanticChildCount,
    this.restorationId,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.loadingWidget,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  State<InfiniteScrollList> createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final ScrollController _sc = ScrollController();
  bool _loading = false;
  int page = 1;
  bool _handleSizeChange = false;

  // previous refresh status
  bool _previousIsRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(_checkIfNeedMore);
    _previousIsRefreshing = widget.isRefreshing;
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isRefreshing && widget.isRefreshing) {
      // reset page when refreshing
      setState(() {
        page = 1;
        _loading = false;
      });
    }

    _previousIsRefreshing = oldWidget.isRefreshing;
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _checkIfNeedMore({isSizeChanged = false}) async {
    // when refresh, not load more
    if (widget.isRefreshing) return;

    if (_sc.position.atEdge && (_sc.offset > 0 || isSizeChanged)) {
      if (!widget.everythingLoaded &&
          !_loading &&
          widget.onLoadingStart != null) {
        setState(() {
          _loading = true;
        });
        await widget.onLoadingStart?.call(page++);
        _loading = false;
      }
    }
  }

  Future<void> _removeLoader() async {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (widget.children.isNotEmpty &&
          mounted &&
          _sc.position.maxScrollExtent == 0) {
        setState(() {
          _loading = false;
        });
        timer.cancel();
      }
    });
  }

  List<Widget> get getChildrens {
    List<Widget> childrens = [];
    for (Widget child in widget.children) {
      childrens.add(child);
    }

    if (!widget.everythingLoaded) {
      childrens.add(
        widget.loadingWidget ??
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
      );
    }

    return childrens;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty && widget.isRefreshing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.loadingWidget ?? const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            const Text('Loading...'),
          ],
        ),
      );
    }

    if (widget.children.isEmpty && _loading) {
      return widget.loadingWidget ??
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_handleSizeChange) {
            _handleSizeChange = true;
          } else {
            _handleSizeChange = false;
            _checkIfNeedMore(isSizeChanged: true);
          }
        });
        return false;
      },
      child: ListView(
        physics: widget.physics,
        reverse: widget.reverse,
        primary: widget.primary,
        itemExtent: widget.itemExtent,
        prototypeItem: widget.prototypeItem,
        cacheExtent: widget.cacheExtent,
        semanticChildCount: widget.semanticChildCount,
        restorationId: widget.restorationId,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        dragStartBehavior: widget.dragStartBehavior,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        clipBehavior: widget.clipBehavior,
        controller: _sc,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        children: getChildrens,
      ),
    );
  }

  int get currentPage => page;

  void resetPage() {
    setState(() {
      page = 1;
      _loading = false;
    });
  }
}
