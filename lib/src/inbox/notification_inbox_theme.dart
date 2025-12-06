import 'package:flutter/material.dart';

@immutable
class NotificationInboxTheme {
  const NotificationInboxTheme({
    this.backgroundColor,
    this.unreadBackgroundColor,
    this.readBackgroundColor,
    this.unreadTitleStyle,
    this.readTitleStyle,
    this.bodyStyle,
    this.subtitleStyle,
    this.timestampStyle,
    this.chipStyle,
    this.emptyState,
    this.leadingBuilder,
    this.trailingBuilder,
    this.dateFormat,
    this.dividerColor,
  });

  final Color? backgroundColor;
  final Color? unreadBackgroundColor;
  final Color? readBackgroundColor;
  final TextStyle? unreadTitleStyle;
  final TextStyle? readTitleStyle;
  final TextStyle? bodyStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? timestampStyle;
  final ChipThemeData? chipStyle;
  final Widget? emptyState;
  final Widget Function(BuildContext context, bool isRead)? leadingBuilder;
  final Widget Function(BuildContext context)? trailingBuilder;
  final String Function(DateTime timestamp)? dateFormat;
  final Color? dividerColor;

  NotificationInboxTheme copyWith({
    Color? backgroundColor,
    Color? unreadBackgroundColor,
    Color? readBackgroundColor,
    TextStyle? unreadTitleStyle,
    TextStyle? readTitleStyle,
    TextStyle? bodyStyle,
    TextStyle? subtitleStyle,
    TextStyle? timestampStyle,
    ChipThemeData? chipStyle,
    Widget? emptyState,
    Widget Function(BuildContext context, bool isRead)? leadingBuilder,
    Widget Function(BuildContext context)? trailingBuilder,
    String Function(DateTime timestamp)? dateFormat,
    Color? dividerColor,
  }) {
    return NotificationInboxTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      unreadBackgroundColor:
          unreadBackgroundColor ?? this.unreadBackgroundColor,
      readBackgroundColor: readBackgroundColor ?? this.readBackgroundColor,
      unreadTitleStyle: unreadTitleStyle ?? this.unreadTitleStyle,
      readTitleStyle: readTitleStyle ?? this.readTitleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      timestampStyle: timestampStyle ?? this.timestampStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      emptyState: emptyState ?? this.emptyState,
      leadingBuilder: leadingBuilder ?? this.leadingBuilder,
      trailingBuilder: trailingBuilder ?? this.trailingBuilder,
      dateFormat: dateFormat ?? this.dateFormat,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }
}

