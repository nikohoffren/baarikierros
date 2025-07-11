import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/city.dart';
import '../models/round.dart';
import '../models/bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../providers/group_state.dart';

class _TimeRange {
  final int start; //* minutes since midnight
  final int end;
  _TimeRange(this.start, this.end);
  String format() {
    return _formatMinutes(start) + '-' + _formatMinutes(end);
  }

  String _formatMinutes(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final min = (m % 60).toString().padLeft(2, '0');
    return '$h:$min';
  }
}

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
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildAuthBar(appState),
                const SizedBox(height: 16),
                _buildHeader(context),
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
              if (appState.user?.photoURL != null) CircleAvatar(backgroundImage: NetworkImage(appState.user!.photoURL!), radius: 18),
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
                    style: TextStyle(color: appState.hasSubscription ? Colors.greenAccent : AppTheme.lightGrey, fontSize: 12),
                  ),
                ],
              ),
            ],
          )
        else
          const Text('Et ole kirjautunut sisään', style: TextStyle(color: AppTheme.lightGrey)),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _handleSignIn(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.primaryBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(appState.isSignedIn ? 'Kirjaudu ulos' : 'Kirjaudu Googlella'),
        ),
      ],
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    final appState = context.read<AppState>();
    if (appState.isSignedIn) {
      await appState.signOut();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final ageConfirmed = prefs.getBool('ageConfirmed') ?? false;

    if (ageConfirmed) {
      await appState.signInWithGoogle();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Vahvista ikäsi', style: TextStyle(color: AppTheme.accentGold)),
        content: const Text('Vahvistamalla hyväksyt, että olet vähintään 18-vuotias.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Peruuta')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kyllä, olen 18+')),
        ],
      ),
    );

    if (confirmed == true) {
      await prefs.setBool('ageConfirmed', true);
      await appState.signInWithGoogle();
    }
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryBlack,
          title: const Text('Tietoa sovelluksesta', style: TextStyle(color: AppTheme.accentGold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                  'Sovelluksen kuvaus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                ),
                SizedBox(height: 8),
                Text(
                  'Baarikierros on sovellus, jonka avulla voit löytää ja kiertää kaupungin parhaita baareja valmiiden reittien avulla. Valitse kaupunki, valitse kierros ja seuraa reittiä helposti kartalta. Sovellus seuraa etenemistäsi ja auttaa sinua löytämään seuraavan pysähdyksen.',
                  style: TextStyle(fontSize: 16, color: AppTheme.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Tärkeää: turvallisuus ja vastuullisuus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                ),
                SizedBox(height: 8),
                Text(
                  'Ole aina varovainen liikenteessä ja noudata liikennesääntöjä siirtyessäsi baarista toiseen. Jos nautit alkoholia, älä koskaan aja,suosi kävelyä. Baarikierros-reitit on suunniteltu niin, että baarit ovat kävelyetäisyydellä toisistaan.',
                  style: TextStyle(fontSize: 15, color: AppTheme.lightGrey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sulje', style: TextStyle(color: AppTheme.accentGold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Center(child: SvgPicture.asset('assets/logo.svg', width: 90, height: 90)),
            ),
            const SizedBox(height: 32),
            const Text(
              'Baarikierros',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Valitse kaupunki ja aloita kierros',
              style: TextStyle(fontSize: 18, color: AppTheme.lightGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.accentGold, size: 28),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Tietoa sovelluksesta',
          ),
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
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold)));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.2), width: 1),
      ),
      child: DropdownButton<City>(
        value: appState.selectedCity,
        onChanged: (City? city) {
          if (city != null) {
            appState.setSelectedCity(city);
          }
        },
        items: appState.cities.map<DropdownMenuItem<City>>((City city) {
          return DropdownMenuItem<City>(value: city, child: Text(city.name));
        }).toList(),
        isExpanded: true,
        dropdownColor: AppTheme.secondaryBlack,
        style: const TextStyle(color: AppTheme.white, fontSize: 18),
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
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold)));
    }

    final rounds = appState.roundsByCity[selectedCity.id] ?? [];
    if (rounds.isEmpty) {
      return const Center(
        child: Text('Tälle kaupungille ei löytynyt kierroksia.', style: TextStyle(color: AppTheme.lightGrey, fontSize: 16)),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: rounds.length,
        itemBuilder: (context, index) {
          final round = rounds[index];
          final openingHoursText = _getRouteOpeningHours(round);
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppTheme.secondaryBlack.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.accentGold.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
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
                                style: const TextStyle(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text('${round.bars.length} baaria', style: const TextStyle(color: AppTheme.accentGold, fontSize: 14)),
                            ),
                          ],
                        ),
                        if (round.description != null) ...[
                          const SizedBox(height: 8),
                          Text(round.description!, style: const TextStyle(color: AppTheme.lightGrey, fontSize: 14)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.accentGold, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              openingHoursText,
                              style: const TextStyle(color: AppTheme.accentGold, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: AppTheme.lightGrey, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Arvioitu kesto: ${round.estimatedDuration ?? 'Ei tiedossa'}',
                              style: const TextStyle(color: AppTheme.lightGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.go('/route', extra: round);
                          },
                          icon: const Icon(Icons.person, color: AppTheme.primaryBlack),
                          label: const Text('Aloita yksin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: AppTheme.primaryBlack,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final appState = Provider.of<AppState>(context, listen: false);
                            final groupState = Provider.of<GroupState>(context, listen: false);
                            if (appState.user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kirjaudu sisään aloittaaksesi ryhmän.')));
                              return;
                            }
                            final groupCode = await groupState.createGroup(round, appState.user!);
                            await showDialog(
                              context: context,
                              builder: (context) => GroupLobbyDialog(
                                groupCode: groupCode,
                                isCreator: true,
                                onStartCrawl: () {
                                  Navigator.of(context).pop();
                                  context.go('/route', extra: {'round': round, 'groupMode': true});
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.group_add, color: AppTheme.accentGold),
                          label: const Text('Aloita ryhmä'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentGold,
                            side: const BorderSide(color: AppTheme.accentGold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final appState = Provider.of<AppState>(context, listen: false);
                            final groupState = Provider.of<GroupState>(context, listen: false);
                            final joined = await showDialog<bool>(context: context, builder: (context) => const JoinGroupDialog());
                            if (joined == true) {
                              final groupCode = groupState.groupCode;
                              if (groupCode != null) {
                                await showDialog(
                                  context: context,
                                  builder: (context) => GroupLobbyDialog(groupCode: groupCode, isCreator: false),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.group, color: AppTheme.accentGold),
                          label: const Text('Liity ryhmään'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentGold,
                            side: const BorderSide(color: AppTheme.accentGold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getRouteOpeningHours(Round round) {
    if (round.bars.isEmpty) return 'Auki: Ei tietoa';
    final now = DateTime.now();
    final weekday = _weekdayToKey(now.weekday);
    List<_TimeRange> intersection = _barToTimeRanges(round.bars.first.openingHours[weekday] ?? []);
    for (final bar in round.bars.skip(1)) {
      final periods = _barToTimeRanges(bar.openingHours[weekday] ?? []);
      intersection = _intersectTimeRanges(intersection, periods);
      if (intersection.isEmpty) break;
    }
    if (intersection.isEmpty) return 'Auki: Ei yhteistä aukioloa tänään';
    intersection.sort((a, b) => a.start.compareTo(b.start));
    final formatted = intersection.map((r) => r.format()).join(', ');
    return 'Auki: $formatted';
  }

  List<_TimeRange> _barToTimeRanges(List<OpenPeriod> periods) {
    final List<_TimeRange> result = [];
    for (final p in periods) {
      final start = _parseMinutes(p.open);
      final end = _parseMinutes(p.close);
      if (end > start) {
        result.add(_TimeRange(start, end));
      } else if (end < start) {
        //* Overnight: split into two ranges
        result.add(_TimeRange(start, 1440)); //* until midnight
        result.add(_TimeRange(0, end)); //* from midnight
      }
      //* If end == start, skip (zero-length period)
    }
    return result;
  }

  int _parseMinutes(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0].padLeft(2, '0'));
    int minute = int.parse(parts[1].padLeft(2, '0'));
    return hour * 60 + minute;
  }

  List<_TimeRange> _intersectTimeRanges(List<_TimeRange> a, List<_TimeRange> b) {
    List<_TimeRange> result = [];
    for (final ra in a) {
      for (final rb in b) {
        final start = ra.start > rb.start ? ra.start : rb.start;
        final end = ra.end < rb.end ? ra.end : rb.end;
        if (start < end) {
          result.add(_TimeRange(start, end));
        }
      }
    }
    return result;
  }

  String _weekdayToKey(int weekday) {
    //* 1=Mon, 7=Sun
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}

class GroupLobbyDialog extends StatefulWidget {
  final String groupCode;
  final bool isCreator;
  final VoidCallback? onStartCrawl;
  const GroupLobbyDialog({Key? key, required this.groupCode, required this.isCreator, this.onStartCrawl}) : super(key: key);

  @override
  State<GroupLobbyDialog> createState() => _GroupLobbyDialogState();
}

class _GroupLobbyDialogState extends State<GroupLobbyDialog> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final groupState = Provider.of<GroupState>(context);
    if (groupState.groupData?.started == true && !widget.isCreator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          final round = groupState.groupData?.toRound();
          if (round != null) {
            context.go('/route', extra: {'round': round, 'groupMode': true});
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = Provider.of<GroupState>(context);
    final members = groupState.groupMembers;
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Ryhmäkoodi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    widget.groupCode,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.white, letterSpacing: 2),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.accentGold),
                    tooltip: 'Kopioi koodi',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.groupCode));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koodi kopioitu leikepöydälle!')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: AppTheme.accentGold),
                    tooltip: 'Jaa koodi',
                    onPressed: () {
                      // TODO: Implement sharing
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Jäsenet',
                style: TextStyle(fontSize: 18, color: AppTheme.accentGold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final member = members[idx];
                    final name = member['displayName'] as String? ?? '';
                    final initial = name.isNotEmpty ? name[0] : '?';
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.accentGold,
                          child: Text(
                            initial,
                            style: const TextStyle(color: AppTheme.primaryBlack, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(name, style: const TextStyle(color: AppTheme.white, fontSize: 12)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (widget.isCreator)
                ElevatedButton(
                  onPressed: () async {
                    final groupState = Provider.of<GroupState>(context, listen: false);
                    await groupState.startGroup();
                    if (widget.onStartCrawl != null) widget.onStartCrawl!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.primaryBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Aloita kierros'),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Peruuta', style: TextStyle(color: AppTheme.lightGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinGroupDialog extends StatefulWidget {
  const JoinGroupDialog({Key? key}) : super(key: key);

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final code = _codeController.text.trim().toUpperCase();
    final groupState = Provider.of<GroupState>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (appState.user == null) {
        setState(() {
          _error = 'Kirjaudu sisään liittyäksesi ryhmään';
          _loading = false;
        });
        return;
      }
      await groupState.joinGroup(code, appState.user!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Virheellinen koodi';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Liity ryhmäkierrokseen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(color: AppTheme.white, fontSize: 22, letterSpacing: 2),
              decoration: InputDecoration(
                labelText: 'Ryhmäkoodi',
                labelStyle: const TextStyle(color: AppTheme.lightGrey),
                counterText: '',
                filled: true,
                fillColor: AppTheme.primaryBlack.withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentGold),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentGold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentGold, width: 2),
                ),
                errorText: _error,
                errorStyle: const TextStyle(color: Colors.redAccent),
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _handleJoin(),
              enabled: !_loading,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _handleJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: AppTheme.primaryBlack,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack)),
                    )
                  : const Text('Liity'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Peruuta', style: TextStyle(color: AppTheme.lightGrey)),
            ),
          ],
        ),
      ),
    );
  }
}
