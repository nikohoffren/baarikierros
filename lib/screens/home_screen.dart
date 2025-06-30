import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/city.dart';
import '../models/round.dart';
import '../models/bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                _buildCityDropdown(appState),
                const SizedBox(height: 24),
                _buildRoundsList(appState),
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

  Widget _buildCityDropdown(AppState appState) {
    if (!appState.isSignedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Kirjaudu sisään nähdäksesi saatavilla olevat kaupungit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
          ),
        ),
      );
    }

    if (appState.cities.isEmpty) {
      // This can be a loading indicator or a "no cities found" message
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold)));
    }

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
        value: appState.selectedCity,
        onChanged: (City? city) {
          if (city != null) {
            appState.setSelectedCity(city);
          }
        },
        items: appState.cities.map<DropdownMenuItem<City>>((City city) {
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

  Widget _buildRoundsList(AppState appState) {
    final selectedCity = appState.selectedCity;
    if (selectedCity == null) {
      return const SizedBox.shrink();
    }

    if (appState.isLoadingRounds) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
        ),
      );
    }

    final rounds = appState.roundsByCity[selectedCity.id] ?? [];
    if (rounds.isEmpty) {
      return const Center(
        child: Text(
          'Tälle kaupungille ei löytynyt kierroksia.',
          style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: rounds.length,
        itemBuilder: (context, index) {
          final round = rounds[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppTheme.secondaryBlack.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.accentGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                context.go('/route', extra: round);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            round.name,
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${round.bars.length} baaria',
                            style: const TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (round.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        round.description!,
                        style: const TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: AppTheme.lightGrey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Arvioitu kesto: ${round.estimatedDuration ?? 'Ei tiedossa'}',
                          style: const TextStyle(
                            color: AppTheme.lightGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
