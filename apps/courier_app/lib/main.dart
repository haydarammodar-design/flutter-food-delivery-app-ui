import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'data/demo_delivery_repository.dart';
import 'models/courier_profile.dart';
import 'models/delivery_offer.dart';
import 'services/api_exception.dart';
import 'services/auth_api_service.dart';
import 'services/courier_repository.dart';
import 'services/delivery_api_service.dart';

void main() {
  runApp(const CourierApp());
}

class CourierApp extends StatefulWidget {
  const CourierApp({
    Key? key,
    this.authService,
    this.repository,
    this.demoRepository,
  }) : super(key: key);

  final AuthApiService? authService;
  final CourierRepository? repository;
  final CourierRepository? demoRepository;

  @override
  State<CourierApp> createState() => _CourierAppState();
}

class _CourierAppState extends State<CourierApp> {
  late AuthApiService _authService;
  CourierRepository? _repository;
  CourierProfile? _profile;
  List<DeliveryOffer> _deliveries = <DeliveryOffer>[];
  final Set<String> _updatingDeliveryIds = <String>{};
  bool _isLoading = false;
  bool _isAvailabilityUpdating = false;
  bool _usingDemo = false;
  String? _loadError;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthApiService();
    _repository = widget.repository;
    _usingDemo = widget.repository is DemoDeliveryRepository;
    if (_repository != null) {
      _loadCourierData();
    }
  }

  Future<void> _authenticate(String email, String password) async {
    final session = await _authService.login(email: email, password: password);
    if (!mounted) {
      return;
    }
    setState(() {
      _repository = DeliveryApiService(accessToken: session.accessToken);
      _profile = null;
      _deliveries = <DeliveryOffer>[];
      _usingDemo = false;
      _loadError = null;
      _selectedTab = 0;
    });
    await _loadCourierData();
  }

  Future<void> _startDemo() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _repository = widget.demoRepository ?? DemoDeliveryRepository();
      _profile = null;
      _deliveries = <DeliveryOffer>[];
      _usingDemo = true;
      _loadError = null;
      _selectedTab = 0;
    });
    await _loadCourierData();
  }

  void _signOut() {
    setState(() {
      _repository = null;
      _profile = null;
      _deliveries = <DeliveryOffer>[];
      _updatingDeliveryIds.clear();
      _isLoading = false;
      _isAvailabilityUpdating = false;
      _usingDemo = false;
      _loadError = null;
      _selectedTab = 0;
    });
  }

  Future<void> _loadCourierData() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.fetchCourierProfile(),
        repository.fetchDeliveryOffers(),
        repository.fetchActiveDelivery(),
      ]);
      final profile = results[0] as CourierProfile;
      final offers = results[1] as List<DeliveryOffer>;
      final activeDelivery = results[2] as DeliveryOffer?;
      if (!mounted || !identical(_repository, repository)) {
        return;
      }
      setState(() {
        _profile = profile;
        _deliveries = _mergeDeliveries(offers, activeDelivery);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || !identical(_repository, repository)) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = _errorMessage(error);
      });
    }
  }

  List<DeliveryOffer> _mergeDeliveries(
    List<DeliveryOffer> offers,
    DeliveryOffer? activeDelivery,
  ) {
    final merged = <String, DeliveryOffer>{};
    for (final offer in offers) {
      merged[offer.id] = offer;
    }
    if (activeDelivery != null) {
      merged[activeDelivery.id] = activeDelivery;
    }
    return merged.values.toList();
  }

  Future<void> _updateAvailability(bool isAvailable) async {
    final repository = _repository;
    if (repository == null || _profile == null || _isAvailabilityUpdating) {
      return;
    }

    setState(() {
      _isAvailabilityUpdating = true;
    });
    try {
      final profile = await repository.updateCourierAvailability(
        isAvailable: isAvailable,
      );
      if (!mounted || !identical(_repository, repository)) {
        return;
      }
      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (mounted && identical(_repository, repository)) {
        _showMessage(_errorMessage(error));
      }
    } finally {
      if (mounted && identical(_repository, repository)) {
        setState(() {
          _isAvailabilityUpdating = false;
        });
      }
    }
  }

  Future<void> _updateDeliveryStatus(
    DeliveryOffer delivery,
    DeliveryStatus status,
  ) async {
    final repository = _repository;
    if (repository == null || _updatingDeliveryIds.contains(delivery.id)) {
      return;
    }

    setState(() {
      _updatingDeliveryIds.add(delivery.id);
    });
    try {
      final updated = await repository.updateDeliveryStatus(
        delivery: delivery,
        status: status,
      );
      if (!mounted || !identical(_repository, repository)) {
        return;
      }
      setState(() {
        _deliveries = _deliveries
            .map(
              (DeliveryOffer offer) =>
                  offer.id == delivery.id ? updated : offer,
            )
            .toList();
      });
      _showMessage(
        '${delivery.reference} is ${deliveryStatusLabel(status).toLowerCase()}.',
      );
    } catch (error) {
      if (mounted && identical(_repository, repository)) {
        _showMessage(_errorMessage(error));
      }
    } finally {
      if (mounted && identical(_repository, repository)) {
        setState(() {
          _updatingDeliveryIds.remove(delivery.id);
        });
      }
    }
  }

  void _acceptOffer(DeliveryOffer delivery) {
    if (!_isAvailable) {
      _showMessage('Go available before accepting another delivery.');
      return;
    }
    if (_activeDelivery != null) {
      _showMessage('Finish your active delivery before accepting another one.');
      return;
    }
    _updateDeliveryStatus(delivery, DeliveryStatus.accepted);
  }

  DeliveryOffer? get _activeDelivery => _findActiveDelivery(_deliveries);

  bool get _isAvailable => _profile?.isAvailable ?? false;

  int get _completedDeliveries {
    return _deliveries
        .where(
            (DeliveryOffer offer) => offer.status == DeliveryStatus.delivered)
        .length;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Could not reach dispatch right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courier Desk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: _CourierColors.pine,
        scaffoldBackgroundColor: _CourierColors.canvas,
        colorScheme: const ColorScheme.light(
          primary: _CourierColors.pine,
          secondary: _CourierColors.green,
          surface: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _repository == null
          ? _LoginScreen(onLogin: _authenticate, onUseDemo: _startDemo)
          : Scaffold(
              backgroundColor: _CourierColors.canvas,
              body: SafeArea(
                child: IndexedStack(
                  index: _selectedTab,
                  children: <Widget>[
                    _HomeTab(
                      deliveries: _deliveries,
                      profile: _profile,
                      isLoading: _isLoading,
                      isAvailable: _isAvailable,
                      isAvailabilityUpdating: _isAvailabilityUpdating,
                      usingDemo: _usingDemo,
                      loadError: _loadError,
                      updatingDeliveryIds: _updatingDeliveryIds,
                      onAvailabilityChanged:
                          _profile == null || _isAvailabilityUpdating
                              ? null
                              : (bool value) {
                                  _updateAvailability(value);
                                },
                      onRefresh: _loadCourierData,
                      onStatusUpdate: _updateDeliveryStatus,
                      onPlaceholder: _showMessage,
                      onUseDemo: _usingDemo
                          ? null
                          : () {
                              _startDemo();
                            },
                    ),
                    _JobsTab(
                      deliveries: _deliveries,
                      isAvailable: _isAvailable,
                      updatingDeliveryIds: _updatingDeliveryIds,
                      onAccept: _acceptOffer,
                    ),
                    _ProfileTab(
                      profile: _profile,
                      isAvailable: _isAvailable,
                      isDemo: _usingDemo,
                      completedDeliveries: _completedDeliveries,
                      onPlaceholder: _showMessage,
                      onSignOut: _signOut,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedTab,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: _CourierColors.pine,
                unselectedItemColor: _CourierColors.slate,
                onTap: (int index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.work_outline),
                    activeIcon: Icon(Icons.work),
                    label: 'Jobs',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    required this.onLogin,
    required this.onUseDemo,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function() onUseDemo;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onLogin(_emailController.text, _passwordController.text);
      if (mounted) {
        _passwordController.clear();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error is ApiException
              ? error.message
              : 'Could not sign in. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CourierColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _CourierColors.pine,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.route, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 28),
            const Text(
              'Courier desk',
              style: TextStyle(
                color: _CourierColors.ink,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to dispatch',
              style: TextStyle(
                color: _CourierColors.slate,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your access token stays only in this app session and is cleared when you sign out.',
              style: TextStyle(
                color: _CourierColors.slate,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _CourierColors.line),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Account credentials',
                      style: TextStyle(
                        color: _CourierColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const <String>[AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _submit();
                      },
                    ),
                    if (_errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        primary: _CourierColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _Eyebrow('LOCAL DEVELOPMENT'),
            const SizedBox(height: 8),
            const Text(
              'Use local routes only when dispatch is unavailable. Demo data never signs in to the API.',
              style: TextStyle(
                color: _CourierColors.slate,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      widget.onUseDemo();
                    },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Use local demo'),
              style: OutlinedButton.styleFrom(
                primary: _CourierColors.pine,
                side: const BorderSide(color: _CourierColors.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'API: ${ApiConfig.baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CourierColors.slate,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.deliveries,
    required this.profile,
    required this.isLoading,
    required this.isAvailable,
    required this.isAvailabilityUpdating,
    required this.usingDemo,
    required this.loadError,
    required this.updatingDeliveryIds,
    required this.onAvailabilityChanged,
    required this.onRefresh,
    required this.onStatusUpdate,
    required this.onPlaceholder,
    required this.onUseDemo,
  });

  final List<DeliveryOffer> deliveries;
  final CourierProfile? profile;
  final bool isLoading;
  final bool isAvailable;
  final bool isAvailabilityUpdating;
  final bool usingDemo;
  final String? loadError;
  final Set<String> updatingDeliveryIds;
  final ValueChanged<bool>? onAvailabilityChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(DeliveryOffer, DeliveryStatus) onStatusUpdate;
  final ValueChanged<String> onPlaceholder;
  final VoidCallback? onUseDemo;

  @override
  Widget build(BuildContext context) {
    final activeDelivery = _findActiveDelivery(deliveries);
    final completedPayout = deliveries
        .where(
            (DeliveryOffer offer) => offer.status == DeliveryStatus.delivered)
        .fold<double>(0, (double total, DeliveryOffer offer) {
      return total + offer.earnings;
    });

    return RefreshIndicator(
      color: _CourierColors.green,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          _HomeHeader(profile: profile, usingDemo: usingDemo),
          const SizedBox(height: 20),
          _AvailabilityPanel(
            isAvailable: isAvailable,
            isUpdating: isAvailabilityUpdating,
            onChanged: onAvailabilityChanged,
          ),
          if (usingDemo || loadError != null) ...<Widget>[
            const SizedBox(height: 12),
            _ConnectionNotice(
              message: usingDemo
                  ? 'Local demo routes are on. They are not connected to dispatch.'
                  : loadError!,
              actionLabel: onUseDemo == null ? null : 'Use local demo',
              onAction: onUseDemo,
            ),
          ],
          const SizedBox(height: 24),
          const _Eyebrow('YOUR SHIFT'),
          const SizedBox(height: 10),
          _ShiftSummary(
            earnings: completedPayout,
            completed: deliveries
                .where(
                  (DeliveryOffer offer) =>
                      offer.status == DeliveryStatus.delivered,
                )
                .length,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const _Eyebrow('ACTIVE DELIVERY'),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeDelivery == null)
            _NoActiveDelivery(isAvailable: isAvailable)
          else
            _ActiveDeliveryCard(
              delivery: activeDelivery,
              isUpdating: updatingDeliveryIds.contains(activeDelivery.id),
              onStatusUpdate: onStatusUpdate,
              onPlaceholder: onPlaceholder,
            ),
          const SizedBox(height: 28),
          const _Eyebrow('SHIFT NOTES'),
          const SizedBox(height: 10),
          const _ShiftTip(),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.profile, required this.usingDemo});

  final CourierProfile? profile;
  final bool usingDemo;

  @override
  Widget build(BuildContext context) {
    final initials = profile?.initials ?? 'CD';
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _CourierColors.pine,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.route, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Courier desk',
                style: TextStyle(
                  color: _CourierColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                usingDemo
                    ? 'LOCAL DEMO | NORTH LOOP'
                    : (profile == null
                        ? 'CONNECTING TO DISPATCH'
                        : profile!.name.toUpperCase()),
                style: const TextStyle(
                  color: _CourierColors.slate,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: _CourierColors.mist,
          child: Text(
            initials,
            style: const TextStyle(
              color: _CourierColors.pine,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({
    required this.isAvailable,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isAvailable;
  final bool isUpdating;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAvailable ? _CourierColors.paleGreen : _CourierColors.mist,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isAvailable ? _CourierColors.green : _CourierColors.slate,
              shape: BoxShape.circle,
            ),
            child: isUpdating
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isAvailable ? Icons.check : Icons.pause,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isAvailable ? 'You are available' : 'You are paused',
                  style: const TextStyle(
                    color: _CourierColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUpdating
                      ? 'Updating dispatch availability'
                      : (isAvailable
                          ? 'New offers can reach you'
                          : 'You will not receive new offers'),
                  style: const TextStyle(
                    color: _CourierColors.slate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            activeColor: _CourierColors.green,
            onChanged: isUpdating ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CourierColors.paleAmber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child:
                Icon(Icons.info_outline, color: _CourierColors.ochre, size: 19),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message,
                  style: const TextStyle(
                    color: _CourierColors.ink,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                    style: TextButton.styleFrom(
                      primary: _CourierColors.ochre,
                      padding: const EdgeInsets.only(top: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftSummary extends StatelessWidget {
  const _ShiftSummary({required this.earnings, required this.completed});

  final double earnings;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _CourierColors.pine,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SummaryMetric(
              label: 'LOADED EARNINGS',
              value: _currency(earnings),
              detail: '$completed delivered',
            ),
          ),
          Container(width: 1, height: 54, color: Colors.white24),
          const SizedBox(width: 18),
          const Expanded(
            child: _SummaryMetric(
              label: 'SHIFT STATUS',
              value: 'On duty',
              detail: 'Dispatch connected',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFBBD4CD),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: const TextStyle(color: Color(0xFFBBD4CD), fontSize: 11),
        ),
      ],
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  const _ActiveDeliveryCard({
    required this.delivery,
    required this.isUpdating,
    required this.onStatusUpdate,
    required this.onPlaceholder,
  });

  final DeliveryOffer delivery;
  final bool isUpdating;
  final Future<void> Function(DeliveryOffer, DeliveryStatus) onStatusUpdate;
  final ValueChanged<String> onPlaceholder;

  @override
  Widget build(BuildContext context) {
    final action = _nextStatusAction(delivery.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120E312B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                delivery.reference,
                style: const TextStyle(
                  color: _CourierColors.slate,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _StatusPill(status: delivery.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _CourierColors.mist,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.store, color: _CourierColors.pine),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      delivery.merchantName,
                      style: const TextStyle(
                        color: _CourierColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_distance(delivery.distanceKm)} | ${delivery.etaMinutes} min left',
                      style: const TextStyle(
                        color: _CourierColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _currency(delivery.earnings),
                style: const TextStyle(
                  color: _CourierColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RoutePoint(
            icon: Icons.store,
            label: 'PICK UP',
            address: delivery.pickupAddress,
            note: delivery.pickupNote,
            isLast: false,
          ),
          _RoutePoint(
            icon: Icons.place,
            label: 'DROP OFF',
            address: delivery.dropoffAddress,
            note: delivery.dropoffNote,
            isLast: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    onPlaceholder(
                      delivery.customerPhone.isEmpty
                          ? 'No customer phone is available for this delivery.'
                          : 'Phone calling opens here for ${delivery.customerName}.',
                    );
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    primary: _CourierColors.pine,
                    side: const BorderSide(color: _CourierColors.line),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    onPlaceholder(
                      'Map directions will open here when navigation is connected.',
                    );
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Map'),
                  style: OutlinedButton.styleFrom(
                    primary: _CourierColors.pine,
                    side: const BorderSide(color: _CourierColors.line),
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating
                    ? null
                    : () {
                        onStatusUpdate(delivery, action.status);
                      },
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(action.icon, size: 18),
                label: Text(isUpdating ? 'Updating...' : action.label),
                style: ElevatedButton.styleFrom(
                  primary: _CourierColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.label,
    required this.address,
    required this.note,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final String address;
  final String? note;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 26,
          child: Column(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isLast
                      ? _CourierColors.paleAmber
                      : _CourierColors.paleGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: isLast ? _CourierColors.ochre : _CourierColors.green,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: note == null ? 34 : 48,
                  color: _CourierColors.line,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: _CourierColors.slate,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: const TextStyle(
                    color: _CourierColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (note != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    note!,
                    style: const TextStyle(
                      color: _CourierColors.slate,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final isMoving = status == DeliveryStatus.pickedUp ||
        status == DeliveryStatus.arrived ||
        status == DeliveryStatus.accepted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isMoving ? _CourierColors.paleGreen : _CourierColors.mist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        deliveryStatusLabel(status).toUpperCase(),
        style: TextStyle(
          color: isMoving ? _CourierColors.green : _CourierColors.slate,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _NoActiveDelivery extends StatelessWidget {
  const _NoActiveDelivery({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourierColors.line),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _CourierColors.mist,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping, color: _CourierColors.pine),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'No active delivery',
                  style: TextStyle(
                    color: _CourierColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAvailable
                      ? 'Keep this screen close for your next offer.'
                      : 'Go available when you are ready for offers.',
                  style: const TextStyle(
                    color: _CourierColors.slate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftTip extends StatelessWidget {
  const _ShiftTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CourierColors.line),
      ),
      child: Row(
        children: const <Widget>[
          Icon(Icons.lightbulb_outline, color: _CourierColors.ochre),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Confirm each handoff in the app so dispatch can keep customers informed.',
              style: TextStyle(
                color: _CourierColors.ink,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab({
    required this.deliveries,
    required this.isAvailable,
    required this.updatingDeliveryIds,
    required this.onAccept,
  });

  final List<DeliveryOffer> deliveries;
  final bool isAvailable;
  final Set<String> updatingDeliveryIds;
  final ValueChanged<DeliveryOffer> onAccept;

  @override
  Widget build(BuildContext context) {
    final offers = deliveries
        .where((DeliveryOffer delivery) => delivery.isAvailable)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: <Widget>[
        const Text(
          'Jobs',
          style: TextStyle(
            color: _CourierColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Delivery offers from live dispatch',
          style: TextStyle(color: _CourierColors.slate, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _CourierColors.paleGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${offers.length} AVAILABLE NOW',
                style: const TextStyle(
                  color: _CourierColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Spacer(),
            Text(
              isAvailable ? 'Dispatch on' : 'Dispatch paused',
              style: TextStyle(
                color:
                    isAvailable ? _CourierColors.green : _CourierColors.slate,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (offers.isEmpty)
          const _NoJobs()
        else
          ...offers.map(
            (DeliveryOffer offer) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _OfferCard(
                delivery: offer,
                isAvailable: isAvailable,
                isUpdating: updatingDeliveryIds.contains(offer.id),
                onAccept: onAccept,
              ),
            ),
          ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.delivery,
    required this.isAvailable,
    required this.isUpdating,
    required this.onAccept,
  });

  final DeliveryOffer delivery;
  final bool isAvailable;
  final bool isUpdating;
  final ValueChanged<DeliveryOffer> onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourierColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  delivery.merchantName,
                  style: const TextStyle(
                    color: _CourierColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _currency(delivery.earnings),
                style: const TextStyle(
                  color: _CourierColors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_distance(delivery.distanceKm)} | est. ${delivery.etaMinutes} min',
            style: const TextStyle(color: _CourierColors.slate, fontSize: 12),
          ),
          const SizedBox(height: 15),
          _AddressLine(icon: Icons.store, text: delivery.pickupAddress),
          const SizedBox(height: 8),
          _AddressLine(icon: Icons.place, text: delivery.dropoffAddress),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !isAvailable || isUpdating
                  ? null
                  : () {
                      onAccept(delivery);
                    },
              style: ElevatedButton.styleFrom(
                primary: _CourierColors.pine,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                isUpdating ? 'Accepting...' : 'Accept delivery',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: _CourierColors.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _CourierColors.ink, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _NoJobs extends StatelessWidget {
  const _NoJobs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CourierColors.line),
      ),
      child: Column(
        children: const <Widget>[
          Icon(Icons.hourglass_empty, color: _CourierColors.slate, size: 32),
          SizedBox(height: 10),
          Text(
            'No delivery offers right now',
            style: TextStyle(
              color: _CourierColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Stay available and dispatch will send the next route here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _CourierColors.slate, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.profile,
    required this.isAvailable,
    required this.isDemo,
    required this.completedDeliveries,
    required this.onPlaceholder,
    required this.onSignOut,
  });

  final CourierProfile? profile;
  final bool isAvailable;
  final bool isDemo;
  final int completedDeliveries;
  final ValueChanged<String> onPlaceholder;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'Courier';
    final initials = profile?.initials ?? 'CD';
    final vehicle = profile?.vehicleSummary ?? 'Equipment not set';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: <Widget>[
        const Text(
          'Profile',
          style: TextStyle(
            color: _CourierColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _CourierColors.pine,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFDEF2E6),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _CourierColors.pine,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDemo
                          ? 'Local demo session'
                          : (isAvailable
                              ? 'Available for dispatch'
                              : 'Dispatch paused'),
                      style: const TextStyle(
                        color: Color(0xFFBBD4CD),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _Eyebrow('TODAY'),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _ProfileMetric(
                value: '$completedDeliveries',
                label: 'Completed',
              ),
            ),
            const SizedBox(width: 10),
            _ProfileMetric(
              value: isAvailable ? 'On' : 'Off',
              label: 'Availability',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _Eyebrow('ACCOUNT'),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.local_shipping,
          title: 'Vehicle and equipment',
          subtitle: vehicle,
          onTap: () {
            onPlaceholder(
              'Vehicle settings will be available when profile editing is connected.',
            );
          },
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.account_balance_wallet,
          title: 'Earnings details',
          subtitle: 'Payout schedule and history',
          onTap: () {
            onPlaceholder(
                'Earnings details are not connected in this preview.');
          },
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.logout,
          title: isDemo ? 'Exit local demo' : 'Sign out',
          subtitle: isDemo
              ? 'Return to secure courier sign-in'
              : 'Clear the in-memory access token',
          onTap: onSignOut,
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CourierColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: _CourierColors.pine,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: _CourierColors.slate, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _CourierColors.line),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _CourierColors.mist,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _CourierColors.pine, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: _CourierColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _CourierColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _CourierColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _CourierColors.slate,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

class _StatusAction {
  const _StatusAction(this.label, this.status, this.icon);

  final String label;
  final DeliveryStatus status;
  final IconData icon;
}

_StatusAction? _nextStatusAction(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.offered:
    case DeliveryStatus.assigned:
      return const _StatusAction(
        'Accept delivery',
        DeliveryStatus.accepted,
        Icons.check,
      );
    case DeliveryStatus.accepted:
      return const _StatusAction(
        'I have arrived',
        DeliveryStatus.arrived,
        Icons.place,
      );
    case DeliveryStatus.arrived:
      return const _StatusAction(
        'Order picked up',
        DeliveryStatus.pickedUp,
        Icons.inventory,
      );
    case DeliveryStatus.pickedUp:
      return const _StatusAction(
        'Mark delivered',
        DeliveryStatus.delivered,
        Icons.check_circle,
      );
    case DeliveryStatus.delivered:
    case DeliveryStatus.cancelled:
    case DeliveryStatus.unknown:
      return null;
  }
}

DeliveryOffer? _findActiveDelivery(List<DeliveryOffer> deliveries) {
  for (final delivery in deliveries) {
    if (delivery.isActive) {
      return delivery;
    }
  }
  return null;
}

String _currency(double value) => '\$${value.toStringAsFixed(2)}';

String _distance(double value) => '${value.toStringAsFixed(1)} km';

class _CourierColors {
  const _CourierColors._();

  static const Color pine = Color(0xFF173D36);
  static const Color ink = Color(0xFF17302A);
  static const Color green = Color(0xFF168362);
  static const Color canvas = Color(0xFFF4F7F5);
  static const Color mist = Color(0xFFE8F0EC);
  static const Color paleGreen = Color(0xFFDDF2E7);
  static const Color paleAmber = Color(0xFFFFF2D8);
  static const Color ochre = Color(0xFFA46A0B);
  static const Color slate = Color(0xFF657570);
  static const Color line = Color(0xFFDCE6E1);
}
