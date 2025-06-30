import 'package:baarikierros/data/app_data.dart';
import 'package:baarikierros/models/city.dart';
import 'package:baarikierros/models/round.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:baarikierros/models/bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  City? _selectedCity;
  List<Round> _rounds = [];

  @override
  void initState() {
    super.initState();
    _selectedCity = AppData.cities.first;
    _rounds = AppData.roundsByCity[_selectedCity!.name] ?? [];
  }

  void _onCityChanged(City? city) {
    if (city != null) {
      setState(() {
        _selectedCity = city;
        _rounds = AppData.roundsByCity[city.name] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildAuthBar(appState),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildCityDropdown(),
                const SizedBox(height: 24),
                _buildRoundsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthBar(AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (appState.isSignedIn)
          Row(
            children: [
              if (appState.user?.photoURL != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(appState.user!.photoURL!),
                  radius: 18,
                ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.user?.displayName ?? '',
                    style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    appState.hasSubscription ? 'Tilaus: Aktiivinen' : 'Tilaus: Ei aktiivinen',
                    style: TextStyle(
                      color: appState.hasSubscription ? Colors.greenAccent : AppTheme.lightGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          const Text(
            'Et ole kirjautunut sisään',
            style: TextStyle(color: AppTheme.lightGrey),
          ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: appState.isSignedIn
              ? appState.signOut
              : appState.signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.primaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(appState.isSignedIn ? 'Kirjaudu ulos' : 'Kirjaudu Googlella'),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/logo.svg',
              width: 90,
              height: 90,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Baarikierros',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentGold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Valitse kaupunki ja aloita kierros',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.lightGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<City>(
        value: _selectedCity,
        onChanged: _onCityChanged,
        items: AppData.cities.map<DropdownMenuItem<City>>((City city) {
          return DropdownMenuItem<City>(
            value: city,
            child: Text(city.name),
          );
        }).toList(),
        isExpanded: true,
        dropdownColor: AppTheme.secondaryBlack,
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 18,
        ),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentGold),
      ),
    );
  }

  Widget _buildRoundsList() {
    return Expanded(
      child: _rounds.isEmpty
          ? const Center(
              child: Text(
                'Tälle kaupungille ei ole vielä kierroksia.',
                style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _rounds.length,
              itemBuilder: (context, index) {
                final round = _rounds[index];
                return _buildRoundCard(round);
              },
            ),
    );
  }

  Widget _buildRoundCard(Round round) {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now).toLowerCase();
    final overlap = _calculateOverlapForToday(round.bars, weekday);
    final minutesPerBar = round.minutesPerBar ?? 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: AppTheme.secondaryBlack.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.accentGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          round.name,
          style: const TextStyle(
            color: AppTheme.accentGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: overlap != null
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: overlap != null ? Colors.greenAccent : Colors.redAccent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    color: overlap != null ? Colors.greenAccent : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    overlap != null
                        ? '${overlap['open']} - ${overlap['close']}'
                        : 'Suljettu',
                    style: TextStyle(
                      color: overlap != null ? AppTheme.white : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.accentGold,
            ),
          ],
        ),
        iconColor: AppTheme.accentGold,
        collapsedIconColor: AppTheme.accentGold,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (round.description != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    round.description!,
                    style: const TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              _buildInfoRow(
                icon: Icons.timer_outlined,
                label: 'Aikaa per baari:',
                value: '$minutesPerBar min',
              ),
              const SizedBox(height: 16),
              Text(
                'Baarit reitillä (${round.bars.length})',
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: round.bars
                    .map((bar) => Chip(
                          label: Text(bar.name),
                          backgroundColor: AppTheme.primaryBlack,
                          labelStyle: const TextStyle(color: AppTheme.lightGrey),
                          side: BorderSide(
                              color: AppTheme.accentGold.withOpacity(0.3)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    GoRouter.of(context).go('/route', extra: round);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Aloita kierros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.lightGrey, fontSize: 15),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
              color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Map<String, String>? _calculateOverlapForToday(List<Bar> bars, String weekday) {
    List<List<Map<String, String>>> periods = bars.map((bar) {
      final periods = bar.openingHours[weekday] ?? [];
      return periods.map((p) => {'open': p.open, 'close': p.close}).toList();
    }).toList();
    if (periods.any((p) => p.isEmpty)) return null;
    String maxOpen = periods.first.first['open']!;
    String minClose = periods.first.first['close']!;
    for (final barPeriods in periods) {
      for (final period in barPeriods) {
        if (_compareTime(period['open']!, maxOpen) > 0) maxOpen = period['open']!;
        if (_compareTime(period['close']!, minClose) < 0) minClose = period['close']!;
      }
    }
    if (_compareTime(maxOpen, minClose) >= 0) return null;
    return {'open': maxOpen, 'close': minClose};
  }

  int _compareTime(String t1, String t2) {
    final h1 = int.parse(t1.split(':')[0]);
    final m1 = int.parse(t1.split(':')[1]);
    final h2 = int.parse(t2.split(':')[0]);
    final m2 = int.parse(t2.split(':')[1]);
    if (h1 != h2) return h1 - h2;
    return m1 - m2;
  }
}
