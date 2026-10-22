import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/internet_connection_cubit.dart';
import '../cubit/internet_connection_state.dart';
import 'no_internet_dialog.dart';

class GlobalInternetConnectionListener extends StatefulWidget {
  final Widget child;

  const GlobalInternetConnectionListener({
    super.key,
    required this.child,
  });

  @override
  State<GlobalInternetConnectionListener> createState() =>
      _GlobalInternetConnectionListenerState();
}

class _GlobalInternetConnectionListenerState
    extends State<GlobalInternetConnectionListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<InternetConnectionCubit>().onAppResumed();
    }
  }

  void _showRestoredFeedback(BuildContext context) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger == null) return;
      final l10n = AppLocalizations.of(context);

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          elevation: 6,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.wifi_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.translate('connection_restored'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetConnectionCubit, InternetConnectionState>(
      listenWhen: (prev, curr) => !prev.hasRecovered && curr.hasRecovered,
      listener: (context, state) {
        if (state.hasRecovered) {
          _showRestoredFeedback(context);
        }
      },
      builder: (context, state) {
        final isOffline = state.isDisconnected;

        return Stack(
          children: [
            // 1. Root application navigation surface (preserved completely)
            widget.child,

            // 2. Global Blocking Modal Barrier & Dialog
            if (isOffline)
              Positioned.fill(
                child: PopScope(
                  canPop: false,
                  child: Material(
                    type: MaterialType.transparency,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: const SafeArea(
                          child: Center(
                            child: SingleChildScrollView(
                              child: NoInternetDialog(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
