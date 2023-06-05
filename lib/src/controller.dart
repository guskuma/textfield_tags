import 'package:flutter/material.dart';

typedef Validator = String? Function(String tag);
typedef TagsBuilder<T> = T Function(
  BuildContext context,
  ScrollController sc,
  List<String> tags,
  void Function(String tag) onDeleteTag,
);
typedef InputFieldBuilder<T> = TagsBuilder<T> Function(
  BuildContext context,
  TextEditingController tec,
  FocusNode fn,
  String? error,
  void Function(String value)? onChanged,
  void Function(String value)? onSubmitted,
);

enum LetterCase { normal, small, capital }

abstract class TextfieldTagsNotifier extends ChangeNotifier {
  TextfieldTagsNotifier();

  final scrollController = ScrollController();

  late TextEditingController? textEditingController;
  late FocusNode? focusNode;

  Function(String tag)? onTagAdded;
  Function(String tag)? onTagRemoved;
  Function(List<String>? tags)? onTagsChanged;

  late Set<String>? _textSeparators;
  late List<String>? _tags;

  List<String>? get tags => _tags;

  void initS(
    List<String>? initialTags,
    TextEditingController? tec,
    FocusNode? fn,
    List<String>? textSeparators,
  ) {
    _textSeparators = (textSeparators?.toSet() ?? {});
    textEditingController = tec ?? TextEditingController();
    focusNode = fn ?? FocusNode();
    _tags = initialTags?.toList() ?? [];
  }

  set addTag(String tag) {
    _tags!.add(tag);
    // debugPrint('Tag added: $tag');
    onTagAdded?.call(tag);
    onTagsChanged?.call(_tags);
  }

  set removeTag(String tag) {
    _tags!.remove(tag);
    // debugPrint('Tag removed: $tag');
    onTagRemoved?.call(tag);
    onTagsChanged?.call(_tags);
  }

  onChanged(String value);
  onSubmitted(String value);
  onTagDelete(String tag);
}

class TextfieldTagsController extends TextfieldTagsNotifier {
  LetterCase? _letterCase;
  Validator? _validator;
  String? _error;

  TextfieldTagsController();

  void init(
    Validator? validator,
    LetterCase? letterCase,
    List<String>? initialTags,
    TextEditingController? tec,
    FocusNode? fn,
    List<String>? textSeparators,
  ) {
    super.initS(initialTags, tec, fn, textSeparators);
    _letterCase = letterCase ?? LetterCase.normal;
    _validator = validator;
  }

  bool get hasError => _error != null && _error!.isNotEmpty;
  bool get hasTags => _tags != null && _tags!.isNotEmpty;
  String? get getError => _error;

  void scrollTags({
    bool forward = true,
    int speedInMilliseconds = 300,
    double? distance,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        if (distance != null) {
          scrollController.animateTo(
            distance,
            duration: Duration(milliseconds: speedInMilliseconds),
            curve: Curves.linear,
          );
        } else {
          if (forward) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: speedInMilliseconds),
              curve: Curves.linear,
            );
          } else {
            scrollController.animateTo(
              scrollController.position.minScrollExtent,
              duration: Duration(milliseconds: speedInMilliseconds),
              curve: Curves.linear,
            );
          }
        }
      }
    });
  }

  void _onTagOperation(String tag) {
    if (tag.isNotEmpty) {
      textEditingController!.clear();
      _error = _validator != null ? _validator!(tag) : null;
      if (!hasError) {
        super.addTag = tag;
        scrollTags();
      }
      notifyListeners();
    }
  }

  String? findSeparator(String value, Set<String> textSeparators) {
    return textSeparators.cast<String?>().firstWhere(
          (element) => value.contains(element!) && value.indexOf(element) != 0,
      orElse: () => null,
    );
  }

  String processText(String text, LetterCase letterCase) {
    final trimmedText = text.trim();
    if (letterCase == LetterCase.small) {
      return trimmedText.toLowerCase();
    } else if (letterCase == LetterCase.capital) {
      return trimmedText.toUpperCase();
    }
    return trimmedText;
  }

  @override
  void onChanged(String value) {
    final separator = findSeparator(value, _textSeparators!);
    if (separator != null) {
      final splits = value.split(separator);
      final lastIndex = splits.length > 1 ? splits.length - 2 : splits.length - 1;
      final processedText = processText(splits.elementAt(lastIndex), _letterCase!);
      _onTagOperation(processedText);
    }
  }


  @override
  void onSubmitted(String value) {
    String convertLetterCase(String input, LetterCase? letterCase) {
      if (letterCase == LetterCase.small) {
        return input.toLowerCase();
      } else if (letterCase == LetterCase.capital) {
        return input.toUpperCase();
      }
      return input;
    }

    final trimmedValue = value.trim();
    final convertedValue = convertLetterCase(trimmedValue, _letterCase);
    _onTagOperation(convertedValue);
  }


  @override
  set addTag(String value) {
    onSubmitted(value);
  }

  @override
  void onTagDelete(String tag) {
    removeTag = tag;
    notifyListeners();
  }

  set setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearTags() {
    _error = null;
    _tags!.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController!.dispose();
    focusNode!.dispose();
    scrollController.dispose();
  }
}
