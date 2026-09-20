import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Keep the DOM input and its composing value alive across Flutter rebuilds.
class ImeTextField extends StatefulWidget {
  const ImeTextField({super.key, this.controller, this.obscureText = false,
    this.autofocus = false, this.readOnly = false, this.textInputAction,
    this.onSubmitted, this.onChanged, this.style, this.decoration,
    this.minLines, this.maxLines = 1});
  final TextEditingController? controller;
  final bool obscureText, autofocus, readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted, onChanged;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? minLines, maxLines;
  @override
  State<ImeTextField> createState() => _ImeTextFieldState();
}

class _ImeTextFieldState extends State<ImeTextField> {
  web.HTMLElement? _element;
  bool _composing = false, _fromBrowser = false;
  bool get _multiline => widget.maxLines != 1 || (widget.minLines ?? 1) > 1;
  String get _text => _multiline
      ? (_element as web.HTMLTextAreaElement).value
      : (_element as web.HTMLInputElement).value;
  void _setText(String text) {
    if (_multiline) {
      (_element as web.HTMLTextAreaElement).value = text;
    } else {
      (_element as web.HTMLInputElement).value = text;
    }
  }
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_sync);
  }
  @override
  void didUpdateWidget(covariant ImeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_sync);
      widget.controller?.addListener(_sync);
      _sync();
    }
  }
  void _sync() {
    if (_element == null || _composing || _fromBrowser) return;
    final text = widget.controller?.text;
    if (text != null && text != _text) _setText(text);
  }
  void _publish() {
    if (!mounted || _element == null || _composing) return;
    final text = _text;
    final start = _multiline ? (_element as web.HTMLTextAreaElement).selectionStart
        : (_element as web.HTMLInputElement).selectionStart ?? text.length;
    final end = _multiline ? (_element as web.HTMLTextAreaElement).selectionEnd
        : (_element as web.HTMLInputElement).selectionEnd ?? text.length;
    _fromBrowser = true;
    widget.controller?.value = TextEditingValue(text: text,
        selection: TextSelection(baseOffset: start, extentOffset: end));
    _fromBrowser = false;
    widget.onChanged?.call(text);
  }
  void _created(Object element) {
    final input = element as web.HTMLElement;
    _element = input;
    input.setAttribute('lang', 'ko');
    input.setAttribute('aria-label', widget.decoration?.hintText ?? '텍스트 입력');
    input.setAttribute('placeholder', widget.decoration?.hintText ?? '');
    if (widget.readOnly) input.setAttribute('readonly', '');
    if (!_multiline) input.setAttribute('type', widget.obscureText ? 'password' : 'text');
    input.style.cssText = 'width:100%;height:100%;box-sizing:border-box;'
        'border:1px solid #9e9e9e;border-radius:10px;background:white;'
        'padding:${_multiline ? '20px' : '0 20px'};resize:none;'
        'font-family:Pretendard,"Malgun Gothic",sans-serif;'
        'font-size:${widget.style?.fontSize ?? 16}px;line-height:1.4;'
        'color:black;outline-color:#5b6790;';
    _setText(widget.controller?.text ?? '');
    input.addEventListener('compositionstart', ((web.Event _) { _composing = true; }).toJS);
    input.addEventListener('compositionend', ((web.Event _) {
      _composing = false;
      _publish();
    }).toJS);
    input.addEventListener('input', ((web.Event _) { _publish(); }).toJS);
    input.addEventListener('keydown', ((web.KeyboardEvent event) {
      if (event.key == 'Enter' && !_multiline && !_composing && !event.isComposing && event.keyCode != 229) {
        event.preventDefault();
        _publish();
        widget.onSubmitted?.call(_text);
      }
    }).toJS);
  }
  @override
  void dispose() {
    widget.controller?.removeListener(_sync);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SizedBox(
    height: _multiline ? (widget.minLines ?? 10) * 24 + 40 : 54,
    child: HtmlElementView.fromTagName(tagName: _multiline ? 'textarea' : 'input', onElementCreated: _created),
  );
}
