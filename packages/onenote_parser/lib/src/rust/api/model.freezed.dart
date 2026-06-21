// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OneNoteContent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OneNoteContent()';
}


}

/// @nodoc
class $OneNoteContentCopyWith<$Res>  {
$OneNoteContentCopyWith(OneNoteContent _, $Res Function(OneNoteContent) __);
}


/// Adds pattern-matching-related methods to [OneNoteContent].
extension OneNoteContentPatterns on OneNoteContent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OneNoteContent_RichText value)?  richText,TResult Function( OneNoteContent_Table value)?  table,TResult Function( OneNoteContent_Image value)?  image,TResult Function( OneNoteContent_EmbeddedFile value)?  embeddedFile,TResult Function( OneNoteContent_Ink value)?  ink,TResult Function( OneNoteContent_Unknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OneNoteContent_RichText() when richText != null:
return richText(_that);case OneNoteContent_Table() when table != null:
return table(_that);case OneNoteContent_Image() when image != null:
return image(_that);case OneNoteContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that);case OneNoteContent_Ink() when ink != null:
return ink(_that);case OneNoteContent_Unknown() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OneNoteContent_RichText value)  richText,required TResult Function( OneNoteContent_Table value)  table,required TResult Function( OneNoteContent_Image value)  image,required TResult Function( OneNoteContent_EmbeddedFile value)  embeddedFile,required TResult Function( OneNoteContent_Ink value)  ink,required TResult Function( OneNoteContent_Unknown value)  unknown,}){
final _that = this;
switch (_that) {
case OneNoteContent_RichText():
return richText(_that);case OneNoteContent_Table():
return table(_that);case OneNoteContent_Image():
return image(_that);case OneNoteContent_EmbeddedFile():
return embeddedFile(_that);case OneNoteContent_Ink():
return ink(_that);case OneNoteContent_Unknown():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OneNoteContent_RichText value)?  richText,TResult? Function( OneNoteContent_Table value)?  table,TResult? Function( OneNoteContent_Image value)?  image,TResult? Function( OneNoteContent_EmbeddedFile value)?  embeddedFile,TResult? Function( OneNoteContent_Ink value)?  ink,TResult? Function( OneNoteContent_Unknown value)?  unknown,}){
final _that = this;
switch (_that) {
case OneNoteContent_RichText() when richText != null:
return richText(_that);case OneNoteContent_Table() when table != null:
return table(_that);case OneNoteContent_Image() when image != null:
return image(_that);case OneNoteContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that);case OneNoteContent_Ink() when ink != null:
return ink(_that);case OneNoteContent_Unknown() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OneNoteRichText field0)?  richText,TResult Function( OneNoteTable field0)?  table,TResult Function( OneNoteImage field0)?  image,TResult Function( OneNoteEmbeddedFile field0)?  embeddedFile,TResult Function( OneNoteInk field0)?  ink,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OneNoteContent_RichText() when richText != null:
return richText(_that.field0);case OneNoteContent_Table() when table != null:
return table(_that.field0);case OneNoteContent_Image() when image != null:
return image(_that.field0);case OneNoteContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that.field0);case OneNoteContent_Ink() when ink != null:
return ink(_that.field0);case OneNoteContent_Unknown() when unknown != null:
return unknown();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OneNoteRichText field0)  richText,required TResult Function( OneNoteTable field0)  table,required TResult Function( OneNoteImage field0)  image,required TResult Function( OneNoteEmbeddedFile field0)  embeddedFile,required TResult Function( OneNoteInk field0)  ink,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case OneNoteContent_RichText():
return richText(_that.field0);case OneNoteContent_Table():
return table(_that.field0);case OneNoteContent_Image():
return image(_that.field0);case OneNoteContent_EmbeddedFile():
return embeddedFile(_that.field0);case OneNoteContent_Ink():
return ink(_that.field0);case OneNoteContent_Unknown():
return unknown();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OneNoteRichText field0)?  richText,TResult? Function( OneNoteTable field0)?  table,TResult? Function( OneNoteImage field0)?  image,TResult? Function( OneNoteEmbeddedFile field0)?  embeddedFile,TResult? Function( OneNoteInk field0)?  ink,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case OneNoteContent_RichText() when richText != null:
return richText(_that.field0);case OneNoteContent_Table() when table != null:
return table(_that.field0);case OneNoteContent_Image() when image != null:
return image(_that.field0);case OneNoteContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that.field0);case OneNoteContent_Ink() when ink != null:
return ink(_that.field0);case OneNoteContent_Unknown() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class OneNoteContent_RichText extends OneNoteContent {
  const OneNoteContent_RichText(this.field0): super._();
  

 final  OneNoteRichText field0;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteContent_RichTextCopyWith<OneNoteContent_RichText> get copyWith => _$OneNoteContent_RichTextCopyWithImpl<OneNoteContent_RichText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_RichText&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteContent.richText(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteContent_RichTextCopyWith<$Res> implements $OneNoteContentCopyWith<$Res> {
  factory $OneNoteContent_RichTextCopyWith(OneNoteContent_RichText value, $Res Function(OneNoteContent_RichText) _then) = _$OneNoteContent_RichTextCopyWithImpl;
@useResult
$Res call({
 OneNoteRichText field0
});




}
/// @nodoc
class _$OneNoteContent_RichTextCopyWithImpl<$Res>
    implements $OneNoteContent_RichTextCopyWith<$Res> {
  _$OneNoteContent_RichTextCopyWithImpl(this._self, this._then);

  final OneNoteContent_RichText _self;
  final $Res Function(OneNoteContent_RichText) _then;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteContent_RichText(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteRichText,
  ));
}


}

/// @nodoc


class OneNoteContent_Table extends OneNoteContent {
  const OneNoteContent_Table(this.field0): super._();
  

 final  OneNoteTable field0;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteContent_TableCopyWith<OneNoteContent_Table> get copyWith => _$OneNoteContent_TableCopyWithImpl<OneNoteContent_Table>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_Table&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteContent.table(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteContent_TableCopyWith<$Res> implements $OneNoteContentCopyWith<$Res> {
  factory $OneNoteContent_TableCopyWith(OneNoteContent_Table value, $Res Function(OneNoteContent_Table) _then) = _$OneNoteContent_TableCopyWithImpl;
@useResult
$Res call({
 OneNoteTable field0
});




}
/// @nodoc
class _$OneNoteContent_TableCopyWithImpl<$Res>
    implements $OneNoteContent_TableCopyWith<$Res> {
  _$OneNoteContent_TableCopyWithImpl(this._self, this._then);

  final OneNoteContent_Table _self;
  final $Res Function(OneNoteContent_Table) _then;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteContent_Table(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteTable,
  ));
}


}

/// @nodoc


class OneNoteContent_Image extends OneNoteContent {
  const OneNoteContent_Image(this.field0): super._();
  

 final  OneNoteImage field0;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteContent_ImageCopyWith<OneNoteContent_Image> get copyWith => _$OneNoteContent_ImageCopyWithImpl<OneNoteContent_Image>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_Image&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteContent.image(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteContent_ImageCopyWith<$Res> implements $OneNoteContentCopyWith<$Res> {
  factory $OneNoteContent_ImageCopyWith(OneNoteContent_Image value, $Res Function(OneNoteContent_Image) _then) = _$OneNoteContent_ImageCopyWithImpl;
@useResult
$Res call({
 OneNoteImage field0
});




}
/// @nodoc
class _$OneNoteContent_ImageCopyWithImpl<$Res>
    implements $OneNoteContent_ImageCopyWith<$Res> {
  _$OneNoteContent_ImageCopyWithImpl(this._self, this._then);

  final OneNoteContent_Image _self;
  final $Res Function(OneNoteContent_Image) _then;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteContent_Image(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteImage,
  ));
}


}

/// @nodoc


class OneNoteContent_EmbeddedFile extends OneNoteContent {
  const OneNoteContent_EmbeddedFile(this.field0): super._();
  

 final  OneNoteEmbeddedFile field0;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteContent_EmbeddedFileCopyWith<OneNoteContent_EmbeddedFile> get copyWith => _$OneNoteContent_EmbeddedFileCopyWithImpl<OneNoteContent_EmbeddedFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_EmbeddedFile&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteContent.embeddedFile(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteContent_EmbeddedFileCopyWith<$Res> implements $OneNoteContentCopyWith<$Res> {
  factory $OneNoteContent_EmbeddedFileCopyWith(OneNoteContent_EmbeddedFile value, $Res Function(OneNoteContent_EmbeddedFile) _then) = _$OneNoteContent_EmbeddedFileCopyWithImpl;
@useResult
$Res call({
 OneNoteEmbeddedFile field0
});




}
/// @nodoc
class _$OneNoteContent_EmbeddedFileCopyWithImpl<$Res>
    implements $OneNoteContent_EmbeddedFileCopyWith<$Res> {
  _$OneNoteContent_EmbeddedFileCopyWithImpl(this._self, this._then);

  final OneNoteContent_EmbeddedFile _self;
  final $Res Function(OneNoteContent_EmbeddedFile) _then;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteContent_EmbeddedFile(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteEmbeddedFile,
  ));
}


}

/// @nodoc


class OneNoteContent_Ink extends OneNoteContent {
  const OneNoteContent_Ink(this.field0): super._();
  

 final  OneNoteInk field0;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteContent_InkCopyWith<OneNoteContent_Ink> get copyWith => _$OneNoteContent_InkCopyWithImpl<OneNoteContent_Ink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_Ink&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteContent.ink(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteContent_InkCopyWith<$Res> implements $OneNoteContentCopyWith<$Res> {
  factory $OneNoteContent_InkCopyWith(OneNoteContent_Ink value, $Res Function(OneNoteContent_Ink) _then) = _$OneNoteContent_InkCopyWithImpl;
@useResult
$Res call({
 OneNoteInk field0
});




}
/// @nodoc
class _$OneNoteContent_InkCopyWithImpl<$Res>
    implements $OneNoteContent_InkCopyWith<$Res> {
  _$OneNoteContent_InkCopyWithImpl(this._self, this._then);

  final OneNoteContent_Ink _self;
  final $Res Function(OneNoteContent_Ink) _then;

/// Create a copy of OneNoteContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteContent_Ink(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteInk,
  ));
}


}

/// @nodoc


class OneNoteContent_Unknown extends OneNoteContent {
  const OneNoteContent_Unknown(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteContent_Unknown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OneNoteContent.unknown()';
}


}




/// @nodoc
mixin _$OneNoteOutlineItem {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteOutlineItem&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'OneNoteOutlineItem(field0: $field0)';
}


}

/// @nodoc
class $OneNoteOutlineItemCopyWith<$Res>  {
$OneNoteOutlineItemCopyWith(OneNoteOutlineItem _, $Res Function(OneNoteOutlineItem) __);
}


/// Adds pattern-matching-related methods to [OneNoteOutlineItem].
extension OneNoteOutlineItemPatterns on OneNoteOutlineItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OneNoteOutlineItem_Group value)?  group,TResult Function( OneNoteOutlineItem_Element value)?  element,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group() when group != null:
return group(_that);case OneNoteOutlineItem_Element() when element != null:
return element(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OneNoteOutlineItem_Group value)  group,required TResult Function( OneNoteOutlineItem_Element value)  element,}){
final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group():
return group(_that);case OneNoteOutlineItem_Element():
return element(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OneNoteOutlineItem_Group value)?  group,TResult? Function( OneNoteOutlineItem_Element value)?  element,}){
final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group() when group != null:
return group(_that);case OneNoteOutlineItem_Element() when element != null:
return element(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OneNoteOutlineGroup field0)?  group,TResult Function( OneNoteOutlineElement field0)?  element,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group() when group != null:
return group(_that.field0);case OneNoteOutlineItem_Element() when element != null:
return element(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OneNoteOutlineGroup field0)  group,required TResult Function( OneNoteOutlineElement field0)  element,}) {final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group():
return group(_that.field0);case OneNoteOutlineItem_Element():
return element(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OneNoteOutlineGroup field0)?  group,TResult? Function( OneNoteOutlineElement field0)?  element,}) {final _that = this;
switch (_that) {
case OneNoteOutlineItem_Group() when group != null:
return group(_that.field0);case OneNoteOutlineItem_Element() when element != null:
return element(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class OneNoteOutlineItem_Group extends OneNoteOutlineItem {
  const OneNoteOutlineItem_Group(this.field0): super._();
  

@override final  OneNoteOutlineGroup field0;

/// Create a copy of OneNoteOutlineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteOutlineItem_GroupCopyWith<OneNoteOutlineItem_Group> get copyWith => _$OneNoteOutlineItem_GroupCopyWithImpl<OneNoteOutlineItem_Group>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteOutlineItem_Group&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteOutlineItem.group(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteOutlineItem_GroupCopyWith<$Res> implements $OneNoteOutlineItemCopyWith<$Res> {
  factory $OneNoteOutlineItem_GroupCopyWith(OneNoteOutlineItem_Group value, $Res Function(OneNoteOutlineItem_Group) _then) = _$OneNoteOutlineItem_GroupCopyWithImpl;
@useResult
$Res call({
 OneNoteOutlineGroup field0
});




}
/// @nodoc
class _$OneNoteOutlineItem_GroupCopyWithImpl<$Res>
    implements $OneNoteOutlineItem_GroupCopyWith<$Res> {
  _$OneNoteOutlineItem_GroupCopyWithImpl(this._self, this._then);

  final OneNoteOutlineItem_Group _self;
  final $Res Function(OneNoteOutlineItem_Group) _then;

/// Create a copy of OneNoteOutlineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteOutlineItem_Group(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteOutlineGroup,
  ));
}


}

/// @nodoc


class OneNoteOutlineItem_Element extends OneNoteOutlineItem {
  const OneNoteOutlineItem_Element(this.field0): super._();
  

@override final  OneNoteOutlineElement field0;

/// Create a copy of OneNoteOutlineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteOutlineItem_ElementCopyWith<OneNoteOutlineItem_Element> get copyWith => _$OneNoteOutlineItem_ElementCopyWithImpl<OneNoteOutlineItem_Element>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteOutlineItem_Element&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteOutlineItem.element(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteOutlineItem_ElementCopyWith<$Res> implements $OneNoteOutlineItemCopyWith<$Res> {
  factory $OneNoteOutlineItem_ElementCopyWith(OneNoteOutlineItem_Element value, $Res Function(OneNoteOutlineItem_Element) _then) = _$OneNoteOutlineItem_ElementCopyWithImpl;
@useResult
$Res call({
 OneNoteOutlineElement field0
});




}
/// @nodoc
class _$OneNoteOutlineItem_ElementCopyWithImpl<$Res>
    implements $OneNoteOutlineItem_ElementCopyWith<$Res> {
  _$OneNoteOutlineItem_ElementCopyWithImpl(this._self, this._then);

  final OneNoteOutlineItem_Element _self;
  final $Res Function(OneNoteOutlineItem_Element) _then;

/// Create a copy of OneNoteOutlineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteOutlineItem_Element(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteOutlineElement,
  ));
}


}

/// @nodoc
mixin _$OneNotePageContent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OneNotePageContent()';
}


}

/// @nodoc
class $OneNotePageContentCopyWith<$Res>  {
$OneNotePageContentCopyWith(OneNotePageContent _, $Res Function(OneNotePageContent) __);
}


/// Adds pattern-matching-related methods to [OneNotePageContent].
extension OneNotePageContentPatterns on OneNotePageContent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OneNotePageContent_Outline value)?  outline,TResult Function( OneNotePageContent_Image value)?  image,TResult Function( OneNotePageContent_EmbeddedFile value)?  embeddedFile,TResult Function( OneNotePageContent_Ink value)?  ink,TResult Function( OneNotePageContent_Unknown value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OneNotePageContent_Outline() when outline != null:
return outline(_that);case OneNotePageContent_Image() when image != null:
return image(_that);case OneNotePageContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that);case OneNotePageContent_Ink() when ink != null:
return ink(_that);case OneNotePageContent_Unknown() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OneNotePageContent_Outline value)  outline,required TResult Function( OneNotePageContent_Image value)  image,required TResult Function( OneNotePageContent_EmbeddedFile value)  embeddedFile,required TResult Function( OneNotePageContent_Ink value)  ink,required TResult Function( OneNotePageContent_Unknown value)  unknown,}){
final _that = this;
switch (_that) {
case OneNotePageContent_Outline():
return outline(_that);case OneNotePageContent_Image():
return image(_that);case OneNotePageContent_EmbeddedFile():
return embeddedFile(_that);case OneNotePageContent_Ink():
return ink(_that);case OneNotePageContent_Unknown():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OneNotePageContent_Outline value)?  outline,TResult? Function( OneNotePageContent_Image value)?  image,TResult? Function( OneNotePageContent_EmbeddedFile value)?  embeddedFile,TResult? Function( OneNotePageContent_Ink value)?  ink,TResult? Function( OneNotePageContent_Unknown value)?  unknown,}){
final _that = this;
switch (_that) {
case OneNotePageContent_Outline() when outline != null:
return outline(_that);case OneNotePageContent_Image() when image != null:
return image(_that);case OneNotePageContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that);case OneNotePageContent_Ink() when ink != null:
return ink(_that);case OneNotePageContent_Unknown() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OneNoteOutline field0)?  outline,TResult Function( OneNoteImage field0)?  image,TResult Function( OneNoteEmbeddedFile field0)?  embeddedFile,TResult Function( OneNoteInk field0)?  ink,TResult Function()?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OneNotePageContent_Outline() when outline != null:
return outline(_that.field0);case OneNotePageContent_Image() when image != null:
return image(_that.field0);case OneNotePageContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that.field0);case OneNotePageContent_Ink() when ink != null:
return ink(_that.field0);case OneNotePageContent_Unknown() when unknown != null:
return unknown();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OneNoteOutline field0)  outline,required TResult Function( OneNoteImage field0)  image,required TResult Function( OneNoteEmbeddedFile field0)  embeddedFile,required TResult Function( OneNoteInk field0)  ink,required TResult Function()  unknown,}) {final _that = this;
switch (_that) {
case OneNotePageContent_Outline():
return outline(_that.field0);case OneNotePageContent_Image():
return image(_that.field0);case OneNotePageContent_EmbeddedFile():
return embeddedFile(_that.field0);case OneNotePageContent_Ink():
return ink(_that.field0);case OneNotePageContent_Unknown():
return unknown();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OneNoteOutline field0)?  outline,TResult? Function( OneNoteImage field0)?  image,TResult? Function( OneNoteEmbeddedFile field0)?  embeddedFile,TResult? Function( OneNoteInk field0)?  ink,TResult? Function()?  unknown,}) {final _that = this;
switch (_that) {
case OneNotePageContent_Outline() when outline != null:
return outline(_that.field0);case OneNotePageContent_Image() when image != null:
return image(_that.field0);case OneNotePageContent_EmbeddedFile() when embeddedFile != null:
return embeddedFile(_that.field0);case OneNotePageContent_Ink() when ink != null:
return ink(_that.field0);case OneNotePageContent_Unknown() when unknown != null:
return unknown();case _:
  return null;

}
}

}

/// @nodoc


class OneNotePageContent_Outline extends OneNotePageContent {
  const OneNotePageContent_Outline(this.field0): super._();
  

 final  OneNoteOutline field0;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNotePageContent_OutlineCopyWith<OneNotePageContent_Outline> get copyWith => _$OneNotePageContent_OutlineCopyWithImpl<OneNotePageContent_Outline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent_Outline&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNotePageContent.outline(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNotePageContent_OutlineCopyWith<$Res> implements $OneNotePageContentCopyWith<$Res> {
  factory $OneNotePageContent_OutlineCopyWith(OneNotePageContent_Outline value, $Res Function(OneNotePageContent_Outline) _then) = _$OneNotePageContent_OutlineCopyWithImpl;
@useResult
$Res call({
 OneNoteOutline field0
});




}
/// @nodoc
class _$OneNotePageContent_OutlineCopyWithImpl<$Res>
    implements $OneNotePageContent_OutlineCopyWith<$Res> {
  _$OneNotePageContent_OutlineCopyWithImpl(this._self, this._then);

  final OneNotePageContent_Outline _self;
  final $Res Function(OneNotePageContent_Outline) _then;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNotePageContent_Outline(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteOutline,
  ));
}


}

/// @nodoc


class OneNotePageContent_Image extends OneNotePageContent {
  const OneNotePageContent_Image(this.field0): super._();
  

 final  OneNoteImage field0;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNotePageContent_ImageCopyWith<OneNotePageContent_Image> get copyWith => _$OneNotePageContent_ImageCopyWithImpl<OneNotePageContent_Image>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent_Image&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNotePageContent.image(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNotePageContent_ImageCopyWith<$Res> implements $OneNotePageContentCopyWith<$Res> {
  factory $OneNotePageContent_ImageCopyWith(OneNotePageContent_Image value, $Res Function(OneNotePageContent_Image) _then) = _$OneNotePageContent_ImageCopyWithImpl;
@useResult
$Res call({
 OneNoteImage field0
});




}
/// @nodoc
class _$OneNotePageContent_ImageCopyWithImpl<$Res>
    implements $OneNotePageContent_ImageCopyWith<$Res> {
  _$OneNotePageContent_ImageCopyWithImpl(this._self, this._then);

  final OneNotePageContent_Image _self;
  final $Res Function(OneNotePageContent_Image) _then;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNotePageContent_Image(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteImage,
  ));
}


}

/// @nodoc


class OneNotePageContent_EmbeddedFile extends OneNotePageContent {
  const OneNotePageContent_EmbeddedFile(this.field0): super._();
  

 final  OneNoteEmbeddedFile field0;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNotePageContent_EmbeddedFileCopyWith<OneNotePageContent_EmbeddedFile> get copyWith => _$OneNotePageContent_EmbeddedFileCopyWithImpl<OneNotePageContent_EmbeddedFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent_EmbeddedFile&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNotePageContent.embeddedFile(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNotePageContent_EmbeddedFileCopyWith<$Res> implements $OneNotePageContentCopyWith<$Res> {
  factory $OneNotePageContent_EmbeddedFileCopyWith(OneNotePageContent_EmbeddedFile value, $Res Function(OneNotePageContent_EmbeddedFile) _then) = _$OneNotePageContent_EmbeddedFileCopyWithImpl;
@useResult
$Res call({
 OneNoteEmbeddedFile field0
});




}
/// @nodoc
class _$OneNotePageContent_EmbeddedFileCopyWithImpl<$Res>
    implements $OneNotePageContent_EmbeddedFileCopyWith<$Res> {
  _$OneNotePageContent_EmbeddedFileCopyWithImpl(this._self, this._then);

  final OneNotePageContent_EmbeddedFile _self;
  final $Res Function(OneNotePageContent_EmbeddedFile) _then;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNotePageContent_EmbeddedFile(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteEmbeddedFile,
  ));
}


}

/// @nodoc


class OneNotePageContent_Ink extends OneNotePageContent {
  const OneNotePageContent_Ink(this.field0): super._();
  

 final  OneNoteInk field0;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNotePageContent_InkCopyWith<OneNotePageContent_Ink> get copyWith => _$OneNotePageContent_InkCopyWithImpl<OneNotePageContent_Ink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent_Ink&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNotePageContent.ink(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNotePageContent_InkCopyWith<$Res> implements $OneNotePageContentCopyWith<$Res> {
  factory $OneNotePageContent_InkCopyWith(OneNotePageContent_Ink value, $Res Function(OneNotePageContent_Ink) _then) = _$OneNotePageContent_InkCopyWithImpl;
@useResult
$Res call({
 OneNoteInk field0
});




}
/// @nodoc
class _$OneNotePageContent_InkCopyWithImpl<$Res>
    implements $OneNotePageContent_InkCopyWith<$Res> {
  _$OneNotePageContent_InkCopyWithImpl(this._self, this._then);

  final OneNotePageContent_Ink _self;
  final $Res Function(OneNotePageContent_Ink) _then;

/// Create a copy of OneNotePageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNotePageContent_Ink(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteInk,
  ));
}


}

/// @nodoc


class OneNotePageContent_Unknown extends OneNotePageContent {
  const OneNotePageContent_Unknown(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNotePageContent_Unknown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OneNotePageContent.unknown()';
}


}




/// @nodoc
mixin _$OneNoteSectionEntry {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteSectionEntry&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'OneNoteSectionEntry(field0: $field0)';
}


}

/// @nodoc
class $OneNoteSectionEntryCopyWith<$Res>  {
$OneNoteSectionEntryCopyWith(OneNoteSectionEntry _, $Res Function(OneNoteSectionEntry) __);
}


/// Adds pattern-matching-related methods to [OneNoteSectionEntry].
extension OneNoteSectionEntryPatterns on OneNoteSectionEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OneNoteSectionEntry_Section value)?  section,TResult Function( OneNoteSectionEntry_SectionGroup value)?  sectionGroup,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section() when section != null:
return section(_that);case OneNoteSectionEntry_SectionGroup() when sectionGroup != null:
return sectionGroup(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OneNoteSectionEntry_Section value)  section,required TResult Function( OneNoteSectionEntry_SectionGroup value)  sectionGroup,}){
final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section():
return section(_that);case OneNoteSectionEntry_SectionGroup():
return sectionGroup(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OneNoteSectionEntry_Section value)?  section,TResult? Function( OneNoteSectionEntry_SectionGroup value)?  sectionGroup,}){
final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section() when section != null:
return section(_that);case OneNoteSectionEntry_SectionGroup() when sectionGroup != null:
return sectionGroup(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OneNoteSection field0)?  section,TResult Function( OneNoteSectionGroup field0)?  sectionGroup,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section() when section != null:
return section(_that.field0);case OneNoteSectionEntry_SectionGroup() when sectionGroup != null:
return sectionGroup(_that.field0);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OneNoteSection field0)  section,required TResult Function( OneNoteSectionGroup field0)  sectionGroup,}) {final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section():
return section(_that.field0);case OneNoteSectionEntry_SectionGroup():
return sectionGroup(_that.field0);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OneNoteSection field0)?  section,TResult? Function( OneNoteSectionGroup field0)?  sectionGroup,}) {final _that = this;
switch (_that) {
case OneNoteSectionEntry_Section() when section != null:
return section(_that.field0);case OneNoteSectionEntry_SectionGroup() when sectionGroup != null:
return sectionGroup(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class OneNoteSectionEntry_Section extends OneNoteSectionEntry {
  const OneNoteSectionEntry_Section(this.field0): super._();
  

@override final  OneNoteSection field0;

/// Create a copy of OneNoteSectionEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteSectionEntry_SectionCopyWith<OneNoteSectionEntry_Section> get copyWith => _$OneNoteSectionEntry_SectionCopyWithImpl<OneNoteSectionEntry_Section>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteSectionEntry_Section&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteSectionEntry.section(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteSectionEntry_SectionCopyWith<$Res> implements $OneNoteSectionEntryCopyWith<$Res> {
  factory $OneNoteSectionEntry_SectionCopyWith(OneNoteSectionEntry_Section value, $Res Function(OneNoteSectionEntry_Section) _then) = _$OneNoteSectionEntry_SectionCopyWithImpl;
@useResult
$Res call({
 OneNoteSection field0
});




}
/// @nodoc
class _$OneNoteSectionEntry_SectionCopyWithImpl<$Res>
    implements $OneNoteSectionEntry_SectionCopyWith<$Res> {
  _$OneNoteSectionEntry_SectionCopyWithImpl(this._self, this._then);

  final OneNoteSectionEntry_Section _self;
  final $Res Function(OneNoteSectionEntry_Section) _then;

/// Create a copy of OneNoteSectionEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteSectionEntry_Section(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteSection,
  ));
}


}

/// @nodoc


class OneNoteSectionEntry_SectionGroup extends OneNoteSectionEntry {
  const OneNoteSectionEntry_SectionGroup(this.field0): super._();
  

@override final  OneNoteSectionGroup field0;

/// Create a copy of OneNoteSectionEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneNoteSectionEntry_SectionGroupCopyWith<OneNoteSectionEntry_SectionGroup> get copyWith => _$OneNoteSectionEntry_SectionGroupCopyWithImpl<OneNoteSectionEntry_SectionGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneNoteSectionEntry_SectionGroup&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'OneNoteSectionEntry.sectionGroup(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $OneNoteSectionEntry_SectionGroupCopyWith<$Res> implements $OneNoteSectionEntryCopyWith<$Res> {
  factory $OneNoteSectionEntry_SectionGroupCopyWith(OneNoteSectionEntry_SectionGroup value, $Res Function(OneNoteSectionEntry_SectionGroup) _then) = _$OneNoteSectionEntry_SectionGroupCopyWithImpl;
@useResult
$Res call({
 OneNoteSectionGroup field0
});




}
/// @nodoc
class _$OneNoteSectionEntry_SectionGroupCopyWithImpl<$Res>
    implements $OneNoteSectionEntry_SectionGroupCopyWith<$Res> {
  _$OneNoteSectionEntry_SectionGroupCopyWithImpl(this._self, this._then);

  final OneNoteSectionEntry_SectionGroup _self;
  final $Res Function(OneNoteSectionEntry_SectionGroup) _then;

/// Create a copy of OneNoteSectionEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(OneNoteSectionEntry_SectionGroup(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as OneNoteSectionGroup,
  ));
}


}

// dart format on
