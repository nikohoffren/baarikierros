import 'package:baarikierros/data/app_data.dart';
import 'package:baarikierros/models/city.dart';
import 'package:baarikierros/models/round.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
          child: const Icon(
            Icons.local_bar,
            size: 60,
            color: AppTheme.primaryBlack,
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          round.name,
          style: const TextStyle(
            color: AppTheme.accentGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          round.description ?? 'Ei kuvausta',
          style: const TextStyle(
            color: AppTheme.lightGrey,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.accentGold,
        ),
        onTap: () {
          GoRouter.of(context).go('/route', extra: round);
        },
      ),
    );
  }
}
