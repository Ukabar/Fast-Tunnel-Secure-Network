import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/utils/ad_screen_ids.dart';
import '../../../core/ads/widgets/adaptive_banner_ad_widget.dart';
import '../../../core/ads/widgets/native_ad_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../settings/application/settings_providers.dart';
import '../application/locations_providers.dart';
import '../domain/planned_location.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(plannedLocationsProvider);
    final settings = ref
        .watch(settingsControllerProvider)
        .when(
          data: (settings) => settings,
          error: (error, stackTrace) => null,
          loading: () => null,
        );
    final selectedId = settings?.preferredLocationId ?? locations.first.id;
    final favorites = settings?.favoriteLocationIds ?? const [];
    final filtered = _filter(locations)..sort(_compareLocations);
    final favoriteLocations = filtered
        .where((location) => favorites.contains(location.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search countries and cities',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: '⭐ Favorites'),
            if (favoriteLocations.isEmpty)
              const _EmptyFavoritesCard()
            else
              for (final location in favoriteLocations)
                _LocationCard(
                  location: location,
                  isSelected: selectedId == location.id,
                  isFavorite: true,
                  onSelected: () => _select(location),
                  onToggleFavorite: () => _toggleFavorite(location),
                ),
            const SizedBox(height: 14),
            const SectionHeader(title: '🌍 All Locations'),
            for (var index = 0; index < filtered.length; index++) ...[
              if (index == 6) const NativeAdCard(),
              _LocationCard(
                location: filtered[index],
                isSelected: selectedId == filtered[index].id,
                isFavorite: favorites.contains(filtered[index].id),
                onSelected: () => _select(filtered[index]),
                onToggleFavorite: () => _toggleFavorite(filtered[index]),
              ),
            ],
            const SizedBox(height: 8),
            const AdaptiveBannerAdWidget(screenId: AdScreenIds.locations),
          ],
        ),
      ),
    );
  }

  List<PlannedLocation> _filter(List<PlannedLocation> locations) {
    if (_query.isEmpty) {
      return [...locations];
    }
    final query = _query.toLowerCase();
    return locations.where((location) {
      final text = [
        location.country,
        location.city,
        location.region,
        location.countryCode,
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  int _compareLocations(PlannedLocation a, PlannedLocation b) {
    final country = a.country.compareTo(b.country);
    if (country != 0) return country;
    return a.city.compareTo(b.city);
  }

  Future<void> _select(PlannedLocation location) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setPreferredLocation(location.id);
  }

  Future<void> _toggleFavorite(PlannedLocation location) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .toggleFavoriteLocation(location.id);
  }
}

class _EmptyFavoritesCard extends StatelessWidget {
  const _EmptyFavoritesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.star_border, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No favorite locations yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap the star icon to save your favorite locations.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.isFavorite,
    required this.onSelected,
    required this.onToggleFavorite,
  });

  final PlannedLocation location;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onSelected;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.55)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      location.flag,
                      semanticsLabel: location.country,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.country,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FavoriteButton(
                isFavorite: isFavorite,
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
