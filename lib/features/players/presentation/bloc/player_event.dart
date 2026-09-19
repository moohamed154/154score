import 'package:equatable/equatable.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlayerProfileEvent extends PlayerEvent {
  final String id;
  final String? slug;
  final String? fallbackName;
  final String? fallbackPhoto;

  const LoadPlayerProfileEvent(
    this.id, {
    this.slug,
    this.fallbackName,
    this.fallbackPhoto,
  });

  @override
  List<Object?> get props => [id, slug, fallbackName, fallbackPhoto];
}

class ChangePlayerTabEvent extends PlayerEvent {
  final int tabIndex;

  const ChangePlayerTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class RefreshPlayerProfileEvent extends PlayerEvent {
  const RefreshPlayerProfileEvent();
}
